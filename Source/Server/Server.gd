extends Node

export var websockets_server = true

var server = null
var hl_server = preload("res://Source/Server/HighLevelServer.tscn")
var ws_server = preload("res://Source/Server/WebSocketsServer.tscn")

const SERVER_PORT = 1909
const MAX_PLAYERS = 2000

var players_online = []
var players_names = {}
var lobbies = {}
var players_in_lobbies = {}

var player_dictionary_template = {
	"id": null,
	"name": null,
	"color": null
}

var colors = {
	0: Color.orange,
	1: Color.lightblue,
	2: Color.yellow,
	3: Color.lightsalmon,
	4: Color.lightgreen,
	5: Color.lightcoral
}

func _ready():
	start_server()
	
	return
	_connect_signals()

func start_server():
	if websockets_server:
		server = ws_server.instance()
	else:
		server = hl_server.instance()
	connect_connection_signals()
	server.set_request_handler(self)
	add_child(server)
	server.start_server()

func connect_connection_signals():
	if server.is_connected("user_connected", self, "player_connected"):
		return
	server.connect("user_connected", self, "player_connected")
	server.connect("user_disconnected", self, "player_disconnected")

func player_connected(player_id):
	players_online.append(player_id)
	server.send_data_to_client(player_id, "set_player_id", player_id)
	server.send_data_to_client(player_id, "send_player_name")

func player_disconnected(player_id):
	if players_in_lobbies.has(player_id):
		var reason = players_names[player_id] + " disconnected."
		var data = {"lobby_code": players_in_lobbies[player_id], "lobby": lobbies[players_in_lobbies[player_id]], "reason": reason}
		remove_player_from_game_lobby(player_id, data)
	players_online.erase(player_id)
	players_names.erase(player_id)

func set_player_name(player_id, data):
	players_names[player_id] = data["player_name"]
	print("%s is set as the name for player with id: %d." % [data["player_name"], player_id])

func create_game_lobby(player_id, lobby_data: Dictionary):
	# Lobby Code [ID]
	lobby_data["code"] = lobbies.size()
	
	# Setting players data for lobby
	var player_number = player_id #lobby_data["players"].size()
	
	lobby_data["players"][player_number]["id"] = player_id
	lobby_data["players"][player_number]["name"] = players_names[player_id]
	lobby_data["players"][player_number]["color"] = get_random_color(lobby_data["players"])
	lobby_data["players"][player_number]["host"] = true
	lobby_data["current_players"] += 1
	# Append lobbies list
	lobbies[lobbies.size()] = lobby_data
	
	players_in_lobbies[player_id] = lobby_data["code"]
	
	var data = {"lobby_data": lobby_data, "player_number": player_number}
	# Notify player
	server.send_data_to_client(player_id, "game_lobby_created", data)

func join_game_lobby(player_id, lobby_auth_info):
	var reason = "Lobby does not exist!"
	var lobby_code = lobby_auth_info["lobby_code"]
	var lobby_pass = lobby_auth_info["lobby_pass"]
	if lobbies.has(lobby_code):
		var lobby = lobbies[lobby_code]
		if lobby["current_players"] < lobby["max_players"]:
			if lobby["pass"] == lobby_pass:
				var player_number = player_id#lobbies[lobby_code]["current_players"]
				lobby["players"][player_number] = {
					"id": player_id, "name": players_names[player_id],
					"color": get_random_color(lobby["players"]), "host": false
				}
#				lobby["players"][player_number]["id"] = player_id
#				lobby["players"][player_number]["name"] = players_names[player_id]
#				lobby["players"][player_number]["color"] = get_random_color()
#				lobby["players"][player_number]["host"] = false
				players_in_lobbies[player_id] = lobby_code
				reason = players_names[player_id] + " has joined."
				lobby["current_players"] += 1
				var data = {"lobby": lobby, "reason": reason, "player_number": player_number}
				update_game_lobby_to_players(data)
				return
			else:
				reason = "Invalid Password!"
		else:
			reason = "Lobby is full!"
	server.send_data_to_client(player_id, "failed_to_join_game_lobby", reason)

func update_game_lobby_to_players(data):
	var lobby = data["lobby"]
	for p_id in lobby["players"]:
		var player_id = lobby["players"][p_id]["id"]
		if data.has("player_number"):
			data["player_number"] = p_id
		if player_id:
			server.send_data_to_client(player_id, "update_game_lobby", data)

func leave_game_lobby(player_id, data):
	remove_player_from_game_lobby(
		player_id, {"lobby_code": data["lobby_code"], "lobby": lobbies[data["lobby_code"]], "reason": ""}
	)

func kick_player_from_game_lobby(player_id, data):
	var reason = "kicked"
	server.send_data_to_client(data["kicked_player_id"], "kicked_from_lobby", reason)
	remove_player_from_game_lobby(
		data["kicked_player_id"], {"lobby_code": data["lobby_code"], "lobby": lobbies[data["lobby_code"]], "reason": reason}
	)

func remove_player_from_game_lobby(player_id, data):
	if not data["reason"]:
		data["reason"] = players_names[player_id] + " left."
	var lobby = data["lobby"]
	var player_number = null
	var is_host = false
	for p_id in lobby["players"].keys():
		if p_id != player_id:
			continue
		player_number = player_id
		is_host = lobby["players"][player_number]["host"]
	players_in_lobbies.erase(player_number)
	if lobby["current_players"] == 1:
		lobbies.erase(data["lobby_code"])
	else:
		lobby["current_players"] -= 1
		lobby["players"].erase(player_number)
		if is_host:
			lobby["players"][lobby["players"].keys()[0]]["host"] = true
		update_game_lobby_to_players(data)

func send_active_game_lobbies(player_id, data=null):
	server.send_data_to_client(player_id, "get_active_lobbies", lobbies)

func send_message_in_game_lobby(sender_id, data):
	var lobby = lobbies[data["lobby_code"]]
	for i in lobby.players:
		var player_id = lobby.players[i].id
		var message_info = {"sender": data["sender"], "message": data["message"]}
		server.send_data_to_client(player_id, "get_message", message_info)

func start_the_game(sender_id, data):
	var lobby = lobbies[data["lobby_code"]]
	for i in lobby.players:
		var player_id = lobby.players[i].id
		server.send_data_to_client(player_id, "game_started")

func send_node_method_call(sender_id, data):
	var lobby = lobbies[data["lobby_code"]]
	for i in lobby.players:
		var player_id = lobby.players[i].id
		if player_id == sender_id: continue
		server.send_data_to_client(
			player_id,
			"get_node_method_call", data 
		)

func stop_server():
	server.stop_server()
	disconnect_connection_signals()
	server.queue_free()

func disconnect_connection_signals():
	if !server.is_connected("user_connected", self, "player_connected"):
		return
	server.disconnect("user_connected", self, "player_connected")
	server.disconnect("user_disconnected", self, "player_disconnected")

func _connect_signals():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")


func _start_server():
	var peer = NetworkedMultiplayerENet.new()
	var error = peer.create_server(SERVER_PORT, MAX_PLAYERS)
	if error == OK:
		get_tree().network_peer = peer
	else:
		print("Error creating the server: ", str(error))

func _player_connected(player_id):
	players_online.append(player_id)
	rpc_id(player_id, "send_player_name")
	print("Plyer: " + str(player_id) + " connected.")

func _player_disconnected(player_id):
	if players_in_lobbies.has(player_id):
		var reason = players_names[player_id] + " disconnected."
		remove_player_from_lobby(players_in_lobbies[player_id], player_id, reason)
	players_online.erase(player_id)
	players_names.erase(player_id)
	print("Plyer: " + str(player_id) + " disconnected.")

remote func get_player_name(player_name):
	var player_id = get_tree().get_rpc_sender_id()
	players_names[player_id] = player_name
	print("Player " + str(player_id) + " has name " + player_name + ".")

remote func create_lobby(lobby_data: Dictionary):
	# Lobby Code [ID]
	lobby_data["code"] = lobbies.size()
	
	# Setting players data for lobby
	var player_id = get_tree().get_rpc_sender_id()
	var player_number = 0 #lobby_data["players"].size()
	
	lobby_data["players"][player_number]["id"] = player_id
	lobby_data["players"][player_number]["name"] = players_names[player_id]
	lobby_data["players"][player_number]["color"] = colors[player_number]
	lobby_data["current_players"] += 1
	# Append lobbies list
	lobbies[lobbies.size()] = lobby_data
	
	players_in_lobbies[player_id] = lobby_data["code"]
	
	# Notify player
	rpc_id(player_id, "lobby_created", lobby_data)

remote func join_lobby(lobby_code, lobby_pass):
	var player_id = get_tree().get_rpc_sender_id()
	var reason = "Lobby does not exist!"
	if lobbies.has(lobby_code):
		if lobbies[lobby_code]["current_players"] < lobbies[lobby_code]["max_players"]:
			if lobbies[lobby_code]["pass"] == lobby_pass:
				var player_number = lobbies[lobby_code]["current_players"]
				lobbies[lobby_code]["players"][player_number]["id"] = player_id
				lobbies[lobby_code]["players"][player_number]["name"] = players_names[player_id]
				lobbies[lobby_code]["players"][player_number]["color"] = colors[player_number]
				players_in_lobbies[player_id] = lobby_code
				reason = players_names[player_id] + " has joined."
				lobbies[lobby_code]["current_players"] += 1
				update_lobby_to_players(lobby_code, reason)
			else:
				reason = "Invalid Password!"
				rpc_id(player_id, "failed_to_join_lobby", reason)
		else:
			reason = "Lobby is full!"
			rpc_id(player_id, "failed_to_join_lobby", reason)
	else:
		rpc_id(player_id, "failed_to_join_lobby", reason)

func update_lobby_to_players(lobby_code, reason = ""):
	for p_id in range(lobbies[lobby_code]["players"].size()):
		if lobbies[lobby_code]["players"][p_id]["id"]:
			rpc_id(lobbies[lobby_code]["players"][p_id]["id"], "update_lobby", lobbies[lobby_code], reason)

remote func leave_lobby(lobby_code):
	var player_id = get_tree().get_rpc_sender_id()
	remove_player_from_lobby(lobby_code, player_id)

remote func kick_player_from_lobby(lobby_code, player_id):
	var kicker_id = get_tree().get_rpc_sender_id()
	var reason = players_names[player_id] + " kicked by " + players_names[kicker_id] + "." 
	rpc_id(player_id, "kicked_from_lobby", reason)
	remove_player_from_lobby(lobby_code, player_id, reason)

func remove_player_from_lobby(lobby_code, player_id, reason = ""):
	if not reason:
		reason = players_names[player_id] + " left."
	if lobbies.has(lobby_code):
		for p_id in range(lobbies[lobby_code]["players"].size()):
			if lobbies[lobby_code]["players"][p_id]["id"] == player_id:
				players_in_lobbies.erase(player_id)
				for other_p_id in range(p_id, lobbies[lobby_code]["players"].size() - 1):
					var color = lobbies[lobby_code]["players"][other_p_id].color
					lobbies[lobby_code]["players"][other_p_id] = lobbies[lobby_code]["players"][other_p_id+1]
					lobbies[lobby_code]["players"][other_p_id].color = color
				lobbies[lobby_code]["players"][lobbies[lobby_code]["players"].size() - 1] = player_dictionary_template
				if lobbies[lobby_code]["current_players"] == 1:
					lobbies.erase(lobby_code)
				else:
					lobbies[lobby_code]["current_players"] -= 1
					update_lobby_to_players(lobby_code, reason)
				break

remote func send_active_lobbies():
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id, "get_active_lobbies", lobbies)

func update_colors(lobby_code):
	pass

remote func send_message(lobby_code, message, sender):
	for i in range(lobbies[lobby_code].current_players):
		var player_id = lobbies[lobby_code].players[i].id
		rpc_id(player_id, "get_message", message, sender)

remote func start_game(lobby_code):
	for i in range(lobbies[lobby_code].current_players):
		var player_id = lobbies[lobby_code].players[i].id
		rpc_id(player_id, "game_started")

remote func send_node_func_call(lobby_code, node_path, function, parameter=null):
	var sender_id = get_tree().get_rpc_sender_id()
	for i in range(lobbies[lobby_code].current_players):
		var player_id = lobbies[lobby_code].players[i].id
		if player_id != sender_id:
			rpc_id(player_id, "get_node_func_call", node_path, function, parameter)

func get_random_color(players_dict):
	randomize()
	var color = colors[randi() % colors.size()]
	var players_colors = []
	for player in players_dict:
		players_colors.append(players_dict[player].color)
	while color in colors:
		color = colors[randi() % colors.size()]
	return color

extends Node

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
	connect_signals()
	start_server()

func connect_signals():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

func start_server():
	var peer = NetworkedMultiplayerENet.new()
	var error = peer.create_server(SERVER_PORT, MAX_PLAYERS)
	if error == OK:
		get_tree().network_peer = peer
	else:
		print("Error creating the server: ", str(error))

func _player_connected(player_id):
	players_online.append(player_id)
	rpc_id(player_id, "send_player_name")

func _player_disconnected(player_id):
	if players_in_lobbies.has(player_id):
		var reason = players_names[player_id] + " disconnected."
		remove_player_from_lobby(players_in_lobbies[player_id], player_id, reason)
	players_online.erase(player_id)
	players_names.erase(player_id)

remote func get_player_name(player_name):
	var player_id = get_tree().get_rpc_sender_id()
	players_names[player_id] = player_name

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

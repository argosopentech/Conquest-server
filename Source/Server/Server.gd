extends Node

const SERVER_PORT = 1909
const MAX_PLAYERS = 2000

var players_online = []
var players_names = {}
var lobbies = {}

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
	rpc_id(player_id, "send_player_data")

func _player_disconnected(player_id):
	pass

remote func get_player_data(player_name):
	var player_id = get_tree().get_rpc_sender_id()
	players_names[player_id] = player_name

remote func create_lobby(lobby_data):
	# Lobby Code [ID]
	lobby_data["code"] = lobbies.size()
	
	# Setting players data for lobby
	var player_id = get_tree().get_rpc_sender_id()
	var player_number = lobby_data["players"].size()
	lobby_data["players"][player_number]["id"] = player_id
	lobby_data["players"][player_number]["name"] = players_names[player_id]
	lobby_data["players"][player_number]["color"] = colors[player_number]
	
	# Append lobbies list
	lobbies[lobbies.size()] = lobby_data
	
	# Notify player
	rpc_id(player_id, "lobby_created", lobby_data)

remote func join_lobby(lobby_code, lobby_pass):
	var player_id = get_tree().get_rpc_sender_id()
	var reason = "Lobby does not exist!"
	if lobbies.has(lobby_code):
		if lobbies[lobby_code]["players"] < lobbies[lobby_code]["max_players"]:
			if lobbies[lobby_code]["pass"] == lobby_pass:
				var player_number = lobbies[lobby_code]["players"].size()
				lobbies[lobby_code]["players"][player_number]["id"] = player_id
				lobbies[lobby_code]["players"][player_number]["name"] = players_names[player_id]
				lobbies[lobby_code]["players"][player_number]["color"] = colors[player_number]
				for player in lobbies[lobby_code]["players"]:
					rpc_id(player["id"], "joined_lobby", lobbies[lobby_code])
			else:
				reason = "Invalid Password!"
				rpc_id(player_id, "failed_to_join_lobby", reason)
		else:
			reason = "Lobby is full!"
			rpc_id(player_id, "failed_to_join_lobby", reason)
	else:
		rpc_id(player_id, "failed_to_join_lobby", reason)

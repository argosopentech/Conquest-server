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

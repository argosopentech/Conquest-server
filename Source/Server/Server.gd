extends Node

const SERVER_PORT = 1909
const MAX_PLAYERS = 500

var players_online = []
var players_data = {}

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

remote func get_player_data(player_data):
	var player_id = get_tree().get_rpc_sender_id()
	players_data[player_id] = player_data

extends Node
class_name HLServer

var server = NetworkedMultiplayerENet.new()
var request_handler = null

signal user_connected(user_id)
signal user_disconnected(user_id)

func connect_server_signals():
	if get_tree().is_connected("network_peer_connected", self, "client_connected"):
		return
	get_tree().connect("network_peer_connected", self, "client_connected")
	get_tree().connect("network_peer_disconnected", self, "client_disconnected")

func disconnect_server_signals():
	if !get_tree().is_connected("network_peer_connected", self, "client_connected"):
		return
	get_tree().disconnect("network_peer_connected", self, "client_connected")
	get_tree().disconnect("network_peer_disconnected", self, "client_disconnected")

func start_server(port = 1909, max_players=2000):
	connect_server_signals()
	if server.create_server(port, max_players) == OK:
		print("The server has started.")
		get_tree().network_peer = server
		return true
	else:
		print("Unable to start the server.")
		return false

func stop_server():
	disconnect_server_signals()
	server.close_connection()
	get_tree().network_peer = null

func set_request_handler(new_handler):
	request_handler = new_handler

func client_connected(id):
	print("Client %d has just connected." % [id])
	emit_signal("user_connected", id)

func client_disconnected(id):
	print("Client %d has just disconnected." % [id])
	emit_signal("user_disconnected", id)

remote func received_data_from_client(method_info):
	var id = get_tree().get_rpc_sender_id()
	print("Just received a packet from client %d: %s." % [id, method_info])
	process_method_info(id, method_info)

func send_data_to_client(id, method, data=null):
	var method_info = {"purpose": "request", "method": method, "data": data}
	rpc_id(id, "received_data_from_server", method_info)

func process_method_info(id, method_info):
	if !request_handler: return
	# method_info = {"purpose": "request", "method": "method", "data": data}
	if method_info is Dictionary & method_info["purpose"] == "request":
		if request_handler.has_method(method_info["method"]):
			request_handler.call_deferred(method_info["method"], [id, method_info["data"]])

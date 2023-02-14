extends Node
class_name WebSocketsServer

var server = WebSocketServer.new()
var request_handler = null

signal user_connected(user_id)
signal user_disconnected(user_id)

func _ready():
	set_process(false)
	
func set_request_handler(new_handler):
	request_handler = new_handler
	
func start_server(port = 9080):
	if server.listen(port) == OK:
		connect_server_signals()
		set_process(true)
		print("The server has started.")
		return true
	else:
		print("Unable to start the server.")
		set_process(false)
		return false
		
func connect_server_signals():
	if server.is_connected("client_connected", self, "client_connected"):
		return
	server.connect("client_connected", self, "client_connected")
	server.connect("client_disconnected", self, "client_disconnected")
	server.connect("data_received", self, "received_data_from_client")
	
func client_connected(id, _protocol):
	print("Client %d has just connected." % [id])
	emit_signal("user_connected", id)
		
func client_disconnected(id, was_clean=false):
	print("Client %d has just disconnected." % [id])
	emit_signal("user_disconnected", id)

func received_data_from_client(id):
	var method_info = server.get_peer(id).get_var(true)
	print("Just received data from client %d: %s." % [id, method_info])
	process_method_info(id, method_info)

func process_method_info(id, method_info):
	if !request_handler: return
	if method_info is Dictionary & method_info.has("purpose") & method_info["purpose"] == "request":
		if request_handler.has_method(method_info["method"]):
			request_handler.call_deferred(method_info["method"], id, method_info["data"])

func _process(delta):
	server.poll()

func send_data_to_client(id, method, data=null):
	var method_info = {"purpose": "request", "method": method, "data": data}
	server.get_peer(id).put_var(method_info, true)

func stop_server():
	disconnect_server_signals()
	server.stop()
	
func disconnect_server_signals():
	if !server.is_connected("client_connected", self, "client_connected"):
		return
	server.disconnect("client_connected", self, "client_connected")
	server.disconnect("client_disconnected", self, "client_disconnected")
	server.disconnect("data_received", self, "received_data_from_client")

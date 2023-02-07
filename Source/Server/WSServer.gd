extends Node
class_name WSServer

var server = WebSocketServer.new()
var request_handler = null

func _ready():
	set_process(false)

func connect_logging_signals():
	if server.is_connected("client_connected", self, "client_connected"):
		return
	server.connect("client_connected", self, "client_connected")
	server.connect("client_disconnected", self, "client_disconnected")

func disconnect_logging_signals():
	if !server.is_connected("client_connected", self, "client_connected"):
		return
	server.disconnect("client_connected", self, "client_connected")
	server.disconnect("client_disconnected", self, "client_disconnected")

func start_server(port = 9080):
	server.connect("data_received", self, "client_data_received")
	if server.listen(port) == OK:
		print("The server has started.")
		set_process(true)
		return true
	else:
		print("Unable to start the server.")
		set_process(false)
		return false

func stop_server():
	server.stop()
	if server.is_connected("data_received", self, "client_data_received"):
		server.disconnect("data_received", self, "client_data_received")

func set_request_handler(new_handler):
	request_handler = new_handler

func client_connected(id, _protocol):
	print("Client %d has just connected." % [id])

func client_disconnected(id, was_clean=false):
	print("Client %d has just disconnected." % [id])

func client_data_received(id):
	var packet = server.get_peer(id).get_packet().get_string_from_utf8()
	print("Just received a packet from client %d: %s." % [id, packet])
	process_packet(id, packet)

func process_packet(id, packet):
	if !request_handler: return
	var data = str2var(packet) # data = ["request", "function_name", parameter]
	if data is Array & data[0] == "request":
		if request_handler.has_method(data[1]):
			request_handler.call_deferred(data[1], [id, data[2]])

func _process(delta):
	server.poll()

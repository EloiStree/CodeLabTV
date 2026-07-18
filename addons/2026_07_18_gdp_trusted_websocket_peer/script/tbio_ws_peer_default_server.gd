class_name TbioWsPeerDefaultServer
extends Node

# Custom signals to notify other nodes
signal on_client_connected(peer_id: int)
signal on_client_disconnected(peer_id: int, code: int, reason: String)
signal on_received_from_client_text(peer_id: int, message: String)
signal on_received_from_client_byte(peer_id: int, data: PackedByteArray)
signal on_received_from_client_text_any( message: String)
signal on_received_from_client_byte_any( data: PackedByteArray)

signal on_send_from_server_to_client_text(text: String)
signal on_send_from_server_to_client_byte(data: PackedByteArray)


# The port we will listen to.
@export var _port = 3617
@export var _listen_interface: String = "0.0.0.0"

# Our WebSocketMultiplayerPeer instance
var _ws_server = WebSocketMultiplayerPeer.new()

# Our connected peers list
var _peers: Dictionary[int, WebSocketPeer] = {}


func _ready():
	# Create the server and start listening
	var err = _ws_server.create_server(_port, _listen_interface)
	if err == OK:
		print("WebSocket server started on port %d." % _port)
		# Connect signals
		_ws_server.peer_connected.connect(_on_peer_connected)
		_ws_server.peer_disconnected.connect(_on_peer_disconnected)
	else:
		push_error("Unable to start WebSocket server.")
		set_process(false)


func _process(_delta):
	# Poll the server for new packets
	_ws_server.poll()
	
	# Process packets from all connected peers
	for peer_id in _peers.keys():
		var peer = _peers[peer_id]
		
		# Poll the individual peer
		peer.poll()
		
		# Get available packets
		var packet_count = peer.get_available_packet_count()
		
		while packet_count > 0:
			var packet = peer.get_packet()
			
			if peer.was_string_packet():
				var packet_text = packet.get_string_from_utf8()
				print("< Got text data from peer %d: %s" % [peer_id, packet_text])
				on_received_from_client_text.emit(peer_id, packet_text)
				on_received_from_client_byte_any.emit(packet_text)
			else:
				print("< Got binary data from peer %d: %d bytes" % [peer_id, packet.size()])
				on_received_from_client_byte.emit(peer_id, packet)
				on_received_from_client_byte_any.emit(packet)
			
			packet_count -= 1


func _on_peer_connected(peer_id: int):
	print("+ Peer %d connected." % peer_id)
	# Get the WebSocketPeer for this connection
	var peer = _ws_server.get_peer(peer_id)
	_peers[peer_id] = peer
	on_client_connected.emit(peer_id)


func _on_peer_disconnected(peer_id: int):
	print("- Peer %d disconnected." % peer_id)
	
	# Get disconnect information if available
	var peer = _peers.get(peer_id)
	var code = -1
	var reason = ""
	
	if peer:
		code = peer.get_close_code()
		reason = peer.get_close_reason()
		_peers.erase(peer_id)
	
	on_client_disconnected.emit(peer_id, code, reason)


# --- Broadcasting Functions ---

func broadcast_text(message: String) -> void:
	for peer_id in _peers:
		var peer = _peers[peer_id]
		if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
			peer.send_text(message)
	on_send_from_server_to_client_text.emit(message)


func broadcast_byte(data: PackedByteArray) -> void:
	for peer_id in _peers:
		var peer = _peers[peer_id]
		if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
			peer.send(data)
	on_send_from_server_to_client_byte.emit(data)
	

func broadcast_ping_and_random():
	broadcast_ping()
	broadcast_random_integer()


func broadcast_ping():
	broadcast_text("ping")
	
	
func broadcast_random_integer():
	var bytes := PackedByteArray()
	bytes.append(randi() % 256)
	broadcast_byte(bytes)


func _on_timer_timeout() -> void:
	pass # Replace with function body.

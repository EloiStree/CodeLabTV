class_name TbioWsPeerDefaultClient
extends Node

# Custom signals
signal on_connected()
signal on_disconnected(code: int, reason: String)
signal on_connection_failed()
signal on_received_text_from_server(text: String)
signal on_received_byte_from_server(data: PackedByteArray)
signal on_sent_text_to_server(text: String)
signal on_sent_byte_to_server(data: PackedByteArray)

# Connection settings
@export var _server_url: String = "ws://0.0.0.0:3617"
@export var _auto_reconnect: bool = true
@export var _reconnect_delay: float = 3.0

# Our WebSocket client (now using MultiplayerPeer)
var _ws_server = WebSocketMultiplayerPeer.new()

# Connection state
var _connected_to_server: bool = false
var _reconnect_timer: float = 0.0
var _peer_id: int = 0  # Unique ID for this client

# Queue for messages sent before connection is ready
var _pending_messages: Array = []

func _ready():
	# Connect to server
	await get_tree().create_timer(_reconnect_timer).timeout
	connect_to_server()
	
	
# Add this diagnostic function to your class
func diagnose_connection():
	var state = _ws_server.get_connection_status()
	var state_names = {
		WebSocketMultiplayerPeer.CONNECTION_DISCONNECTED: "DISCONNECTED",
		WebSocketMultiplayerPeer.CONNECTION_CONNECTING: "CONNECTING",
		WebSocketMultiplayerPeer.CONNECTION_CONNECTED: "CONNECTED",
	}
	
	print("=== DIAGNOSTIC ===")
	print("Connection status: %d (%s)" % [state, state_names.get(state, "UNKNOWN")])
	print("_connected_to_server flag: %s" % _connected_to_server)
	print("Peer ID: %d" % _peer_id)
	print("Pending messages: %d" % _pending_messages.size())
	print("Server URL: %s" % _server_url)
	
		
func _process(delta):
	# Poll the WebSocket client
	_ws_server.poll()
	
	# Get the current state
	var state = _ws_server.get_connection_status()
	
	if state == WebSocketMultiplayerPeer.CONNECTION_CONNECTED:
		if not _connected_to_server:
			_connected_to_server = true
			_peer_id = _ws_server.get_unique_id()
			print("Connected to server! Peer ID: %d" % _peer_id)
			on_connected.emit()
			
			# Send any queued messages
			_flush_pending_messages()
		
		# Read all available packets
		while _ws_server.get_available_packet_count() > 0:
			var packet = _ws_server.get_packet()
			var sender_id = _ws_server.get_packet_peer()
			
			# Check if it's a text or binary packet
			var packet_text = packet.get_string_from_utf8()
			
			# Try to parse as text, fallback to binary
			if packet_text.is_valid_unicode_string() and packet_text.length() > 0:
				print("Got text from peer %d: %s" % [sender_id, packet_text])
				on_received_text_from_server.emit(packet_text)
			else:
				print("Got binary data from peer %d: %d bytes" % [sender_id, packet.size()])
				on_received_byte_from_server.emit(packet)
	
	
	elif state == WebSocketMultiplayerPeer.CONNECTION_DISCONNECTED:
		if _connected_to_server:
			print("Disconnected from server.")
			_connected_to_server = false
			_peer_id = 0
			on_disconnected.emit(0, "Connection closed")
			
			# Handle auto-reconnect
			if _auto_reconnect:
				_reconnect_timer = _reconnect_delay
		
		# Attempt reconnection
		if _auto_reconnect and _reconnect_timer > 0:
			_reconnect_timer -= delta
			if _reconnect_timer <= 0:
				print("Attempting to reconnect...")
				connect_to_server()
	
	elif state == WebSocketMultiplayerPeer.CONNECTION_CONNECTING:
		# Still connecting, do nothing
		pass

func connect_to_server():
	print("Connecting to server: %s" % _server_url)
	
	# Create a new WebSocketMultiplayerPeer if needed
	if _ws_server.get_connection_status() != WebSocketMultiplayerPeer.CONNECTION_DISCONNECTED:
		_ws_server = WebSocketMultiplayerPeer.new()
	
	# For WebSocketMultiplayerPeer, we use create_client() instead of connect_to_url()
	var err = _ws_server.create_client(_server_url)
	
	if err != OK:
		push_error("Unable to connect to server. Error: %d" % err)
		on_connection_failed.emit()
		if _auto_reconnect:
			_reconnect_timer = _reconnect_delay
	else:
		print("Connection initiated...")
	
	return err

func disconnect_from_server(code: int = 1000, reason: String = "Client disconnecting"):
	if _connected_to_server:
		_ws_server.close()
		_connected_to_server = false
		_peer_id = 0
		_pending_messages.clear()

func send_text(text: String) -> bool:
	print("B", text)
	diagnose_connection()
	# Check actual connection state
	var state = _ws_server.get_connection_status()
	
	if state != WebSocketMultiplayerPeer.CONNECTION_CONNECTED:
		# Queue message for later if auto-reconnect is enabled
		if _auto_reconnect:
			_pending_messages.append(text)
			print("Queued message (not connected yet)")
		else:
			push_error("Not connected to server. Cannot send text.")
		return false
	
	print("c", text)
	
	# For WebSocketMultiplayerPeer, we need to specify a target peer
	# Use 0 for broadcast to all peers (or 1 for server in client-server setup)
	var target_peer = 1  # Usually 1 is the server in Godot's multiplayer system
	var err = _ws_server.send_text(text, target_peer)
	
	if err == OK:
		print("Sent text to server: %s" % text)
		on_sent_text_to_server.emit(text)
		return true
	else:
		push_error("Failed to send text to server. Error: %d" % err)
		return false

func send_bytes(data: PackedByteArray) -> bool:
	if not _connected_to_server:
		push_error("Not connected to server. Cannot send bytes.")
		return false
	
	# Use 1 for server target
	var target_peer = 1
	var err = _ws_server.send_bytes(data, target_peer)
	
	if err == OK:
		print("Sent %d bytes to server" % data.size())
		on_sent_byte_to_server.emit(data)
		return true
	else:
		push_error("Failed to send bytes to server. Error: %d" % err)
		return false

func send_ping() -> bool:
	return send_text("ping")

func send_random_byte() -> bool:
	var bytes := PackedByteArray()
	bytes.append(randi() % 256)
	return send_bytes(bytes)

func is_connected_to_server() -> bool:
	return _connected_to_server

func set_server_url(url: String):
	_server_url = url
	# Reconnect with new URL if we were connected
	if _connected_to_server:
		disconnect_from_server()
		connect_to_server()

# Helper to flush pending messages
func _flush_pending_messages():
	for msg in _pending_messages:
		send_text(msg)
	_pending_messages.clear()

# Get unique peer ID (useful for identifying this client)
func get_peer_id() -> int:
	return _peer_id

# Original functions (unchanged)
func push_random_integer():
	var bytes_to_send = integer_to_int32_bytes(randi())
	send_bytes(bytes_to_send)

func push_text_hello_world():
	send_text("Hello World")

func push_byte_42_little_endian():
	send_bytes(integer_to_int32_bytes(42))

func push_hello_world_and_integer_42():
	push_text_hello_world()
	push_byte_42_little_endian()

func push_random_ssd1306_as_byte_array():
	var random_bytes = PackedByteArray()
	for i in range((128*64)/8):
		random_bytes.append(randi() % 256) 
	send_bytes(random_bytes)

const STRING_RANDOM="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

func push_random_ssd1306_as_text():
	var text01 = ""
	for i in range(128*64):
		text01 += String(STRING_RANDOM[randi() % STRING_RANDOM.length()])
	send_text(text01)

func push_index_integer_to_targets(index_int32: int, value_int32: int):
	var byte_as_int_index = integer_to_int32_bytes(index_int32)
	var byte_as_int_value = integer_to_int32_bytes(value_int32)
	var bytes_as_indexed_integer = PackedByteArray()
	bytes_as_indexed_integer.append_array(byte_as_int_index)
	bytes_as_indexed_integer.append_array(byte_as_int_value)
	send_bytes(bytes_as_indexed_integer)

func push_integer_to_targets(value_int32: int):
	var byte_as_int_value = integer_to_int32_bytes(value_int32)
	send_bytes(byte_as_int_value)

func push_iid_to_targets(index_int32: int, value_int32: int, date_ulong64: int):
	var byte_as_int_index = integer_to_int32_bytes(index_int32)
	var byte_as_int_value = integer_to_int32_bytes(value_int32)
	var byte_as_ulong_date = integer_to_ulong64bytes(date_ulong64)
	var bytes_as_iid = PackedByteArray()
	bytes_as_iid.append_array(byte_as_int_index)
	bytes_as_iid.append_array(byte_as_int_value)
	bytes_as_iid.append_array(byte_as_ulong_date)
	send_bytes(bytes_as_iid)

func push_integer_array_as_little_endian_bytes_to_targets(int_array: Array[int]):
	var bytes_to_send = PackedByteArray()
	for value in int_array:
		var byte_as_int_value = integer_to_int32_bytes(value)
		bytes_to_send.append_array(byte_as_int_value)
	send_bytes(bytes_to_send)

func integer_to_int32_bytes(value_int32: int) -> PackedByteArray:
	var byte_array = PackedByteArray()
	byte_array.resize(4)
	byte_array[0] = value_int32 & 0xFF
	byte_array[1] = (value_int32 >> 8) & 0xFF
	byte_array[2] = (value_int32 >> 16) & 0xFF
	byte_array[3] = (value_int32 >> 24) & 0xFF
	return byte_array

func integer_to_ulong64bytes(value_ulong64: int) -> PackedByteArray:
	var byte_array = PackedByteArray()
	byte_array.resize(8)
	byte_array[0] = value_ulong64 & 0xFF
	byte_array[1] = (value_ulong64 >> 8) & 0xFF
	byte_array[2] = (value_ulong64 >> 16) & 0xFF
	byte_array[3] = (value_ulong64 >> 24) & 0xFF
	byte_array[4] = (value_ulong64 >> 32) & 0xFF
	byte_array[5] = (value_ulong64 >> 40) & 0xFF
	byte_array[6] = (value_ulong64 >> 48) & 0xFF
	byte_array[7] = (value_ulong64 >> 56) & 0xFF
	return byte_array

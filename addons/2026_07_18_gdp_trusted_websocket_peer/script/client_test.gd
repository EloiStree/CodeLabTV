extends Node

const SERVER_IP: String = "127.0.0.1"
const PORT: int = 9080

var peer: ENetMultiplayerPeer


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	_connect_to_server()


func _connect_to_server() -> void:
	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(SERVER_IP, PORT)
	if error != OK:
		push_error("Failed to connect to server %s:%d: %s" % [SERVER_IP, PORT, error])
		return

	multiplayer.multiplayer_peer = peer
	print("Connecting to server %s:%d" % [SERVER_IP, PORT])


func _on_peer_connected(id: int) -> void:
	print("Peer connected: %d" % id)


func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: %d" % id)


func _on_connected_ok() -> void:
	print("Connected to server")


func _on_connected_fail() -> void:
	print("Connection failed")


func _on_server_disconnected() -> void:
	print("Server disconnected")


@rpc("any_peer", "call_local", "reliable")
func send_message(message: String) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	print("Message from %d: %s" % [sender_id, message])

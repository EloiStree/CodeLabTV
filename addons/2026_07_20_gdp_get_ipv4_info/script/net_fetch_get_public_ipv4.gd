class_name NetFetchGetPublicIPv4

extends Node

signal on_public_ipv4_updated(ipv4: String)

@export var fetch_at_ready : bool = true

func _ready():
    if Engine.is_editor_hint():
        return
    if fetch_at_ready:
        fetch_public_ipv4()

func fetch_public_ipv4():
    var url = "https://api.ipify.org"
    var http_request = HTTPRequest.new()
    add_child(http_request)    
    http_request.request_completed.connect(_on_request_completed.bind(http_request))
    var error = http_request.request(url)
    if error != OK:
        push_error("HTTP Request failed to start. Error: " + str(error))
        http_request.queue_free()

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_node: HTTPRequest) -> void:
    if http_node:
        http_node.queue_free()
        
    if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
        var ip = body.get_string_from_utf8().strip_edges()
        on_public_ipv4_updated.emit(ip)
    else:
        push_error("Failed to fetch public IPv4. Result: " + str(result) + ", Response Code: " + str(response_code))
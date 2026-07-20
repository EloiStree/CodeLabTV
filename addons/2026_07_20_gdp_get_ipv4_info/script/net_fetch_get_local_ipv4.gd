
class_name NetFetchGetLocalIPv4
extends Node


signal on_ipv4_list_updated(ipv4_list: Array[String])

signal on_ipv4_list_joined_updated(ipv4_list_joined: String)



@export var fetch_at_ready : bool = true
@export var remove_localhost_ipv4 : bool = true
@export var join_splitter : String = ", "
@export var filter_out_ipv4 :bool = true

@export_group("Output")
@export var list_ipv4_addresses : Array[String] = []
@export var ipv4_as_string_joined : String = ""

func _ready():
    if Engine.is_editor_hint():
        return
    if fetch_at_ready:
        fetch_local_ipv4()

func is_ipv4_address_valid(ipv4: String) -> bool:
    # Basic validation for IPv4 address format
    var parts = ipv4.split(".")
    if parts.size() != 4:
        return false
    for part in parts:
        var num = int(part)
        if num < 0 or num > 255:
            return false
    return true


func fetch_local_ipv4():
    list_ipv4_addresses.clear()
    var ipv4_list = IP.get_local_addresses()
    for ipv4 in ipv4_list:
        if remove_localhost_ipv4 and (ipv4 == "127.0.0.1" or ipv4 == "localhost"):
            continue
        if filter_out_ipv4 and not is_ipv4_address_valid(ipv4):
            continue
        list_ipv4_addresses.append(ipv4)


    on_ipv4_list_updated.emit(list_ipv4_addresses)
    ipv4_as_string_joined = join_splitter.join(list_ipv4_addresses)
    on_ipv4_list_joined_updated.emit(ipv4_as_string_joined)
    



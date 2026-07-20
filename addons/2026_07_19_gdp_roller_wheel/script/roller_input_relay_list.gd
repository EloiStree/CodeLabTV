class_name RollerInputRelayList
extends Node



@export var m_input_relay_list : Array[RollerInputRelay] = []
@export var m_parent_to_search_from : Node3D


func _ready():
	if Engine.is_editor_hint():
		return
	search_all_in_childrens_recursively()

func search_all_in_childrens_recursively():
	if m_parent_to_search_from == null:
		push_error("search_all_in_childrens_recursively: m_parent_to_search_from is null")
		return
	m_input_relay_list.clear()
	_search_recursively(m_parent_to_search_from)

func _search_recursively(node: Node):
	if node is RollerInputRelay:
		m_input_relay_list.append(node)
	for child in node.get_children():
		_search_recursively(child)

func get_input_relay_list() -> Array[RollerInputRelay]:
	return m_input_relay_list

func get_input_relay_count() -> int:
	return m_input_relay_list.size()


func relay_input_to(index_0_n:int, back_forward_percent_11: float, left_right_percent_11_roll: float):
	if index_0_n < 0 or index_0_n >= m_input_relay_list.size():
		push_error("relay_input_to: index_0_n out of bounds")
		return
	var relay:RollerInputRelay = m_input_relay_list[index_0_n]
	relay.set_back_forward_percent_11(back_forward_percent_11)
	relay.set_left_right_percent_11_roll(left_right_percent_11_roll)

func relay_input_back_forward_to(index_0_n:int, back_forward_percent_11: float):
	if index_0_n < 0 or index_0_n >= m_input_relay_list.size():
		push_error("relay_input_back_forward_to: index_0_n out of bounds")
		return
	var relay:RollerInputRelay = m_input_relay_list[index_0_n]
	relay.set_back_forward_percent_11(back_forward_percent_11)

func relay_input_left_right_roll_to(index_0_n:int, left_right_percent_11_roll: float):
	if index_0_n < 0 or index_0_n >= m_input_relay_list.size():
		push_error("relay_input_left_right_roll_to: index_0_n out of bounds")
		return
	var relay:RollerInputRelay = m_input_relay_list[index_0_n]
	relay.set_left_right_percent_11_roll(left_right_percent_11_roll)

func relay_input_to_all(back_forward_percent_11: float, left_right_percent_11_roll: float):
	for relay in m_input_relay_list:
		relay.set_back_forward_percent_11(back_forward_percent_11)
		relay.set_left_right_percent_11_roll(left_right_percent_11_roll)

func relay_input_back_forward_to_all(back_forward_percent_11: float):
	for relay in m_input_relay_list:
		relay.set_back_forward_percent_11(back_forward_percent_11)

func relay_input_left_right_roll_to_all(left_right_percent_11_roll: float):
	for relay in m_input_relay_list:
		relay.set_left_right_percent_11_roll(left_right_percent_11_roll)

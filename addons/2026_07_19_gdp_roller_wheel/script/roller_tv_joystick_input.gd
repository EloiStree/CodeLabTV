class_name RollerTVJoystickInput
extends Node

signal on_back_forward_input_changed(percent_11: float)
signal on_left_right_input_changed(percent_11: float)

@export var _use_input: bool = true
@export var _last_back_forward_input := 0.0
@export var _last_left_right_input := 0.0

func _ready():
	if Engine.is_editor_hint():
		return

func enable_input(use_input: bool):
	var changed:bool = _use_input != use_input
	if not changed:
		return
	_use_input = use_input
	if not _use_input:
		_last_back_forward_input = 0.0
		_last_left_right_input = 0.0
		on_back_forward_input_changed.emit(0.0)
		on_left_right_input_changed.emit(0.0)

func _process(_delta: float) -> void:

	if Engine.is_editor_hint():
		return

	if not _use_input:
		return

	var back_forward_input := _get_axis_if_actions_exist("ui_up", "ui_down")
	var left_right_input := _get_axis_if_actions_exist("ui_left", "ui_right")

	var back_forward_released :=   Input.is_action_just_released("ui_down") or Input.is_action_just_released("ui_up")
	var left_right_released := Input.is_action_just_released("ui_left") or Input.is_action_just_released("ui_right")
	if back_forward_released:
		back_forward_input = 0.0

	if left_right_released:
		left_right_input = 0.0

	if not is_equal_approx(back_forward_input, _last_back_forward_input):
		back_forward_input *= -1.0
		_last_back_forward_input = back_forward_input
		on_back_forward_input_changed.emit(back_forward_input)

	if not is_equal_approx(left_right_input, _last_left_right_input):
		_last_left_right_input = left_right_input
		on_left_right_input_changed.emit(left_right_input)


func _get_axis_if_actions_exist(negative_action: StringName, positive_action: StringName) -> float:
	if not InputMap.has_action(negative_action) or not InputMap.has_action(positive_action):
		return 0.0

	return Input.get_axis(negative_action, positive_action)

	

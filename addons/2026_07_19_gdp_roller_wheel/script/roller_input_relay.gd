
class_name RollerInputRelay
extends Node


signal on_percent_11_back_forward_changed(percent_11: float)
signal on_percent_11_left_right_roll_changed(percent_11: float)
signal on_percent_11_back_forward_updated(percent_11: float)
signal on_percent_11_left_right_roll_updated(percent_11: float)

signal on_color_changed(color: Color)
signal on_color_updated(color: Color)


@export_range(-1, 1, 0.001) var m_back_forward_percent_11 : float
@export_range(-1, 1, 0.001) var m_left_right_percent_11_roll : float
@export var m_color : Color = Color(1, 1, 1, 1)

@export var m_push_inspector_value_at_ready : bool = true

func _ready():
	if Engine.is_editor_hint():
		return
	if m_push_inspector_value_at_ready:
		set_back_forward_percent_11(m_back_forward_percent_11)
		set_left_right_percent_11_roll(m_left_right_percent_11_roll)
		set_color(m_color)

func set_color(color: Color):
	var changed:bool = m_color != color
	if changed:
		m_color = color
		on_color_changed.emit(color)
	on_color_updated.emit(color)




func set_back_forward_percent_11(percent_11: float):
	var changed:bool = m_back_forward_percent_11 != percent_11
	if changed:
		m_back_forward_percent_11 = clampf(percent_11, -1.0, 1.0)
		on_percent_11_back_forward_changed.emit(percent_11)
	on_percent_11_back_forward_updated.emit(percent_11)

func set_left_right_percent_11_roll(percent_11: float):
	var changed:bool = m_left_right_percent_11_roll != percent_11
	if changed:
		m_left_right_percent_11_roll = clampf(percent_11, -1.0, 1.0)
		on_percent_11_left_right_roll_changed.emit(percent_11)
	on_percent_11_left_right_roll_updated.emit(percent_11)

func set_with_joystick_vector2(joystick_vector2: Vector2):
	set_back_forward_percent_11(joystick_vector2.y)
	set_left_right_percent_11_roll(joystick_vector2.x)

func set_with_joystick_double_float(back_forward: float, left_right: float):
	set_back_forward_percent_11(back_forward)
	set_left_right_percent_11_roll(left_right)


func turn_left():
	set_left_right_percent_11_roll(-1.0)

func turn_right():

	set_left_right_percent_11_roll(1.0)

func stop_turning():
	set_left_right_percent_11_roll(0.0)


func move_forward():
	set_back_forward_percent_11(1.0)

func move_backward():

	set_back_forward_percent_11(-1.0)

func stop_moving():
	set_back_forward_percent_11(0.0)

func stop_all_movement():
	stop_turning()
	stop_moving()


func set_as_turn_left(is_turn_left: bool):
	if is_turn_left:
		turn_left()
	else:
		stop_turning()

func set_as_turn_right(is_turn_right: bool):
	if is_turn_right:
		turn_right()
	else:
		stop_turning()


func set_as_move_forward(is_move_forward: bool):
	if is_move_forward:
		move_forward()
	else:
		stop_moving()


func set_as_move_backward(is_move_backward: bool):
	if is_move_backward:
		move_backward()
	else :
		stop_moving()

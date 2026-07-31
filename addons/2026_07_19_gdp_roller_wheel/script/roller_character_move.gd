class_name RollerCharacterMoveBasic
extends Node


@export var _character_controller : CharacterBody3D

@export_group("Input")
@export_range(-1, 1, 0.001) var _percent_11_back_forward : float
@export_range(-1, 1, 0.001) var _percent_11_left_right_roll : float


@export var _input_lerp_multiplier : float = 10.0
@export_range(-1, 1, 0.001) var _percent_11_back_forward_lerped : float
@export_range(-1, 1, 0.001) var _percent_11_left_right_roll_lerped : float


@export_group("Settings")
@export var _max_wheel_roll_angle: float = 45.0
@export var _max_wheel_rotation_left_right: float = 90.0
@export var _max_wheel_rotation_per_seconds: float = 720.0
@export var _gravity: float = 20.0

@export_group("Anchor")
@export var _roll_anchor_to_rotate: Node3D
@export var _forward_wheel_rotation_state_anchor: Node3D
@export var _wheel_radius_center_point: Node3D
@export var _wheel_radius_up_point: Node3D


@export_group("Debug")
@export var _current_rotation_forward_speed_in_degree: float = 0.0
@export var _current_total_rotation_forward_in_degree: float = 0.0

func get_radius_distance() -> float:
	return _wheel_radius_center_point.global_position.distance_to(_wheel_radius_up_point.global_position)

func set_speed_in_degree(degree: float):
	_percent_11_back_forward = degree/ _max_wheel_rotation_per_seconds
	
func set_speed_in_percent_11(percent_11: float):
	_percent_11_back_forward = clampf(percent_11, -1.0, 1.0)
	
func set_speed_with_distance_per_second(distance_per_seconds: float):
	var radius: float = get_radius_distance()
	if radius == 0.0:
		return
	var circonference: float = radius * 2.0 * PI
	var rotations_per_second: float = distance_per_seconds / circonference
	var degrees_per_second: float = rotations_per_second * 360.0
	set_speed_in_degree(degrees_per_second)


func set_with_joystick_vector2(x_right_y_forward:Vector2):
	set_back_forward_percent11(x_right_y_forward.y)
	set_left_right_percent11(x_right_y_forward.x)
	
func set_with_joystick_double_float(back_forward:float, left_right:float):
	set_back_forward_percent11(back_forward)
	set_left_right_percent11(left_right)


func set_back_forward_percent11(back_forward:float):
	_percent_11_back_forward = clampf(back_forward, -1.0, 1.0)
	
	
func set_left_right_percent11(left_right:float):
	_percent_11_left_right_roll = clampf(left_right, -1.0, 1.0)
	


func _physics_process(delta: float):

	_percent_11_back_forward_lerped = lerp(_percent_11_back_forward_lerped, _percent_11_back_forward, delta * _input_lerp_multiplier)
	_percent_11_left_right_roll_lerped = lerp(_percent_11_left_right_roll_lerped, _percent_11_left_right_roll, delta * _input_lerp_multiplier)


	_current_rotation_forward_speed_in_degree = _max_wheel_rotation_per_seconds * _percent_11_back_forward_lerped
	
	if _current_rotation_forward_speed_in_degree != 0.0:
		_current_total_rotation_forward_in_degree += _current_rotation_forward_speed_in_degree * delta
		_current_total_rotation_forward_in_degree = fmod(_current_total_rotation_forward_in_degree, 360.0)	
	_forward_wheel_rotation_state_anchor.rotation_degrees.x = -_current_total_rotation_forward_in_degree
	
	var distance_to_move_forward: float = 0.0
	var radius: float = get_radius_distance()
	if radius > 0.0:
		var circonference: float = radius * 2.0 * PI
		var degrees_rotated_this_frame = _current_rotation_forward_speed_in_degree * delta
		distance_to_move_forward = (degrees_rotated_this_frame / 360.0) * circonference
		
	var moving_percent: float = absf(_percent_11_back_forward_lerped)
	var move_direction_sign: float = sign(_percent_11_back_forward_lerped)
	var degree_to_rotate: float = -_percent_11_left_right_roll_lerped * moving_percent * move_direction_sign * delta * _max_wheel_rotation_left_right
	_character_controller.rotate_y(deg_to_rad(degree_to_rotate))
	var forward_direction = -_character_controller.global_transform.basis.z
	if distance_to_move_forward != 0.0:
		_character_controller.velocity = forward_direction * (distance_to_move_forward / delta)
	else:
		_character_controller.velocity = Vector3.ZERO
	
	if not _character_controller.is_on_floor():
		_character_controller.velocity.y = -_gravity

	_character_controller.move_and_slide()
	var target_roll_degree = _max_wheel_roll_angle * -_percent_11_left_right_roll_lerped
	_roll_anchor_to_rotate.rotation_degrees.z = target_roll_degree
		
	

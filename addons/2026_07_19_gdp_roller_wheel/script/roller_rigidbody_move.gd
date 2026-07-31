class_name RollerRigidBodyMoveBasic
extends Node

@export var _rigid_body_controller : RigidBody3D

@export_group("Input")
@export_range(-1, 1, 0.001) var _percent_11_back_forward : float
@export_range(-1, 1, 0.001) var _percent_11_left_right_roll : float

@export var _input_lerp_forward_multiplier : float = 10.0
@export var _input_lerp_roll_multiplier : float = 2.0
@export_range(-1, 1, 0.001) var _percent_11_back_forward_lerped : float
@export_range(-1, 1, 0.001) var _percent_11_left_right_roll_lerped : float

@export_group("Settings")
@export var _max_wheel_roll_angle: float = 15.0
@export var _max_wheel_rotation_left_right: float = 360.0
@export var _max_wheel_rotation_per_seconds: float = 720.0
@export var _gravity: float = 9

# Changed from 'force' to 'max_speed' for easier control of Rigidbodies
@export var _max_speed_forward_backward: float = 30
@export var _movement_acceleration: float = 50.0
@export var _steering_torque: float = 15.0

@export_group("Anchor")
@export var _roll_anchor_to_rotate: Node3D
@export var _forward_wheel_rotation_state_anchor: Node3D
@export var _wheel_radius_center_point: Node3D
@export var _wheel_radius_up_point: Node3D
@export var _forward_force_direction: Node3D

@export_group("Debug")
@export var _current_rotation_forward_speed_in_degree: float = 0.0
@export var _current_total_rotation_forward_in_degree: float = 0.0

func _ready():
	if Engine.is_editor_hint():
		return
		
	# Set up the RigidBody for 50kg and continuous collision detection (important for fast moving balls)
	_rigid_body_controller.mass = 50.0
	_rigid_body_controller.continuous_cd = true
	_rigid_body_controller.contact_monitor = true
	_rigid_body_controller.max_contacts_reported = 10
	
	# Give the ball a bouncy physics material so it kicks other balls effectively
	var phys_mat = PhysicsMaterial.new()
	phys_mat.bounce = 0.8
	phys_mat.friction = 0.8
	_rigid_body_controller.physics_material_override = phys_mat

func get_radius_distance() -> float:
	return _wheel_radius_center_point.global_position.distance_to(_wheel_radius_up_point.global_position)

func set_speed_in_degree(degree: float):
	_percent_11_back_forward = degree / _max_wheel_rotation_per_seconds
	
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
	if Engine.is_editor_hint():
		return

	_percent_11_back_forward_lerped = lerp(_percent_11_back_forward_lerped, _percent_11_back_forward, delta * _input_lerp_forward_multiplier)
	_percent_11_left_right_roll_lerped = lerp(_percent_11_left_right_roll_lerped, _percent_11_left_right_roll, delta * _input_lerp_roll_multiplier)

	# Visual wheel spinning
	_current_rotation_forward_speed_in_degree = _max_wheel_rotation_per_seconds * _percent_11_back_forward_lerped
	if _current_rotation_forward_speed_in_degree != 0.0:
		_current_total_rotation_forward_in_degree += _current_rotation_forward_speed_in_degree * delta
		_current_total_rotation_forward_in_degree = fmod(_current_total_rotation_forward_in_degree, 360.0)	
	_forward_wheel_rotation_state_anchor.rotation_degrees.x = -_current_total_rotation_forward_in_degree
	
	# Visual rolling tilt
	var target_roll_degree = _max_wheel_roll_angle * -_percent_11_left_right_roll_lerped
	_roll_anchor_to_rotate.rotation_degrees.z = target_roll_degree

	# --- PHYSICS MOVEMENT & KICKING ---
	
	# 1. Apply Custom Gravity as a continuous force
	_rigid_body_controller.apply_central_force(Vector3.DOWN * _gravity * _rigid_body_controller.mass)
	
	# 2. Forward / Backward Movement
	var forward_direction = -_rigid_body_controller.global_transform.basis.z
	var target_velocity = forward_direction * (_max_speed_forward_backward * _percent_11_back_forward_lerped)
	
	# Calculate how much force is needed to reach target velocity (acceleration)
	# This allows natural momentum and physics-based collisions (kicking other balls)
	var current_velocity = _rigid_body_controller.linear_velocity
	var velocity_diff = target_velocity - current_velocity
	velocity_diff.y = 0.0 # Don't let movement forces interfere with gravity
	
	# Apply movement force proportional to 50kg mass
	_rigid_body_controller.apply_central_force(velocity_diff * _rigid_body_controller.mass * _movement_acceleration * delta)
	
	# 3. Steering (Left / Right turning)
	var moving_percent: float = absf(_percent_11_back_forward_lerped)
	var move_direction_sign: float = sign(_percent_11_back_forward_lerped)
	
	# Calculate target yaw rotation speed
	var degree_to_rotate: float = -_percent_11_left_right_roll_lerped * moving_percent * move_direction_sign * _max_wheel_rotation_left_right
	var target_angular_y = deg_to_rad(degree_to_rotate)
	
	# Apply torque to steer the rigidbody physically
	var current_angular = _rigid_body_controller.angular_velocity.y
	var angular_diff = target_angular_y - current_angular
	_rigid_body_controller.apply_torque(Vector3.UP * angular_diff * _rigid_body_controller.mass * _steering_torque * delta)

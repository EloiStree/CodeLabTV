class_name RollerSetMeshColor
extends Node



@export var _standard_material : StandardMaterial3D
@export var _meshes_instance : Array[MeshInstance3D]
@export var _color : Color = Color(1, 1, 1, 1)
@export var _set_random_color_at_ready : bool = true

var _material_duplicated :StandardMaterial3D

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_material_duplicated = _standard_material.duplicate() as StandardMaterial3D

	if _set_random_color_at_ready:
		var random_color = Color(randf(), randf(), randf(), 1.0)
		set_mesh_color(random_color)
	else:
		set_mesh_color(_color)


func set_mesh_color(color: Color):
	if _material_duplicated == null:
		push_error("set_mesh_color: _material_duplicated is null")
		return
	_color = color
	_material_duplicated.albedo_color = color
	for mesh_instance in _meshes_instance:
		if mesh_instance !=null:
			mesh_instance.set_surface_override_material(0, _material_duplicated)

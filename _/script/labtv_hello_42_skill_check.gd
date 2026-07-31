class_name CodeLabTvHello42SkillCheck
extends Node

@export var scene_to_load: PackedScene

@export var integer_to_look_for: int = 42
@export var text_to_look_for: String = "Hello World"

func check_for_specific_text(text: String) -> void:
	if text_to_look_for == text.strip_edges():
		load_next_scene()

func check_for_specific_integer(value_integer: int) -> void:
	if value_integer == integer_to_look_for:
		load_next_scene()
		
func check_for_specific_byte_pack_as_integer(data: PackedByteArray) -> void:
	if data.size() != 4:
		return

	var value := (
		data[0]
		| (data[1] << 8)
		| (data[2] << 16)
		| (data[3] << 24)
	)

	if value == 42:
		load_next_scene()

func load_next_scene() -> void:
	if scene_to_load:
		get_tree().change_scene_to_packed(scene_to_load)
	else:
		push_warning("No scene assigned to 'scene_to_load'.")

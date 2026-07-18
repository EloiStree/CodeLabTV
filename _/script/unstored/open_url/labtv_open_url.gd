class_name LabTvOpenUrl
extends Node

@export var _url_to_open: String

func open_url_in_inspector():
	open_url(_url_to_open)

func open_url(url: String):
	if url.strip_edges().is_empty():
		return

	var err := OS.shell_open(url)
	if err != OK:
		push_error("Failed to open URL: %s (Error %d)" % [url, err])

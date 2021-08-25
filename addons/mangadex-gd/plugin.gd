tool
extends EditorPlugin

var plugin_display

func _enter_tree():
	plugin_display = load("res://addons/mangadex-gd/plugin_display.tscn").instance()
	get_editor_interface().get_editor_viewport().add_child(plugin_display)
	make_visible(false)

func _exit_tree():
	if plugin_display:
		plugin_display.queue_free()

func has_main_screen():
	return true

func make_visible(visible):
	if plugin_display:
		plugin_display.visible = visible

func get_plugin_name():
	return "MangaDex GD"

func get_plugin_icon():
	return get_editor_interface().get_base_control().get_icon("CanvasLayer", "EditorIcons")

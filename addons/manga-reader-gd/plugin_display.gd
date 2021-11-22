tool
extends Control

var main: Node

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	main = load("res://addons/manga-reader-gd/main_display.tscn").instance()
	add_child(main)
	main.setup()

func _exit_tree() -> void:
	if main:
		main.queue_free()

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


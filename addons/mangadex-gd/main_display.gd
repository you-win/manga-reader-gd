tool
extends Control

enum RequestType {
	NONE = 0,
	PING,
	LOGIN,
	USER_DATA,
	USER_FEED,
	USER_FOLLOWED_MANGA,
	GET_MANGA,
	GET_CHAPTER
}

var client_pool: Node

var current_screen: Control

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	print("starting!")
	client_pool = load("res://addons/mangadex-gd/client_pool.gd").new()
	client_pool.main = self
	call_deferred("add_child", client_pool)
	
	current_screen = load("res://addons/mangadex-gd/screens/login_screen.tscn").instance()
	current_screen.main = self
	call_deferred("add_child", current_screen)

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func change_screen_to(path: String) -> void:
	current_screen.queue_free()
	
	yield(get_tree(), "idle_frame")
	
	current_screen = load(path).instance()
	current_screen.main = self
	call_deferred("add_child", current_screen)

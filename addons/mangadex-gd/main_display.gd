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
	GET_CHAPTER,

	GET_MDAH_SERVER,

	GET_MANGA_PAGE
}

var client_pool: Node

var current_screen: Control

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	if not Engine.editor_hint:
		setup()

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

func change_screen(screen: Node) -> void:
	current_screen.queue_free()

	yield(get_tree(), "idle_frame")

	screen.main = self
	call_deferred("add_child", screen)

func setup() -> void:
	print("starting!")
	client_pool = load("res://addons/mangadex-gd/client_pool.gd").new()
	client_pool.main = self
	call_deferred("add_child", client_pool)
	
	current_screen = load("res://addons/mangadex-gd/screens/login_screen.tscn").instance()
	current_screen.main = self
	call_deferred("add_child", current_screen)

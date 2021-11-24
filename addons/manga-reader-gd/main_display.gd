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
	VIEW_MANGA,
	GET_CHAPTER,

	GET_MDAH_SERVER,

	GET_MANGA_PAGE
}

const CLIENT_POOL: Resource = preload("res://addons/manga-reader-gd/client_pool.gd")
const LOGIN_SCREEN: PackedScene = preload("res://addons/manga-reader-gd/screens/login_screen.tscn")

class LFU:
	const LFU_MAX: int = 50
	
	var lfu: Dictionary # String: PoolByteArray

	func _init() -> void:
		lfu = {}

	func find(key: String):
		var result = lfu.get(key)
		if result:
			lfu.erase(key)
			lfu[key] = result
			return result
			
		return null
	
	func add(key: String, data) -> void:
		lfu[key] = data
		
		if lfu.size() > LFU_MAX:
			lfu.erase(lfu.keys()[0])

var image_lfu: LFU
var request_lfu: LFU

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

func change_screen(screen) -> void:
	current_screen.queue_free()

	yield(get_tree(), "idle_frame")
	
	match typeof(screen):
		TYPE_OBJECT:
			current_screen = screen
		TYPE_STRING:
			current_screen = load(screen).instance()
		_:
			print_debug("Tried to change screen to unhandled type")

	current_screen.main = self
	call_deferred("add_child", current_screen)

func setup() -> void:
	print("starting!")
	client_pool = CLIENT_POOL.new()
	client_pool.main = self
	call_deferred("add_child", client_pool)
	
	current_screen = LOGIN_SCREEN.instance()
	current_screen.main = self
	call_deferred("add_child", current_screen)

	image_lfu = LFU.new()
	request_lfu = LFU.new()

tool
extends "res://addons/mangadex-gd/screens/base_screen.gd"

const READ_CHAPTER_SCENE: PackedScene = preload("res://addons/mangadex-gd/screens/read_chapter.tscn")

export var username_field_path: NodePath
export var user_feed_path: NodePath

onready var username_field: Label = get_node(username_field_path)
onready var user_feed: VBoxContainer = get_node(user_feed_path)

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	var user_data_client = yield(main.client_pool.get_next_available_client(), "completed")
	user_data_client.get_user_data()

	var user_feed_client = yield(main.client_pool.get_next_available_client(), "completed")
	user_feed_client.get_user_feed("en", 0) # TODO hardcoded values

###############################################################################
# Connections                                                                 #
###############################################################################

func _handle_response(request_type: int, response_status: int, response_body) -> void:
	match request_type:
		main.RequestType.USER_DATA:
			if response_body.empty():
				print_debug("User data response empty")
				return
			username_field.text = response_body["data"]["attributes"]["username"]
		main.RequestType.USER_FEED:
			if response_body.empty():
				print_debug("User feed response empty")
				return
			
			# TODO unused for now
			var limit = response_body["limit"]
			var offset = response_body["offset"]

			var data: Array = response_body["data"]

			# TODO this is gross
			for chapter_data in data:
				var button := Button.new()
				button.text = "%s - %s" % [chapter_data["attributes"]["title"], chapter_data["attributes"]["chapter"]]
				button.connect("pressed", self, "_on_read_chapter", [chapter_data])

				user_feed.call_deferred("add_child", button)

func _on_read_chapter(data: Dictionary) -> void:
	var read_chapter_screen = READ_CHAPTER_SCENE.instance()
	read_chapter_screen.chapter_id = data["id"]
	read_chapter_screen.chapter_hash = data["attributes"]["hash"]
	read_chapter_screen.chapter_page_ids = data["attributes"]["data"]
	
	main.change_screen(read_chapter_screen)

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################



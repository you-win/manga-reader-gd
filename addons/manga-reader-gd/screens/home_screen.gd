tool
extends "res://addons/manga-reader-gd/screens/base_screen.gd"

const READ_CHAPTER_SCENE: PackedScene = preload("res://addons/manga-reader-gd/screens/read_chapter.tscn")

const AUTOWRAP_BUTTON: PackedScene = preload("res://addons/manga-reader-gd/autowrap_button.tscn")

export var username_field_path: NodePath
export var user_feed_path: NodePath

onready var username_field: Label = get_node(username_field_path)
onready var user_feed: VBoxContainer = get_node(user_feed_path)

var chapter_data: Dictionary = {} # {string: [{}]}

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
			username_field.text = response_body["data"]["attributes"]["username"]
		main.RequestType.USER_FEED:
			
			# TODO unused for now
			var limit = response_body["limit"]
			var offset = response_body["offset"]

			# chapter_data = response_body["data"]

			# var manga_ids := []
			for data in response_body["data"]:
				for rel in data["relationships"]:
					if rel.get("type") == "manga":
						# manga_ids.append(rel["id"])
						var id = rel["id"]
						if not chapter_data.has(id):
							chapter_data[id] = []
						chapter_data[id].append(data)
						break

			var client = yield(main.client_pool.get_next_available_client(), "completed")
			client.get_manga(chapter_data.keys())
		main.RequestType.GET_MANGA:
			for data in response_body["data"]:
				# TODO assume english
				var titles: Dictionary = data["attributes"]["title"]
				var chapter_name: String = ""
				if titles.has("en"):
					chapter_name = titles["en"]
				elif titles.has("ja"):
					chapter_name = titles["ja"]
				else:
					chapter_name = titles[titles.keys()[0]] # Get a random title
				
				for cd in chapter_data[data["id"]]:
					var button = AUTOWRAP_BUTTON.instance()
					user_feed.add_child(button)
					
					var b = button.get_node("Button")
					var l = button.get_node("PanelContainer/Label")
					
					var chapter_title: String = cd["attributes"]["title"] if cd["attributes"]["title"] else ""
					
					l.text = "%s: %s" % [chapter_name, cd["attributes"]["chapter"]]
					if not chapter_title.empty():
						l.text = "%s - %s" % [l.text, chapter_title]
					
					b.connect("pressed", self, "_on_read_chapter", [cd])

					# user_feed.call_deferred("add_child", button)
#					button.add_child(label)

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


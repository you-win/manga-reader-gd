tool
extends "res://addons/manga-reader-gd/screens/base_screen.gd"

const LOGIN_SCREEN_PATH: String = "res://addons/manga-reader-gd/screens/login_screen.tscn"
const READ_CHAPTER_PATH: String = "res://addons/manga-reader-gd/screens/read_chapter.tscn"

const AUTOWRAP_BUTTON: PackedScene = preload("res://addons/manga-reader-gd/autowrap_button.tscn")

# Top bar
export var logout_button_path: NodePath
export var search_bar_path: NodePath
export var refresh_button_path: NodePath

onready var logout_button: Button = get_node(logout_button_path) as Button
onready var search_bar: LineEdit = get_node(search_bar_path) as LineEdit
onready var refresh_button: Button = get_node(refresh_button_path) as Button

# User data
export var username_field_path: NodePath
export var user_feed_path: NodePath

onready var username_field: Label = get_node(username_field_path) as Label
onready var user_feed: VBoxContainer = get_node(user_feed_path) as VBoxContainer

var chapter_data: Dictionary = {} # {string: [{}]}

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	logout_button.connect("pressed", self, "_on_logout")
	search_bar.connect("text_entered", self, "_on_search_bar_enter_pressed")
	refresh_button.connect("pressed", self, "_on_refresh")

	_get_data()

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

			# User feed data only contains chapter information
			# We find manga information in a separate request
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
	var read_chapter_screen = load(READ_CHAPTER_PATH).instance()
	read_chapter_screen.chapter_id = data["id"]
	read_chapter_screen.chapter_hash = data["attributes"]["hash"]
	read_chapter_screen.chapter_page_ids = data["attributes"]["data"]
	
	main.change_screen(read_chapter_screen)

func _on_logout() -> void:
	main.change_screen(LOGIN_SCREEN_PATH)

func _on_search_bar_enter_pressed(text: String) -> void:
	
	pass

func _on_refresh() -> void:
	for child in user_feed.get_children():
		child.free()
	chapter_data.clear()
	_get_data()

###############################################################################
# Private functions                                                           #
###############################################################################

func _get_data() -> void:
	var user_data_client = yield(main.client_pool.get_next_available_client(), "completed")
	user_data_client.get_user_data()

	var user_feed_client = yield(main.client_pool.get_next_available_client(), "completed")
	user_feed_client.get_user_feed("en", 0) # TODO hardcoded values

###############################################################################
# Public functions                                                            #
###############################################################################

tool
extends "res://addons/manga-reader-gd/screens/base_screen.gd"

const LOGIN_SCREEN_PATH: String = "res://addons/manga-reader-gd/screens/login_screen.tscn"
const READ_CHAPTER_PATH: String = "res://addons/manga-reader-gd/screens/read_chapter.tscn"
const VIEW_MANGA_PATH: String = "res://addons/manga-reader-gd/screens/view-manga/view_manga.tscn"

const AUTOWRAP_BUTTON: PackedScene = preload("res://addons/manga-reader-gd/screens/home-screen/autowrap_button.tscn")
const SEARCH_RESULT_POPUP: PackedScene = preload("res://addons/manga-reader-gd/screens/home-screen/search_result_popup.tscn")

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

			for data in response_body["data"]:
				for rel in data["relationships"]:
					if rel.get("type") == "manga":
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
				var manga_title: String = _get_manga_title_from_manga_response(data)
				
				for cd in chapter_data[data["id"]]:
					var button = AUTOWRAP_BUTTON.instance()
					user_feed.add_child(button)
					
					var b = button.get_node("Button")
					var l = button.get_node("PanelContainer/Label")
					
					var chapter_title: String = cd["attributes"]["title"] if cd["attributes"]["title"] else ""
					
					l.text = "%s: %s" % [manga_title, cd["attributes"]["chapter"]]
					if not chapter_title.empty():
						l.text = "%s - %s" % [l.text, chapter_title]
					
					b.connect("pressed", self, "_on_read_chapter", [cd])
		main.RequestType.SEARCH_MANGA:
			var popup: Popup = SEARCH_RESULT_POPUP.instance()
			for data in response_body["data"]:
				var manga_title: String = _get_manga_title_from_manga_response(data)

				var button := Button.new()
				button.text = manga_title
				button.connect("pressed", self, "_on_view_manga", [data])

				popup.buttons.append(button)
			
			add_child(popup)

func _on_read_chapter(data: Dictionary) -> void:
	var read_chapter_screen = load(READ_CHAPTER_PATH).instance()
	read_chapter_screen.chapter_id = data["id"]
	read_chapter_screen.chapter_hash = data["attributes"]["hash"]
	read_chapter_screen.chapter_page_ids = data["attributes"]["data"]
	
	main.change_screen(read_chapter_screen)

func _on_view_manga(data: Dictionary) -> void:
	var view_manga_screen = load(VIEW_MANGA_PATH).instance()
	view_manga_screen.manga_data = data
	
	main.change_screen(view_manga_screen)

func _on_logout() -> void:
	main.change_screen(LOGIN_SCREEN_PATH)

func _on_search_bar_enter_pressed(text: String) -> void:
	if text.empty():
		return
	var client = yield(main.client_pool.get_next_available_client(), "completed")
	client.search_manga(text)

func _on_refresh() -> void:
	for child in user_feed.get_children():
		child.free()
	chapter_data.clear()
	_get_data()

###############################################################################
# Private functions                                                           #
###############################################################################

func _get_data(force_refresh: bool = false) -> void:
	var user_data_client = yield(main.client_pool.get_next_available_client(), "completed")
	if force_refresh:
		user_data_client.force_new_request = true
	user_data_client.get_user_data()

	var user_feed_client = yield(main.client_pool.get_next_available_client(), "completed")
	if force_refresh:
		user_feed_client.force_new_request = true
	user_feed_client.get_user_feed("en", 0) # TODO hardcoded values

func _get_manga_title_from_manga_response(data: Dictionary) -> String:
	# TODO assume english
	var titles: Dictionary = data["attributes"]["title"]
	var manga_title: String = ""
	if titles.has("en"):
		manga_title = titles["en"]
	elif titles.has("ja"):
		manga_title = titles["ja"]
	else:
		manga_title = titles[titles.keys()[0]] # Get a random title

	return manga_title

###############################################################################
# Public functions                                                            #
###############################################################################

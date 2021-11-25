tool
extends "res://addons/manga-reader-gd/screens/base_screen.gd"

const HOME_SCREEN_PATH: String = "res://addons/manga-reader-gd/screens/home-screen/home_screen.tscn"

# MangaContainer
export var scroll_container_path: NodePath
export var manga_page_path: NodePath

onready var scroll_container: ScrollContainer = get_node(scroll_container_path) as ScrollContainer
onready var manga_page: TextureRect = get_node(manga_page_path) as TextureRect

onready var v_scroll: VScrollBar = scroll_container.get_v_scrollbar()
onready var h_scroll: HScrollBar = scroll_container.get_h_scrollbar()

# Controls
export var left_button_path: NodePath
export var middle_button_path: NodePath
export var right_button_path: NodePath

onready var left_button: Button = get_node(left_button_path) as Button
onready var middle_button: Button = get_node(middle_button_path) as Button
onready var right_button: Button = get_node(right_button_path) as Button

# TopBar
export var options_container_path: NodePath
export var hide_options_button_path: NodePath
export var back_button_path: NodePath
export var refresh_button_path: NodePath

onready var options_container: Control = get_node(options_container_path) as Control
onready var hide_options_button: Button = get_node(hide_options_button_path) as Button
onready var back_button: Button = get_node(back_button_path) as Button
onready var refresh_button: Button = get_node(refresh_button_path) as Button

var chapter_id: String
var chapter_hash: String
var chapter_page_ids: Array

var current_page_index: int = 0

var mdah_server: String
const MDAH_SERVER_RETRY_MAX: int = 3
var mdah_server_retry_count: int = 0

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	left_button.connect("pressed", self, "_on_left")
	middle_button.connect("pressed", self, "_on_middle")
	right_button.connect("pressed", self, "_on_right")
	
	hide_options_button.connect("pressed", self, "_on_hide_options")
	back_button.connect("pressed", self, "_on_back")
	refresh_button.connect("pressed", self, "_on_refresh")
	
	options_container.hide()
	
	var mdah_server_client = yield(main.client_pool.get_next_available_client(), "completed")
	mdah_server_client.get_mdah_server(chapter_id)

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_WHEEL_UP:
				scroll_container.scroll_vertical = clamp(scroll_container.scroll_vertical - 20.0, 0.0, v_scroll.max_value)
			BUTTON_WHEEL_DOWN:
				scroll_container.scroll_vertical = clamp(scroll_container.scroll_vertical + 20.0, 0.0, v_scroll.max_value)
			_:
				pass

###############################################################################
# Connections                                                                 #
###############################################################################

func _handle_response(request_type: int, response_status: int, response_body) -> void:
	match request_type:
		main.RequestType.GET_MDAH_SERVER:
			if response_body.empty():
				print_debug("MDaH response empty")
				return
			
			mdah_server = response_body["baseUrl"]

			var get_manga_page_client = yield(main.client_pool.get_next_available_client(), "completed")
			get_manga_page_client.get_manga_page(mdah_server, chapter_hash, chapter_page_ids[current_page_index])
		main.RequestType.GET_MANGA_PAGE:
			if response_body.empty():
				print_debug("Get manga page response empty")
				return

			var image := Image.new()
			if (image.load_png_from_buffer(response_body) != OK and
				image.load_jpg_from_buffer(response_body) != OK and
				image.load_bmp_from_buffer(response_body) != OK and
				image.load_tga_from_buffer(response_body) != OK and
				image.load_webp_from_buffer(response_body) != OK):
				print_debug("Unable to load manga page as any format")
				if mdah_server_retry_count < MDAH_SERVER_RETRY_MAX:
					mdah_server_retry_count += 1
					var mdah_server_client = yield(main.client_pool.get_next_available_client(), "completed")
					mdah_server_client.get_mdah_server(chapter_id)
				else:
					print("Unable to successfully load in image after %d retries, declining to start again", MDAH_SERVER_RETRY_MAX)
				return
			mdah_server_retry_count = 0
			
			var texture := ImageTexture.new()
			texture.create_from_image(image)

			manga_page.texture = texture

func _on_left() -> void:
	current_page_index -= 1
	if current_page_index < 0:
		current_page_index = 0
		return
	var get_manga_page_client = yield(main.client_pool.get_next_available_client(), "completed")
	get_manga_page_client.get_manga_page(mdah_server, chapter_hash, chapter_page_ids[current_page_index])

func _on_middle() -> void:
	options_container.show()

func _on_right() -> void:
	current_page_index += 1
	if current_page_index >= chapter_page_ids.size():
		current_page_index -= 1
		return
	var get_manga_page_client = yield(main.client_pool.get_next_available_client(), "completed")
	get_manga_page_client.get_manga_page(mdah_server, chapter_hash, chapter_page_ids[current_page_index])

func _on_hide_options() -> void:
	options_container.hide()

func _on_back() -> void:
	# TODO hardcoded to homescreen for now
	main.change_screen(HOME_SCREEN_PATH)

func _on_refresh() -> void:
	var get_manga_page_client = yield(main.client_pool.get_next_available_client(), "completed")
	get_manga_page_client.get_manga_page(mdah_server, chapter_hash, chapter_page_ids[current_page_index])

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

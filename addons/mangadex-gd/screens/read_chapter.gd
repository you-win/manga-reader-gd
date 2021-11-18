tool
extends "res://addons/mangadex-gd/screens/base_screen.gd"

export var scroll_container_path: NodePath
export var manga_page_path: NodePath
export var left_button_path: NodePath
export var middle_button_path: NodePath
export var right_button_path: NodePath

onready var scroll_container: ScrollContainer = get_node(scroll_container_path) as ScrollContainer
onready var manga_page: TextureRect = get_node(manga_page_path) as TextureRect
onready var left_button: Button = get_node(left_button_path) as Button
onready var middle_button: Button = get_node(middle_button_path) as Button
onready var right_button: Button = get_node(right_button_path) as Button

onready var v_scroll: VScrollBar = scroll_container.get_v_scrollbar()
onready var h_scroll: HScrollBar = scroll_container.get_h_scrollbar()

var chapter_id: String
var chapter_hash: String
var chapter_page_ids: Array

var current_page_index: int = 0

var mdah_server: String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	left_button.connect("pressed", self, "_on_left")
	middle_button.connect("pressed", self, "_on_middle")
	right_button.connect("pressed", self, "_on_right")
	
	var mdah_server_client = yield(main.client_pool.get_next_available_client(), "completed")
	mdah_server_client.get_mdah_server(chapter_id)

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_WHEEL_UP:
				scroll_container.scroll_vertical = clamp(scroll_container.scroll_vertical - 20.0, 0.0, v_scroll.max_value)
			BUTTON_WHEEL_DOWN:
				scroll_container.scroll_vertical = clamp(scroll_container.scroll_vertical + 20.0, 0.0, v_scroll.max_value)

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
			if image.load_png_from_buffer(response_body) != OK:
				print_debug("Unable to load manga page")
			
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
	# TODO stub
	pass

func _on_right() -> void:
	current_page_index += 1
	if current_page_index >= chapter_page_ids.size():
		current_page_index -= 1
		return
	var get_manga_page_client = yield(main.client_pool.get_next_available_client(), "completed")
	get_manga_page_client.get_manga_page(mdah_server, chapter_hash, chapter_page_ids[current_page_index])

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

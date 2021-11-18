tool
extends "res://addons/mangadex-gd/screens/base_screen.gd"

const SERVER_UNAVAILABLE := "Server unavailable"

export var username_input_path: NodePath
export var password_input_path: NodePath
export var remember_username_path: NodePath
export var remember_password_path: NodePath
export var login_button_path: NodePath

onready var _username_input: LineEdit = get_node(username_input_path)
onready var _password_input: LineEdit = get_node(password_input_path)
onready var _remember_username: CheckBox = get_node(remember_username_path)
onready var _remember_password: CheckBox = get_node(remember_password_path)
onready var _login_button: Button = get_node(login_button_path)

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	_login_button.connect("pressed", self, "_on_login_button_pressed")
	
	if OS.is_debug_build():
		var dev_login = find_node("DevLogin")
		dev_login.visible = true
		dev_login.connect("pressed", self, "_on_dev_login")
		find_node("DevToken").visible = true
	
	var http = yield(main.client_pool.get_next_available_client(), "completed")
	http.ping()

###############################################################################
# Connections                                                                 #
###############################################################################

func _handle_response(request_type: int, response_status: int, response_body) -> void:
	match request_type:
		main.RequestType.PING:
			if response_status != 200:
				_login_button.disabled
				_login_button.text = SERVER_UNAVAILABLE
		main.RequestType.LOGIN:
			if not response_body.has("token"):
				print_debug("Invalid response: %s" % JSON.print(response_body), true)
				return
			main.client_pool.token = response_body["token"]["session"]
			main.client_pool.refresh = response_body["token"]["refresh"]
			main.change_screen_to("res://addons/mangadex-gd/screens/home_screen.tscn")

func _on_login_button_pressed() -> void:
	if (not _username_input.text.empty() and not _password_input.text.empty()):
		var http = yield(main.client_pool.get_next_available_client(), "completed")
		http.login(_username_input.text, _password_input.text)

func _on_dev_login() -> void:
	main.client_pool.token = find_node("DevToken").text
	main.change_screen_to("res://addons/mangadex-gd/screens/home_screen.tscn")

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################



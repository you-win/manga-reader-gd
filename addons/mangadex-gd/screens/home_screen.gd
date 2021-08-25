tool
extends "res://addons/mangadex-gd/screens/base_screen.gd"

export var username_field_path: NodePath

onready var username_field: Label = get_node(username_field_path)

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	var http = yield(main.client_pool.get_next_available_client(), "completed")
	http.get_user_data()

###############################################################################
# Connections                                                                 #
###############################################################################

func _handle_response(request_type: int, response_status: int, response_body: Dictionary) -> void:
	match request_type:
		main.RequestType.USER_DATA:
			if response_body.empty():
				print_debug("User data response empty", true)
				return
			username_field.text = response_body["data"]["attributes"]["username"]

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################



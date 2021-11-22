tool
extends Node

signal response_received(request_type, response_code, response_body)

const MAX_CLIENTS: int = 10
const INITIAL_CLIENTS: int = 4

const MDR_HANDLER_PATH := "res://addons/manga-reader-gd/mdr_handler.gd"

var main: Node

var clients: Array = []

var token := ""
var refresh := ""

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	for i in INITIAL_CLIENTS:
		var client = load(MDR_HANDLER_PATH).new()
		client.main = main
		client.connect("ready_to_read", self, "_on_client_ready_to_read")
		add_child(client)
		
		clients.append(client)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_client_ready_to_read(request_type: int, response_code: int, response_body) -> void:
	emit_signal("response_received", request_type, response_code, response_body)

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func get_next_available_client() -> Node:
	# Reuse existing client
	for client in clients:
		if client.is_ready_for_new_request:
			print_debug("Getting existing client %s" % client.name)
			yield(get_tree(), "idle_frame")
			return client
	
	# Create a new client if necessary and possible
	if clients.size() < MAX_CLIENTS:
		print_debug("Creating new client")
		var mdr_handler = load(MDR_HANDLER_PATH).new()
		mdr_handler.main = main
		clients.append(mdr_handler)
		mdr_handler.connect("ready_to_ready", self, "_on_client_ready_to_read")
		add_child(mdr_handler)
		yield(get_tree(), "idle_frame")
		return mdr_handler
	
	# Wait until a client is free
	print_debug("Waiting for client to be available")
	yield(get_tree().create_timer(3.0), "timeout")
	return yield(get_next_available_client(), "completed")

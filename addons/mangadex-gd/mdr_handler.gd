tool
extends HTTPRequest

signal ready_to_read(request_type, response_code, response_body)

const BASE_URL := "https://api.mangadex.org/"

const VALID_RESPONSE_CODES: PoolIntArray = PoolIntArray([200, 201, 202, 203, 204])

const CONTENT_TYPE: String = "Content-Type: application/json"
const USER_AGENT: String = "User-Agent: MangaDexGD/1.0 (Godot 3.4)"
const ACCEPT_ALL: String = "Accept: */*"

const PONG := "pong"

var main: Node

var last_request_type: int = 0

var is_ready_for_new_request := true

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	connect("request_completed", self, "_on_request_completed")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_request_completed(_result: int, response_code: int, _headers: PoolStringArray,
		body: PoolByteArray) -> void:
	if not response_code in VALID_RESPONSE_CODES:
		print_debug("Response code %s is not a valid status code" % response_code, true)
		if not body.empty():
			print_debug("%s" % (body.get_string_from_utf8()))
		emit_signal("ready_to_read", last_request_type, response_code, {})
		return
	
	var parsed_body: Dictionary = {}
	if not body.empty():
		var body_string := body.get_string_from_utf8()
		if body_string == PONG:
			parsed_body["ping"] = body_string
		else:
			var parsed_json = parse_json(body_string)
			if not typeof(parsed_json) == TYPE_DICTIONARY:
				parsed_body["text"] = body_string
			else:
				parsed_body = parsed_json
	
	is_ready_for_new_request = true
	emit_signal("ready_to_read", last_request_type, response_code, parsed_body)

###############################################################################
# Private functions                                                           #
###############################################################################

func _check_error(err: int) -> void:
	if err != OK:
		print_debug("Failed to create request", true)

func _send_request(method: int, path: String, data: String = "",
		headers: PoolStringArray = PoolStringArray([CONTENT_TYPE, USER_AGENT, ACCEPT_ALL])) -> int:
	is_ready_for_new_request = false
	return request("%s%s" % [BASE_URL, path], headers, true, method, data)

func _construct_bearer_header() -> PoolStringArray:
	var bearer: String = "Authorization: Bearer %s" % get_parent().token
	return PoolStringArray([bearer, CONTENT_TYPE, USER_AGENT, ACCEPT_ALL])

###############################################################################
# Public functions                                                            #
###############################################################################

# Infrastructure

func ping() -> void:
	print_debug("Sending ping request")
	last_request_type = main.RequestType.PING
	
	var err: int = _send_request(HTTPClient.METHOD_GET, "ping")
	
	_check_error(err)

# Auth

func login(username: String, password: String) -> void:
	print_debug("Sending login request")
	last_request_type = main.RequestType.LOGIN
	
	var data: String = JSON.print({
		"username": username,
		"password": password
	})
	
	var err: int = _send_request(HTTPClient.METHOD_POST, "auth/login", data)
	
	_check_error(err)

# User

func get_user_data() -> void:
	print_debug("Getting user data")
	last_request_type = main.RequestType.USER_DATA
	
	var err: int = _send_request(HTTPClient.METHOD_GET, "user/me", "", _construct_bearer_header())

func get_user_feed(language: String, offset: int = 0) -> void:
	print_debug("Getting user feed for lang %s" % language)
	last_request_type = main.RequestType.USER_FEED
	
	var err: int = _send_request(HTTPClient.METHOD_GET,
		"user/follows/manga/feed?limit=10&locales[]=%s&offset=%s" % [language, offset], "",
		_construct_bearer_header())
	
	_check_error(err)

# Manga

func get_user_followed_manga(offset: int, limit: int) -> void:
	print_debug("Getting user followed manga")
	last_request_type = main.RequestType.USER_FOLLOWED_MANGA
	
	var err: int = _send_request(HTTPClient.METHOD_GET,
		"user/follows/manga?offset=%s&limit=%s" % [offset, limit], "", _construct_bearer_header())
	
	_check_error(err)

func get_manga(manga_id: String) -> void:
	print_debug("Getting manga for id %s" % manga_id)
	last_request_type = main.RequestType.GET_MANGA
	
	var err: int = _send_request(HTTPClient.METHOD_GET, "manga/%s" % manga_id, "",
			_construct_bearer_header())
	
	_check_error(err)

func get_chapter(chapter_id: String) -> void:
	print_debug("Getting chapter for id %s" % chapter_id)
	last_request_type = main.RequestType.GET_CHAPTER
	
	var err: int = _send_request(HTTPClient.METHOD_GET, "chapter/%s" % chapter_id, "",
			_construct_bearer_header())
	
	_check_error(err)

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
var last_request_uri: String = ""

var force_new_request: bool = false

var is_ready_for_new_request := true

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	connect("request_completed", self, "_on_request_completed")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_request_completed(_result: int, response_code: int, headers: PoolStringArray,
		body, was_cached: bool = false) -> void:
	if not response_code in VALID_RESPONSE_CODES:
		print_debug("Response code %s is not a valid status code" % response_code, true)
		if not body.empty():
			print_debug("%s" % (body.get_string_from_utf8()))
		emit_signal("ready_to_read", last_request_type, response_code, {})
		return

	var parsed_body

	if not was_cached:
		if not body.empty():
			if not last_request_type in [main.RequestType.GET_MANGA_PAGE, main.RequestType.PING]:
				parsed_body = {}
				var body_string = body.get_string_from_utf8()
				if body_string == PONG:
					parsed_body["ping"] = body_string
				else:
					var parsed_json = parse_json(body_string)
					if not typeof(parsed_json) == TYPE_DICTIONARY:
						parsed_body["text"] = body_string
					else:
						parsed_body = parsed_json
				
				main.request_lfu.add(last_request_uri, parsed_body)
			else:
				parsed_body = body
				main.image_lfu.add(last_request_uri, parsed_body)
		else:
			parsed_body = {}
	else:
		parsed_body = body
	
	is_ready_for_new_request = true
	force_new_request = false
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

	last_request_uri = "%s%s" % [BASE_URL, path]

	if (method != HTTPClient.METHOD_POST and last_request_type != main.RequestType.PING and not force_new_request):
		var cached_result = main.request_lfu.find(last_request_uri)
		if cached_result:
			emit_signal("request_completed", OK, 200, [], cached_result, true)
			return OK

	return request(last_request_uri, headers, true, method, data)

func _construct_bearer_header() -> PoolStringArray:
	var bearer: String = "Authorization: Bearer %s" % get_parent().token
	return PoolStringArray([bearer, CONTENT_TYPE, USER_AGENT, ACCEPT_ALL])

func _find_content_type_header_value(headers: PoolStringArray) -> String:
	var result: String = ""
	print_debug(headers)
	for header in headers:
		var split_header: PoolStringArray = header.split(" ")
		print_debug(split_header[1])
		if split_header[0] == "Content-Type:":
			return split_header[split_header.size() - 1]

	return result

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
		"user/follows/manga/feed?limit=32&offset=%s&translatedLanguage[]=%s&includes[]=user&includes[]=scanlation_group&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&order[createdAt]=desc" % [offset, language],
		"",
		_construct_bearer_header()
	)
	
	_check_error(err)

# Manga

func get_user_followed_manga(offset: int, limit: int) -> void:
	print_debug("Getting user followed manga")
	last_request_type = main.RequestType.USER_FOLLOWED_MANGA
	
	var err: int = _send_request(HTTPClient.METHOD_GET,
		"user/follows/manga?offset=%s&limit=%s" % [offset, limit], "", _construct_bearer_header())
	
	_check_error(err)

func get_manga(ids: Array) -> void:
	print_debug("Getting manga ids")
	last_request_type = main.RequestType.GET_MANGA

	if ids.empty():
		print_debug("ids array is empty, cannot get manga")
		return
	var ids_copy: Array = ids.duplicate()
	var query_param: String = "limit=100&ids[]="
	var params: String = "%s%s" % [query_param, ids_copy.pop_back()]
	for id_idx in ids_copy.size():
		params = "%s&%s%s" % [params, query_param, ids_copy.pop_back()]

	var err: int = _send_request(HTTPClient.METHOD_GET, "manga?%s" % params, "", _construct_bearer_header())

	_check_error(err)

func search_manga(title: String) -> void:
	print_debug("Searching for manga title")
	last_request_type = main.RequestType.SEARCH_MANGA

	if title.empty():
		print_debug("Title is empty, cannot search")
		return

	var err: int = _send_request(HTTPClient.METHOD_GET, "manga?title=%s" % title, "", _construct_bearer_header())

	_check_error(err)

func view_manga(manga_id: String) -> void:
	print_debug("Getting manga for id %s" % manga_id)
	last_request_type = main.RequestType.VIEW_MANGA
	
	var err: int = _send_request(HTTPClient.METHOD_GET, "manga/%s" % manga_id, "",
			_construct_bearer_header())
	
	_check_error(err)

func get_manga_volumes_and_chapters(manga_id: String) -> void:
	print_debug("Getting manga chapters for id %s" % manga_id)
	last_request_type = main.RequestType.GET_MANGA_VOLUMES_AND_CHAPTERS

	var err: int = _send_request(HTTPClient.METHOD_GET, "manga/%s/aggregate" % manga_id, "",
			_construct_bearer_header())

	_check_error(err)

# Chapter

func get_chapter(chapter_id: String) -> void:
	print_debug("Getting chapter for id %s" % chapter_id)
	last_request_type = main.RequestType.GET_CHAPTER
	
	var err: int = _send_request(HTTPClient.METHOD_GET, "chapter/%s" % chapter_id, "",
			_construct_bearer_header())
	
	_check_error(err)

# MDaH

func get_mdah_server(chapter_id: String) -> void:
	print_debug("Getting MDaH server %s" % chapter_id)
	last_request_type = main.RequestType.GET_MDAH_SERVER

	var err: int = _send_request(HTTPClient.METHOD_GET, "at-home/server/%s" % chapter_id,
		"", _construct_bearer_header())

	_check_error(err)

# Get manga page

func get_manga_page(mdah_server: String, chapter_hash: String, chapter_page_id: String) -> void:
	print_debug("Getting page from mdah server %s" % chapter_page_id)
	last_request_type = main.RequestType.GET_MANGA_PAGE
	
	is_ready_for_new_request = false
	
	var headers: PoolStringArray = _construct_bearer_header()
	headers.append("Accept-Encoding: gzip, deflate, br")
	headers.append("Connection: keep-alive")
	# headers.append("Host: %s:444" % mdah_server)

	last_request_uri = chapter_page_id

	if not force_new_request:
		print_debug("Looking for image in lfu")
		var cached_result = main.image_lfu.find(chapter_page_id)
		if cached_result:
			print_debug("Found image in lfu")
			emit_signal("request_completed", OK, 200, [], cached_result, true)
			return
	
	var err: int = request(
		"%s%s" % [mdah_server, "/data/%s/%s" % [chapter_hash, chapter_page_id]],
		headers,
		true,
		HTTPClient.METHOD_GET,
		""
	)

	_check_error(err)

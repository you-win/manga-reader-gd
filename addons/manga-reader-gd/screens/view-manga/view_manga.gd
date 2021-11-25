tool
extends "res://addons/manga-reader-gd/screens/base_screen.gd"

var manga_data: Dictionary

export var title_label_path: NodePath
export var alt_title_label_path: NodePath
export var description_label_path: NodePath
export var tags_label_path: NodePath

onready var title_label: Label = get_node(title_label_path) as Label
onready var alt_title_label: Label = get_node(alt_title_label_path) as Label
onready var description_label: Label = get_node(description_label_path) as Label
onready var tags_label: Label = get_node(tags_label_path) as Label

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	var manga_id: String = manga_data["id"]
	var client = yield(main.client_pool.get_next_available_client(), "completed")
	client.view_manga(manga_id)

	var client1 = yield(main.client_pool.get_next_available_client(), "completed")
	client1.view_manga(manga_id)

###############################################################################
# Connections                                                                 #
###############################################################################

func _handle_response(request_type: int, response_status: int, response_body) -> void:
	match request_type:
		main.RequestType.VIEW_MANGA:
			var data: Dictionary = response_body["data"]["attributes"]
			
			title_label.text = data["title"]["en"] # TODO hardcoded to en
			
			var alt_titles: Array = data.get("altTitles")
			if (alt_titles and alt_titles.size() > 0):
				alt_titles.invert()
				var alt_title: Dictionary = alt_titles.pop_back()
				alt_title_label.text = alt_title[alt_title.keys()[0]] # TODO this might be a bad idea
				for t in alt_titles:
					alt_title = alt_titles.pop_back()
					alt_title_label.text += ", %s" % alt_title[alt_title.keys()[0]] # TODO this might be a bad idea
			
			description_label.text = data["description"]["en"] # TODO hardcoded to en
			
			var tags: Array = data.get("tags")
			if (tags and tags.size() > 0):
				tags.invert()
				var tag: Dictionary = tags.pop_back()["attributes"]["name"]
				tags_label.text = tag[tag.keys()[0]] # TODO this might be a bad idea
				for t in tags:
					tag = tags.pop_back()["attributes"]["name"]
					tags_label.text = tag[tag.keys()[0]] # TODO this might be a bad idea
		main.RequestType.GET_MANGA_VOLUMES_AND_CHAPTERS:
			pass

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

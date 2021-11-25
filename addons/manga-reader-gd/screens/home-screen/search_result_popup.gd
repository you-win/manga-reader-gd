extends WindowDialog

var buttons: Array = []

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	connect("popup_hide", self, "_on_popup_hide")

	var vbox: VBoxContainer = $MarginContainer/VBoxContainer
	for button in buttons:
		vbox.call_deferred("add_child", button)

	popup_centered_ratio(0.75)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_popup_hide() -> void:
	queue_free()

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
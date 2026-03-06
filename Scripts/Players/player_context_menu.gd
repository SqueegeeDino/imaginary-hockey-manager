extends PanelContainer
class_name PlayerContextMenu

signal add_to_team(player: PlayerProfile)
signal remove_from_team(player: PlayerProfile)
signal show_more_info(player: PlayerProfile)
signal menu_closed

var player: PlayerProfile = null

@onready var label_name: Label = %lbl_Name
@onready var button_add_to_team: Button = %btn_Add
@onready var button_remove_from_team: Button = %btn_Remove
@onready var button_show_more_info: Button = %btn_Info

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	button_add_to_team.pressed.connect(_on_add_to_team_pressed)
	button_remove_from_team.pressed.connect(_on_remove_from_team_pressed)
	button_show_more_info.pressed.connect(_on_show_more_info_pressed)

func setup(p: PlayerProfile) -> void:
	player = p
	label_name.text = p.display_name

func _on_add_to_team_pressed() -> void:
	if player != null:
		add_to_team.emit(player)
	queue_free()

func _on_remove_from_team_pressed() -> void:
	if player != null:
		remove_from_team.emit(player)
	queue_free()

func _on_show_more_info_pressed() -> void:
	if player != null:
		show_more_info.emit(player)
	queue_free()

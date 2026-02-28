# res://Scenes/PlayerRow.gd
class_name PlayerRow
extends Button

signal hovered(player: PlayerProfile)
signal exited(player: PlayerProfile)
signal clicked(player: PlayerProfile)

@export var star_empty: Texture2D
@export var star_half: Texture2D
@export var star_full: Texture2D

@onready var label_name: Label = $HBoxContainer/_playerLabel_name
@onready var stars := [
	$HBoxContainer/starContainer/icon_star1,
	$HBoxContainer/starContainer/icon_star2,
	$HBoxContainer/starContainer/icon_star3,
	$HBoxContainer/starContainer/icon_star4,
	$HBoxContainer/starContainer/icon_star5
]


var player: PlayerProfile

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func():
		if player != null:
			hovered.emit(player)
			print("Hovering")
	)
	mouse_exited.connect(func():
		if player != null:
			exited.emit(player)
			print("Exited hover")
	)
	
func set_player(p: PlayerProfile, star_units: int) -> void:
	if label_name == null:
		push_error("PlayerRow: label_name is null. Check node path/case.")
		return
	player = p
	label_name.text = p.display_name
	_set_stars(star_units)
	label_name.text = p.display_name

func _set_stars(star_units: int) -> void:
	# Clamp to valid range (0–10)
	var units: int = clamp(star_units, 0, 10)

	for i in range(5):
		var star_value: int = units - (i * 2)

		if star_value >= 2:
			stars[i].texture = star_full
		elif star_value == 1:
			stars[i].texture = star_half
		else:
			stars[i].texture = star_empty
	# Clamp to valid range (0–10)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(player)

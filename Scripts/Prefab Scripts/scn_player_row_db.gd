class_name PlayerRowDB
extends Button

@export var star_empty: Texture2D
@export var star_half: Texture2D
@export var star_full: Texture2D

@onready var label_name: Label = $HBoxContainer/_playerLabel_name
@onready var stars := [
	$HBoxContainer/MarginContainer/starContainer/icon_star1,
	$HBoxContainer/MarginContainer/starContainer/icon_star2,
	$HBoxContainer/MarginContainer/starContainer/icon_star3,
	$HBoxContainer/MarginContainer/starContainer/icon_star4,
	$HBoxContainer/MarginContainer/starContainer/icon_star5
]

var player: PlayerProfile = null

func _init() -> void:
	pass

func awake(p: PlayerProfile) -> void:
	player = p

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

func _ready():
	if player != null: # Only run this if a PlayerProfile has been passed through
		label_name.text = player.display_name
		_set_stars(player.starRating)
	else:
		print("Null PlayerProfile @ scn_player_row_db.gd: _ready():")
		print("Are you in the right scene?")
	mouse_filter = Control.MOUSE_FILTER_STOP

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
	print("Passed ID: ", player.id )


func _ready():
	if player != null:
		label_name.text = player.display_name
	else:
		print("Null PlayerProfile @ scn_player_row_db.gd: _ready():")
		print("Are you in the right scene?")
	pass

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
var player_id: int
var player_name: String
func _init() -> void:
	pass

func awake(playerID, playerName) -> void:
	print("Passed ID: ", playerID)
	player_id = playerID
	player_name = playerName


func _ready():
	label_name.text = player_name

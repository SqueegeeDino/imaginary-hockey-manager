# res://scripts/players/player_profile.gd
class_name PlayerProfile
extends RefCounted

var id: int
var display_name: String

var intelligence: int
var physical: int
var defense: int
var offense: int

func _init(_id: int, _name: String, i: int, p: int, d: int, o: int) -> void:
	id = _id
	display_name = _name
	intelligence = i
	physical = p
	defense = d
	offense = o

func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"intelligence": intelligence,
		"physical": physical,
		"defense": defense,
		"offense": offense,
	}

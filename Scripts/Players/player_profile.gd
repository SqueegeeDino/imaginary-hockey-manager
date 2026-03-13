# res://scripts/players/player_profile.gd
class_name PlayerProfile
extends RefCounted

var id: int
var display_name: String

var intelligence: int
var physical: int
var defense: int
var offense: int
var starRating: int
var overall: float

var role: int
var bestPos: int
	

func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"intelligence": intelligence,
		"physical": physical,
		"defense": defense,
		"offense": offense,
		"role": role,
		"best position": bestPos,
		"star_rating": starRating,
		"overall_rating": overall
	}

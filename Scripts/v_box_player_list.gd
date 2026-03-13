extends VBoxContainer

# Runtime modifiable variables
@onready var sortOrder: String = "DESC"
@onready var sortType: String = "player_id"

func _on_sort_pressed(type: String, order: String) -> void:
	sortType = type
	sortOrder = order
	scrollBox = 

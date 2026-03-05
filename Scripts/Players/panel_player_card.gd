extends PanelContainer

signal card_hovered
signal card_unhovered

@onready var window_size: Vector2i = get_window().size # Get the window size when the node wakes up
@onready var panel_size: int = size.y # Get the panel size
@onready var clamp_max: int = window_size.y - (panel_size + 10) # Set the max clamping dimensions by simply subtracting the panel size plus a buffer range, from the window size

var _mouse_over_card: bool = false

func _ready():
	set_process_input(true) # Allow the node to read input events (moving the mouse)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
		
func _on_mouse_entered() -> void:
	_mouse_over_card = true
	card_hovered.emit()

func _on_mouse_exited() -> void:
	_mouse_over_card = false
	card_unhovered.emit()
	
func _input(event):
	if _mouse_over_card: # If mouse is currently hovering on the card, don't move it around
		return
	# When the mouse moves, move the UI element up and down
	if event is InputEventMouseMotion:
		var new_position: float = event.position.y - 50
		position.y = clamp(new_position, 10, clamp_max)

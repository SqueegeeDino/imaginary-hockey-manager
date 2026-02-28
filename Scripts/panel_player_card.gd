extends PanelContainer

@onready var window_size: Vector2i = get_window().size # Get the window size when the node wakes up
@onready var panel_size: int = size.y # Get the panel size
@onready var clamp_max: int = window_size.y - (panel_size + 10) # Set the max clamping dimensions by simply subtracting the panel size plus a buffer range, from the window size

func _ready():
	set_process_input(true) # Allow the node to read input events (moving the mouse)

func _input(event):
	# When the mouse moves, move the UI element up and down
	if event is InputEventMouseMotion:
		var new_position: float = event.position.y
		position.y = clamp(new_position, 10, clamp_max)

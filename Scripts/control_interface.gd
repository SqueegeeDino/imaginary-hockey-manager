extends Control

var database = SQLite

# Export variables
@export var scrollBox: VBoxContainer
@export var playerRow: PackedScene

# Runtime modifiable variables
@onready var sortOrder: String = "DESC"
@onready var sortType: String = "player_id"

func _ready() -> void:
	database = SQLite.new()
	database.path = "res://data.db"
	database.open_db()
	generate_list()

## Local Functions
# Instantiate function
func _instantiate_playerRow(player: PlayerProfile) -> void:
	var row = playerRow.instantiate() # Spawn the row, set it as a local variable
	row.awake(player) # Run the CUSTOM awake function that will apply the player ID to this item
	scrollBox.add_child(row) # Add this row as a child of the scrollcontainer VBox

## Primary Functions
# Main Interface
# Spawn list of existing values in database
func generate_list() -> void:
	# Wipe the list
	for child in scrollBox.get_children():
		child.queue_free()
	
	database.query("SELECT * FROM players ORDER BY " + sortType)
	# This works because the database.query() function returns an array of dictionaries.
	# We iterate through each individual dictionary, then snag the desired values using their keys
	# Keys are the headers of the columns
	if database.query_result.size() == 0:
		print("Empty database")
		return
	for i in database.query_result:
		var player := PlayerProfile.new()
		player.id = i["player_id"]
		player.display_name = i["name"]
		player.overall = i["overall"]
		player.starRating = i["stars"]
		# Instantiate the row with the passed through info saved internally
		_instantiate_playerRow(player)

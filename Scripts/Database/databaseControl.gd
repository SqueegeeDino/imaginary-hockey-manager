extends Control

var database: SQLite
var generator:= PlayerGenerator.new()
var rng := RandomNumberGenerator.new()
var playerRow: PackedScene = preload("res://Scenes/scn_playerRow_db.tscn")

@onready var ui_nameLine = $PanelContainer/HBoxContainer/GridContainer2/name
@onready var ui_ageLine = $PanelContainer/HBoxContainer/GridContainer2/age
@onready var ui_sortAsc = $PanelContainer/HBoxContainer/GridContainer3/check_sortAsc
@onready var ui_position = $PanelContainer/HBoxContainer/GridContainer2/position
@onready var scrollBox = $VBox_playerList/panel_playerList/MarginContainer/ScrollContainer/VBoxContainer

# Runtime modifiable variables
@onready var sortOrder: String = "ASC"
@onready var sortType: String = "player_id"

class GeneratorConfig:
	var stat_min: int = 1
	var stat_max: int = 99
	var base_mean: float = 0.55
	var spread: float = 0.4
	var bias: float = 0.
	
	# Typed dictionary values (still Variant at runtime, so we cast when reading)
	var mean_offsets: Dictionary = {
		"intelligence": 0.0,
		"physical": 0.0,
		"defense": 0.0,
		"offense": 0.0,
	}

var statType_array: Array[String] = [
	"Intelligence",
	"Physical",
	"Offense",
	"Defense",
]

func _ready():
	database = SQLite.new()
	database.path = "res://data.db"
	database.open_db()
	_generate_list()

## Helpers
# Ascendin and descending helper

func _asc_desc() -> void:
	if sortOrder == "ASC":
		sortOrder = "DESC"
	else:
		sortOrder = "ASC"

func _change_sort_type(sortType) -> void:
	sortType

# Stat value randomization
# Clamp from 0 to 1
func _clamp01(x: float) -> float:
	return clamp(x, 0.0, 1.0)

func _rand_normal() -> float:
	var u1: float = max(rng.randf(), 0.000001)
	var u2: float = rng.randf()
	return sqrt(-2.0 * log(u1)) * cos(TAU * u2)

func _get_offset(cfg: GeneratorConfig, stat_key: String) -> float:
	# Avoid type inference from Variant: explicitly handle missing keys and cast
	if cfg.mean_offsets.has(stat_key):
		return float(cfg.mean_offsets[stat_key])
	return 0.0

func _sample_stat(cfg: GeneratorConfig, stat_key: String) -> int:
	var r: float = float(cfg.stat_max - cfg.stat_min)

	# Explicit types prevent "cannot infer type" errors
	var mean: float = cfg.base_mean + _get_offset(cfg, stat_key)
	mean = _clamp01(mean)

	mean = _clamp01(mean + cfg.bias * 0.25)

	var x: float = mean + _rand_normal() * cfg.spread
	x = _clamp01(x)

	return int(round(cfg.stat_min + x * r))
# Takes the overall float value, and returns a "Stars" value, as an int of 1-10
func _stars_from_overall(overall: float) -> int:
	# Map 1..99-ish into 1..5 stars.
	# Tweak thresholds freely.
	if overall >= 95: return 10
	if overall >= 90: return 9
	if overall >= 80: return 8
	if overall >= 70: return 7
	if overall >= 60: return 6
	if overall >= 50: return 5
	if overall >= 40: return 4
	if overall >= 30: return 3
	if overall >= 20: return 2
	return 1
# Takes stats as an array, then outputs a single value as their overall
func _average_array(data: Array) -> float:
	if data.is_empty(): # Protection against crashing on empty array input
		printerr("_average_array: Your input data is empty, did you mean that?")
		return 0.0
	var sum: float = 0.0
	for value in data:
		sum += float(value)
	return sum / data.size()
## Main Internal Functions
func _on_btn_create_table_pressed() -> void:
	var table = {
		"player_id" : {"data_type":"int", "primary_key": true, "not_null": true, "auto_increment": true},
		"name" : {"data_type":"text"},
		"age" : {"data_type":"int"},
		"position" : {"data_type":"int"},
		"physical" : {"data_type":"real"},
		"intelligence" : {"data_type":"real"},
		"offense" : {"data_type":"real"},
		"defense" : {"data_type":"real"},
		"overall" : {"data_type":"real"},
	}

	database.create_table("players", table)
	print("Table created")

func _on_btn_insert_data_pressed() -> void:
	var data = {
		"name" : ui_nameLine.text,
		"age" : int(ui_ageLine.text),
		"position" : ui_position.selected  + 1
	}
	
	database.insert_row("players", data)

func _on_btn_select_data_pressed() -> void:
	print(database.select_rows("players", "player_id > 0", ["*"]))

func _on_btn_update_data_pressed() -> void:
	database.update_rows("players", "name = '" + ui_nameLine.text + "'", {"age": int(ui_ageLine.text)})
	pass # Replace with function body.

func _on_btn_delete_data_pressed() -> void:
	database.delete_rows("players", "id > 0")

func _on_btn_custom_select_pressed() -> void: # Join two tables together, and print their data
	database.query("select * from players
	LEFT OUTER JOIN playerPosition on playerPosition.id = players.position
	where age > " + ui_ageLine.text)
	for i in database.query_result:
		print("-------------------------------")
		print(i)

func _on_btn_sort_ages_pressed() -> void:
	database.query("select age, name from players ORDER BY age " + sortOrder)
	for i in database.query_result:
		print(i)

func _on_btn_insert_random_pressed(cfg: GeneratorConfig = GeneratorConfig.new()) -> void:
	var player_name: String = generator._pick_player_name(1) # Will be changable to allow for name variance
	var a: int = rng.randi_range(18,42)
	var pos: int = rng.randi_range(1,5)
	
	var _xMin: float = 1
	var _xMax: float = 10
	
	# Basic skater stats
	var i: int = _sample_stat(cfg, "intelligence")
	var p: int = _sample_stat(cfg, "physical")
	var d: int = _sample_stat(cfg, "defense")
	var o: int = _sample_stat(cfg, "offense")
	
	var skillArray: Array[float] = [i,p,d,o]
	
	var ovr := _average_array(skillArray) # Get the overall (average) value
	var stars := _stars_from_overall(ovr)

	var data = {
		"name" : player_name,
		"age" : a,
		"position" : pos,
		"intelligence" : i,
		"physical" : p,
		"offense" : o,
		"defense" : d,
		"overall" : ovr,
		"stars" : stars,
	}
	
	database.insert_row("players", data)
	_generate_list()

## Interface Specific Functions (make rows, move items, show UI, etc.)
# Interface helpers
# Instantiate function
func _instantiate_playerRow(player: PlayerProfile) -> void:
	var row = playerRow.instantiate() # Spawn the row, set it as a local variable
	row.awake(player) # Run the CUSTOM awake function that will apply the player ID to this item
	scrollBox.add_child(row) # Add this row as a child of the scrollcontainer VBox

# Main Interface
# Spawn list of existing values in database
func _generate_list() -> void:
	# Wipe the list
	for child in scrollBox.get_children():
		child.queue_free()
	
	database.query("SELECT * FROM players ORDER BY " + sortType + sortOrder)
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
		_instantiate_playerRow(player) #!Remember to update _instantiate_playerRow if you add new parameters to pass through!

extends Control

var database: SQLite

@onready var ui_nameLine = $PanelContainer/HBoxContainer/GridContainer2/name
@onready var ui_scoreLine = $PanelContainer/HBoxContainer/GridContainer2/score
@onready var ui_sortAsc = $PanelContainer/HBoxContainer/GridContainer/check_sortAsc
@onready var ui_position = $PanelContainer/HBoxContainer/GridContainer2/position

func _ready():
	database = SQLite.new()
	database.path = "res://data.db"
	database.open_db()

## Helpers
# Ascendin and descending helper
@onready var asc_desc = "ASC"
func _asc_desc(cntrl) -> String:
	if cntrl.button_pressed == true:
		var asc_desc = "DESC"
		return asc_desc
	else:
		var asc_desc = "ASC"
		return asc_desc

	
func _on_btn_create_table_pressed() -> void:
	var table = {
		"id" : {"data_type":"int", "primary_key": true, "not_null": true, "auto_increment": true},
		"name" : {"data_type":"text"},
		"score" : {"data_type":"int"}
	}
	database.create_table("players", table)
	print("Table created")

func _on_btn_insert_data_pressed() -> void:
	print("Score: ", int(ui_scoreLine.text))
	var data = {
		"name" : ui_nameLine.text,
		"score" : int(ui_scoreLine.text)
	}
	
	database.insert_row("players", data)

func _on_btn_select_data_pressed() -> void:
	print(database.select_rows("players", "id > 0", ["*"]))

func _on_btn_update_data_pressed() -> void:
	database.update_rows("players", "name = '" + ui_nameLine.text + "'", {"score": int(ui_scoreLine.text)})
	pass # Replace with function body.

func _on_btn_delete_data_pressed() -> void:
	database.delete_rows("players", "id > 0")

func _on_btn_custom_select_pressed() -> void: # Join two tables together, and print their data
	database.query("select * from players
JOIN playerInfo on playerInfo.id = players.playerInfoID
where score > " + ui_scoreLine.text)
	for i in database.query_result:
		print(i)

func _on_btn_sort_scores_pressed() -> void:
	database.query("select score, name from players ORDER BY score " + _asc_desc(ui_sortAsc))
	for i in database.query_result:
		print(i)

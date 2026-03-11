extends Control

var database: SQLite

@onready var nameLine = $PanelContainer/HBoxContainer/GridContainer2/name
@onready var scoreLine = $PanelContainer/HBoxContainer/GridContainer2/score

func _ready():
	database = SQLite.new()
	database.path = "res://data.db"
	database.open_db()

func _on_btn_create_table_pressed() -> void:
	var table = {
		"id" : {"data_type":"int", "primary_key": true, "not_null": true, "auto_increment": true},
		"name" : {"data_type":"text"},
		"score" : {"data_type":"int"}
	}
	database.create_table("players", table)
	print("Table created")

func _on_btn_insert_data_pressed() -> void:
	print("Score: ", int(scoreLine.text))
	var data = {
		"name" : nameLine.text,
		"score" : int(scoreLine.text)
	}
	
	database.insert_row("players", data)

func _on_btn_select_data_pressed() -> void:
	print(database.select_rows("players", "id > 0", ["*"]))

func _on_btn_update_data_pressed() -> void:
	database.update_rows("players", "name = '" + nameLine.text + "'", {"score": int(scoreLine.text)})
	pass # Replace with function body.

func _on_btn_delete_data_pressed() -> void:
	database.delete_rows("players", "id > 0")

func _on_btn_custom_select_pressed() -> void: # Join two tables together, and print their data
	database.query("select * from players
JOIN playerInfo on playerInfo.id = players.playerInfoID
where score > " + scoreLine.text)
	for i in database.query_result:
		print(i)

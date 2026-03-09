extends Control

var database: SQLite

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
	
	print("Score: ", int($PanelContainer/HBoxContainer/GridContainer2/score.text))
	var data = {
		"name" : $PanelContainer/HBoxContainer/GridContainer2/name.text,
		"score" : int($PanelContainer/HBoxContainer/GridContainer2/score.text)
	}
	
	database.insert_row("players", data)


func _on_btn_select_data_pressed() -> void:
	pass # Replace with function body.


func _on_btn_update_data_pressed() -> void:
	pass # Replace with function body.


func _on_btn_delete_data_pressed() -> void:
	pass # Replace with function body.


func _on_btn_custom_select_pressed() -> void:
	pass # Replace with function body.

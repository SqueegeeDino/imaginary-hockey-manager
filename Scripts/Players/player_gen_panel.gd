extends Control
class_name PlayerGen

# Public (editor) parameters
@export var hideTimer: Timer # Timer for delaying before hiding UI items
@export var nameType: OptionButton
@export var skaterQuality: OptionButton
@export var qualityVariance: HSlider
## Archetype controls
# Archetype UI elements
@export var useArchetypes: CheckButton
@export var archetype1: LineEdit
@export var archetype2: LineEdit
@export var archetype3: LineEdit
@export var radarGraph: RadarGraph
@export var radarTeam: RadarGraph
const RadarGraph = preload("res://addons/godot_radar_graph/radar_graph.gd") # Preload the radar
# Archetype settings
@export var archetype1Settings: Vector3
@export var archetype2Settings: Vector3
@export var archetype3Settings: Vector3
# Other elements
@export var label_points: Label
@onready var points: int = 100
@export var label_playerCount: Label
@onready var playerCount: int = 0
# Player row scene prefab
@export var player_row_scene: PackedScene  # assign PlayerRow.tscn in inspector
@export var player_context_menu: PackedScene # Context menu prefab
# Drag these in via the Inspector OR use the NodePath version below.
@onready var player_list_vbox: VBoxContainer = %vBox_playerList
@onready var selected_vbox: VBoxContainer = %vBox_playerList2
@onready var playerCard: PanelContainer = %panel_playerCard
@onready var label_int: Label = %cardLabel_int
@onready var label_phys: Label = %cardLabel_phys
@onready var label_def: Label = %cardLabel_def
@onready var label_off: Label = %cardLabel_off
@onready var label_name: Label = %cardLabel_name
@onready var label_role: Label = %cardLabel_role
@onready var label_pos: Label = %cardLabel_position

var rng := RandomNumberGenerator.new()
var generator := PlayerGenerator.new()
var last_player: PlayerProfile = null
var next_id: int = 1

var players_cache: Array[PlayerProfile] = []

var bias: float = 0

func _ready() -> void:
	rng.randomize()
	
	# Hide player card at start, connect to timer
	playerCard.visible = false
	hideTimer.timeout.connect(_on_hideTimer_timeout)
	# Panel stickiness
	playerCard.card_hovered.connect(_on_card_hovered)
	playerCard.card_unhovered.connect(_on_card_unhovered)

func _make_cfg(bias: float, mean: float, spread: float) -> PlayerGenerator.GeneratorConfig:
	var cfg := PlayerGenerator.GeneratorConfig.new()
	cfg.stat_min = 1
	cfg.stat_max = 99
	cfg.base_mean = mean
	cfg.spread = spread
	cfg.bias = bias
	return cfg

func _update_player_card(p: PlayerProfile) -> void:
	label_name.text = p.display_name
	label_int.text = str(p.intelligence)
	label_phys.text = str(p.physical)
	label_def.text = str(p.defense)
	label_off.text = str(p.offense)

func overall_from_player(p: PlayerProfile) -> float:
	# simple average of the 4 stats
	return (p.intelligence + p.physical + p.defense + p.offense) / 4.0

func stars_from_overall(overall: float) -> int:
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

func _clear_player_list() -> void:
	for child in player_list_vbox.get_children():
		child.queue_free()

func average_array(data: Array) -> float:
	if data.is_empty():
		return 0.0
	var sum: float = 0.0
	for value in data:
		sum += float(value)
	return sum / data.size()

func _list_stat_average(list: Node, stat: String) -> float:
	var player_array: Array = []
	var stat_array: Array = []
	var row_array: Array = list.get_children(false)
	# Take the array of player_row items and punch out all their player_profile items into a different array
	for r in row_array:
		var p = r.player
		player_array.append(p)
	# Take the array of player_profile items generated above, and punch out all their values of the desired stat
	for i in player_array:
		var s = i.get(stat)
		stat_array.append(s)
	return average_array(stat_array)

func _on_average_call():
	print("Intelligence: ",_list_stat_average(selected_vbox, "intelligence"))
	var avg_i: float = _list_stat_average(selected_vbox, "intelligence")
	print("Physical: ",_list_stat_average(selected_vbox, "physical"))
	var avg_p: float = _list_stat_average(selected_vbox, "physical")
	print("Offense: ",_list_stat_average(selected_vbox, "offense"))
	var avg_o: float = _list_stat_average(selected_vbox, "offense")
	print("Defense: ",_list_stat_average(selected_vbox, "defense"))
	var avg_d: float = _list_stat_average(selected_vbox, "defense")
	return {"avg_int":avg_i, "avg_phy":avg_p, "avg_off":avg_o, "avg_def":avg_d}
	
## List generation button signal
func _on_generate_list_pressed(
	isClear: bool,
	) -> void:
	var sT = useArchetypes.button_pressed # Check for superType check button
	var nT = nameType.get_index() # Get nameType dropdown index value
	# Execute correct function based on check button
	if sT:
		if isClear:
			_clear_player_list()
		isClear = false # This makes sure each iteration doesn't wipe the previous archetype
		var qB1 = archetype1Settings.x
		var qM1 = archetype1Settings.y
		var sV1 = archetype1Settings.z
		var qtyArc1 = archetype1.text
		_on_generate_list_superType(isClear, qtyArc1, nT, qB1, qM1, sV1)
		var qB2 = archetype2Settings.x
		var qM2 = archetype2Settings.y
		var sV2 = archetype2Settings.z
		var qtyArc2 = archetype2.text
		_on_generate_list_superType(isClear, qtyArc2, nT, qB2, qM2, sV2)
		var qB3 = archetype3Settings.x
		var qM3 = archetype3Settings.y
		var sV3 = archetype3Settings.z
		var qtyArc3 = archetype3.text
		_on_generate_list_superType(isClear, qtyArc3, nT, qB3, qM3, sV3)
	else:
		print("No supertypes")
		_on_generate_list_(isClear)

## Generic list generator
# Currently relies on dropdowns and slider to control certain values. 
#Debugging only, probably will be deprecated
func _on_generate_list_(isClear: bool) -> void:
	var nT = nameType.get_selected_id()
	var q = skaterQuality.get_selected_id()
	# Variance controls individual player stat variance
	# Low variance means all their stats will be similar values, while high variance allows for a greater range
	var qV = qualityVariance.value
	
	# Set player quality bias based on the option menu index
	if q == 1:
		bias = 0.9
	elif q == 2:
		bias = -0.9
	else:
		bias = 0.0
	
	print("Name Type:", nT)
	print("Bias Index:", q)
	print("Bias:", bias)
	print("Skill Variance: ", qV)
	
	# 1) generate batch
	var cfg := _make_cfg(bias, 0.55, qV) # your existing config maker
	var count := 500

	# name_index 0 female full, 1 male full — pick one for now:
	var name_index := 1

	players_cache = generator.generate_many(rng, cfg, count, next_id, nT)
	next_id += count

	# 2) build UI list
	if isClear: # Wipe the list if desired
		_clear_player_list()

	for p in players_cache:
		var row_node := player_row_scene.instantiate()
		var row := row_node as PlayerRow
		if row == null:
			push_error("Instantiated row is not a PlayerRow. Script: %s" % [str(row_node.get_script())])
			player_list_vbox.add_child(row_node)
			continue
		var ovr := overall_from_player(p)
		var s := stars_from_overall(ovr)

		player_list_vbox.add_child(row)
		
		row.set_player(p,s)
		row.hovered.connect(_on_player_hovered)
		row.exited.connect(_on_player_exited)
		row.clicked.connect(_on_player_left_clicked)

## List generator using superTypes (superstar, middle six player, bottom 6 player, etc.)
# More or less a version of _on_generate_list_ that allows for passing as much informaiton through
# as arguments as possible
func _on_generate_list_superType(
	isClear: bool = true,
	qtyStr: String = "1", 
	nameGenType: int = 1, 
	qualityBias: float = 0.0,
	qualityMean: float = 0.55,
	statVariance: float = 0.2
	) -> void:
	
	# 1) generate batch
	var cfg := _make_cfg(qualityBias, qualityMean, statVariance) # your existing config maker
	var count: int = qtyStr as int

	# name_index 0 female full, 1 male full — pick one for now:
	var nT := nameGenType

	players_cache = generator.generate_many(rng, cfg, count, next_id, nT)
	next_id += count

	# 2) build UI list
	if isClear: # Wipe the list if desired
		_clear_player_list()

	for p in players_cache:
		var row_node := player_row_scene.instantiate()
		var row := row_node as PlayerRow
		if row == null:
			push_error("Instantiated row is not a PlayerRow. Script: %s" % [str(row_node.get_script())])
			player_list_vbox.add_child(row_node)
			continue
		var ovr := overall_from_player(p)
		var s := stars_from_overall(ovr)

		player_list_vbox.add_child(row)
		
		row.set_player(p,s)
		row.hovered.connect(_on_player_hovered)
		row.exited.connect(_on_player_exited)
		row.clicked_left.connect(_on_player_left_clicked)
		row.clicked_right.connect(_on_player_right_clicked)

## Interface Controls
# Used for closing menus when clicked outside of the menu. Currently only tied to the context menu
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			if active_context_menu != null and is_instance_valid(active_context_menu):
				active_context_menu.queue_free()
				active_context_menu = null
# Hovering controls
func _on_player_hovered(p: PlayerProfile) -> void:
	if p == null:
		return
	
	playerCard.moveable(true)
	await get_tree().process_frame
	# Show element
	hideTimer.stop() # Cancels any pending hide
	playerCard.visible = true
	playerCard.moveable(false)
	
	# Set values in element
	label_name.text = p.display_name
	label_int.text = str(p.intelligence)
	label_phys.text = str(p.physical)
	label_def.text = str(p.defense)
	label_off.text = str(p.offense)
	label_role.text = PlayerGenerator.get_roleName(p.role)
	label_pos.text = PlayerGenerator.get_positionName(p.bestPos)

func _on_player_exited(p: PlayerProfile) -> void:
	if p == null:
		return
	hideTimer.start()

	# Player Card Handling
func _on_card_hovered() -> void:
	# Cancel pending hide while mouse is on the player card
	hideTimer.stop()
func _on_card_unhovered() -> void:
	# Start hide timer if mouse leaves card
	hideTimer.start()

func _on_hideTimer_timeout() -> void:
	playerCard.visible = false
	playerCard.moveable(true)


## Interacting with player list
# Variables
var active_context_menu: PlayerContextMenu = null # Create a null holding variable for active context menu checking
var active_player_row: PlayerRow = null # Create a null holding variable for the currently active player row
# Functions
func _clamp_menu_to_window(menu: Control, click_pos: Vector2) -> Vector2:
	var window_size := get_window().size
	var menu_size := menu.size
	
	var x: float = clamp(click_pos.x, 0.0, window_size.x - menu_size.x)
	var y: float = clamp(click_pos.y, 0.0, window_size.y - menu_size.y)
	return Vector2(x,y)

func _on_player_left_clicked(p: PlayerProfile, n: Node) -> void:
	if n.get_parent() == player_list_vbox: # Move player from available to selected menu
		if p.starRating <= points:
			n.reparent(selected_vbox)
			points = points - p.starRating
			label_points.text = str(points)
			playerCount = playerCount + 1
			label_playerCount.text = str(playerCount)
			
			var stat_dict = _on_average_call()
			radarTeam.set_item_value(0,stat_dict["avg_int"])
			radarTeam.set_item_value(1,stat_dict["avg_phy"])
			radarTeam.set_item_value(2,stat_dict["avg_off"])
			radarTeam.set_item_value(3,stat_dict["avg_def"])
			
	else: # Remove player from team
		n.reparent(player_list_vbox)
		points = points + p.starRating
		label_points.text = str(points)
		playerCount = playerCount - 1
		label_playerCount.text = str(playerCount)
		var stat_dict = _on_average_call()
		radarTeam.set_item_value(0,stat_dict["avg_int"])
		radarTeam.set_item_value(1,stat_dict["avg_phy"])
		radarTeam.set_item_value(2,stat_dict["avg_off"])
		radarTeam.set_item_value(3,stat_dict["avg_def"])

func _on_player_right_clicked(p: PlayerProfile, click_pos: Vector2, r: Node) -> void:
	# Close any existing menu first
	if active_context_menu != null and is_instance_valid(active_context_menu):
		active_context_menu.queue_free()
		active_context_menu = null
	
	active_player_row = r
	
	var menu := player_context_menu.instantiate() as PlayerContextMenu
	menu.active_row = r
	add_child(menu)

	menu.setup(p)
	
	await get_tree().process_frame
	menu.position = _clamp_menu_to_window(menu, click_pos)

	menu.add_to_team.connect(_on_menu_add_to_team)
	menu.remove_from_team.connect(_on_menu_remove_from_team)
	menu.show_more_info.connect(_on_menu_show_more_info)

	active_context_menu = menu
## Context menu actions
func _on_menu_add_to_team(p: PlayerProfile) -> void:
	if p.starRating <= points:
		if active_player_row.get_parent() == player_list_vbox:
			active_player_row.reparent(selected_vbox)
			points = points - p.starRating
			label_points.text = str(points)
			playerCount = playerCount + 1
			label_playerCount.text = str(playerCount)
			var stat_dict = _on_average_call()
			radarTeam.set_item_value(0,stat_dict["avg_int"])
			radarTeam.set_item_value(1,stat_dict["avg_phy"])
			radarTeam.set_item_value(2,stat_dict["avg_off"])
			radarTeam.set_item_value(3,stat_dict["avg_def"])

func _on_menu_remove_from_team(p: PlayerProfile) -> void:
	if active_player_row.get_parent() != player_list_vbox:
		active_player_row.reparent(player_list_vbox)
		points = points + p.starRating
		label_points.text = str(points)
		playerCount = playerCount - 1
		label_playerCount.text = str(playerCount)
		var stat_dict = _on_average_call()
		radarTeam.set_item_value(0,stat_dict["avg_int"])
		radarTeam.set_item_value(1,stat_dict["avg_phy"])
		radarTeam.set_item_value(2,stat_dict["avg_off"])
		radarTeam.set_item_value(3,stat_dict["avg_def"])

func _on_menu_show_more_info(p: PlayerProfile) -> void:
	print("Show more info: ", p.display_name)
	print("Ovr: ", p.overall)
	print("Stars: ", p.starRating)
	radarGraph.set_item_value(0,p.intelligence)
	radarGraph.set_item_value(1,p.physical)
	radarGraph.set_item_value(2,p.offense)
	radarGraph.set_item_value(3,p.defense)

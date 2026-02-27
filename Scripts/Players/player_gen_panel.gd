extends Control

@export var nameType: OptionButton
@export var skaterQuality: OptionButton
@export var player_row_scene: PackedScene  # assign PlayerRow.tscn in inspector
# Drag these in via the Inspector OR use the NodePath version below.
@onready var player_list_vbox: VBoxContainer = %vBox_playerList
@onready var label_int: Label = %cardLabel_int
@onready var label_phys: Label = %cardLabel_phys
@onready var label_def: Label = %cardLabel_def
@onready var label_off: Label = %cardLabel_off
@onready var label_name: Label = %cardLabel_name

#@onready var button_nor: Button = %button_Nor
#@onready var button_goo: Button = %button_Goo
#@onready var button_bad: Button = %button_Bad
#@onready var button_500: Button = %button_500

var rng := RandomNumberGenerator.new()
var generator := PlayerGenerator.new()
var last_player: PlayerProfile = null
var next_id: int = 1
var bias: float = 0

func _ready() -> void:
	rng.randomize()

	# Connect buttons (only needed if you haven't wired signals in the editor)
	#button_nor.pressed.connect(_on_generate_normal_pressed)
	#button_goo.pressed.connect(_on_generate_good_pressed)
	#button_bad.pressed.connect(_on_generate_bad_pressed)
	#button_500.pressed.connect(_on_generate_500_pressed)

func _make_cfg(bias: float) -> PlayerGenerator.GeneratorConfig:
	var cfg := PlayerGenerator.GeneratorConfig.new()
	cfg.stat_min = 1
	cfg.stat_max = 99
	cfg.base_mean = 0.55
	cfg.spread = 0.18
	cfg.bias = bias
	return cfg

func _update_player_card(p: PlayerProfile) -> void:
	label_name.text = p.display_name
	label_int.text = str(p.intelligence)
	label_phys.text = str(p.physical)
	label_def.text = str(p.defense)
	label_off.text = str(p.offense)

func _generate_and_show(bias: float, name_index: int) -> void:
	var cfg := _make_cfg(bias)
	last_player = generator.generate_profile(
		rng,
		cfg,
		next_id,
		name_index
	)
	next_id += 1
	_update_player_card(last_player)

func _on_generate_skater_pressed() -> void:
	var nT = nameType.get_selected_id()
	var q = skaterQuality.get_selected_id()
	
	if q == 1:
		bias = 0.8
	elif q == 2:
		bias = -0.8
	else:
		bias = 0.0
	
	_generate_and_show(bias, nT)
	print("Name Type:", nT)
	print("Bias Index:", q)
	print("Bias:", bias)

func _on_generate_500_pressed() -> void:
	var cfg := _make_cfg(0.0)
	var players := generator.generate_many(rng, cfg, 500, next_id)
	next_id += 500
	last_player = players[players.size() - 1]
	_update_player_card(last_player)

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



var players_cache: Array[PlayerProfile] = []

func _clear_player_list() -> void:
	for child in player_list_vbox.get_children():
		child.queue_free()

func _on_generate_list_pressed() -> void:
	# 1) generate batch
	var cfg := _make_cfg(0.0) # your existing config maker
	var count := 500

	# name_index 0 female full, 1 male full — pick one for now:
	var name_index := 1

	players_cache = generator.generate_many(rng, cfg, count, next_id, name_index)
	next_id += count

	# 2) build UI list
	_clear_player_list()

	for p in players_cache:
		var row := player_row_scene.instantiate() as PlayerRow
		var ovr := overall_from_player(p)
		var s := stars_from_overall(ovr)

		# (next step) hover updates the skater panel:
		row.hovered.connect(_on_player_hovered)

		player_list_vbox.add_child(row)
		
func _on_player_hovered(p: PlayerProfile) -> void:
	if p == null:
		return
	%cardLabel_name.text = p.display_name
	label_int.text = str(p.intelligence)
	label_phys.text = str(p.physical)
	label_def.text = str(p.defense)
	label_off.text = str(p.offense)

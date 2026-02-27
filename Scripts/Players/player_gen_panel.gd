extends Control

@export var nameType: OptionButton
@export var skaterQuality: OptionButton
# Drag these in via the Inspector OR use the NodePath version below.
@onready var label_int: Label = $panel_playerCard/VBoxContainer/GridContainer/HBox_Int/label_int
@onready var label_phys: Label = $panel_playerCard/VBoxContainer/GridContainer/HBox_Phys/label_phys
@onready var label_def: Label = $panel_playerCard/VBoxContainer/GridContainer/HBox_Def/label_defense
@onready var label_off: Label = $panel_playerCard/VBoxContainer/GridContainer/HBox_Off/label_offense
@onready var label_name: Label = $panel_playerCard/VBoxContainer/label_name

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

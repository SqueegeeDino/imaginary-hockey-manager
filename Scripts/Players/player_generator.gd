# res://Scripts/Players/player_generator.gd
class_name PlayerGenerator
extends RefCounted

var _name_gen: NameGenerator = NameGenerator.new()

func _pick_player_name(name_type: int) -> String: 
	# new_name() returns 6 options.
	# Indexes (based on how the addon builds the array):
	# Name types: 0 female full, 1 male full, 2 emi fantasy, 3 sam short, 4 sam med, 5 sam long
	var names: Array[String] = _name_gen.new_name()
	
	# Safety clamp name typing so bad input doesn't crash generation
	var idx: int = clamp(name_type, 0, names.size() -1)
	return names[idx]

## Player Information
# Generator for stats
class GeneratorConfig:
	var stat_min: int = 1
	var stat_max: int = 99
	var base_mean: float = 0.55
	var spread: float = 0.4
	var bias: float = 0.0

	# Typed dictionary values (still Variant at runtime, so we cast when reading)
	var mean_offsets: Dictionary = {
		"intelligence": 0.0,
		"physical": 0.0,
		"defense": 0.0,
		"offense": 0.0,
	}
# Role Mapping
enum Role {
	Forward = 1,
	Defense = 2
}
static var role_names := {
	Role.Forward: "Forward",
	Role.Defense: "Defense"
}
static func get_roleName(role:int) -> String:
	return role_names.get(role, "Unknown")

# Position mapping
enum Position {
	C = 1,
	LW = 2,
	RW  = 3,
	LD = 4,
	RD = 5,
	G  = 6
}
static var position_names := {
	Position.C:  "Center",
	Position.LW: "Left Wing",
	Position.RW: "Right Wing",
	Position.LD: "Left Defense",
	Position.RD: "Right Defense",
	Position.G:  "Goalie"
}
static func get_positionName(pos:int) -> String:
	return position_names.get(pos, "Unknown")

## Helper functions
# Clamp from 0 to 1
func _clamp01(x: float) -> float:
	return clamp(x, 0.0, 1.0)

func _rand_normal(rng: RandomNumberGenerator) -> float:
	var u1: float = max(rng.randf(), 0.000001)
	var u2: float = rng.randf()
	return sqrt(-2.0 * log(u1)) * cos(TAU * u2)

func _get_offset(cfg: GeneratorConfig, stat_key: String) -> float:
	# Avoid type inference from Variant: explicitly handle missing keys and cast
	if cfg.mean_offsets.has(stat_key):
		return float(cfg.mean_offsets[stat_key])
	return 0.0

func _sample_stat(rng: RandomNumberGenerator, cfg: GeneratorConfig, stat_key: String) -> int:
	var r: float = float(cfg.stat_max - cfg.stat_min)

	# Explicit types prevent "cannot infer type" errors
	var mean: float = cfg.base_mean + _get_offset(cfg, stat_key)
	mean = _clamp01(mean)

	mean = _clamp01(mean + cfg.bias * 0.25)

	var x: float = mean + _rand_normal(rng) * cfg.spread
	x = _clamp01(x)

	return int(round(cfg.stat_min + x * r))

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

func average_array(data: Array) -> float:
	if data.is_empty():
		return 0.0
	var sum: float = 0.0
	for value in data:
		sum += float(value)
	return sum / data.size()

## Profile Generation
func generate_profile(
	rng: RandomNumberGenerator, 
	cfg: GeneratorConfig, 
	id: int,
	name_type: int,
	role: int,
) -> PlayerProfile:
	
	var name: String = _pick_player_name(name_type)
	var xMin: float = 1
	var xMax: float = 10
	
	# Basic skater stats
	var i: int = _sample_stat(rng, cfg, "intelligence")
	var p: int = _sample_stat(rng, cfg, "physical")
	var d: int = _sample_stat(rng, cfg, "defense")
	var o: int = _sample_stat(rng, cfg, "offense") 
	# Position stats
	var posDict = {} # Empty dictionary created to hold the positions
	var c: int = 1
	var rw: int = 1
	var lw: int = 1
	var rd: int = 1
	var ld: int = 1
	
	# Stat adjustment based on role (forward, defender)
	if role == 1: # If player is a forward adjust stats for offense and defense
		d = clamp((d - rng.randf_range(xMin,xMax)), 1, 99)
		o = clamp((o + rng.randf_range(xMin,xMax)), 1, 99)
		c = rng.randi_range(6,10)
		rw = rng.randi_range(6,10)
		lw = rng.randi_range(6,10)
		rd = rng.randi_range(1,5)
		ld = rng.randi_range(1,5)
	elif role == 2: # If player is a defender adjust stats
		d = clamp((d + rng.randf_range(xMin,xMax)), 1, 99)
		o = clamp((o - rng.randf_range(xMin,xMax)), 1, 99)
		c = rng.randi_range(1,5)
		rw = rng.randi_range(1,5)
		lw = rng.randi_range(1,5)
		rd = rng.randi_range(6,10)
		ld = rng.randi_range(6,10)
	else:
		d = d
		o = o
		c = rng.randi_range(2,8)
		rw = rng.randi_range(2,8)
		lw = rng.randi_range(2,8)
		rd = rng.randi_range(2,8)
		ld = rng.randi_range(2,2)
	
	# Store skill values in an array
	var skillArray: Array[float] = [i, p, d, o]
	var ovr := average_array(skillArray) # Get the overall (average) value
	var stars := stars_from_overall(ovr)
	# Skater position
	# Commit values to dict (this probably sucks)
	posDict[1] = c
	posDict[2] = rw
	posDict[3] = lw
	posDict[4] = rd
	posDict[5] = ld
	# Create starting points
	var best_pos: int = 0
	var best_posRating: int = 0
	# Iterate through dictionary to find best position value
	for pos in posDict.keys():
		var r := int(posDict[pos])
		if r > best_posRating:
			best_posRating = r
			best_pos = int(pos)
	return PlayerProfile.new()

func generate_many(
	rng: RandomNumberGenerator,
	cfg: GeneratorConfig,
	count: int,
	starting_id: int = 0,
	name_type: int = 0,
) -> Array[PlayerProfile]:
	var out: Array[PlayerProfile] = []
	out.resize(count)
	for idx: int in range(count):
		var role = rng.randi_range(1,2)
		out[idx] = generate_profile(rng, cfg, starting_id + idx, name_type, role)
	return out

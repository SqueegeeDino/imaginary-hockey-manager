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
	return names[idx] # "Sam's short" is a nice default for now

class GeneratorConfig:
	var stat_min: int = 1
	var stat_max: int = 99
	var base_mean: float = 0.55
	var spread: float = 0.18
	var bias: float = 0.0

	# Typed dictionary values (still Variant at runtime, so we cast when reading)
	var mean_offsets: Dictionary = {
		"intelligence": 0.0,
		"physical": 0.0,
		"defense": 0.0,
		"offense": 0.0,
	}

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

func generate_profile(
	rng: RandomNumberGenerator, 
	cfg: GeneratorConfig, 
	id: int,
	name_type: int,
) -> PlayerProfile:
	
	var name: String = _pick_player_name(name_type)
	
	var i: int = _sample_stat(rng, cfg, "intelligence")
	var p: int = _sample_stat(rng, cfg, "physical")
	var d: int = _sample_stat(rng, cfg, "defense")
	var o: int = _sample_stat(rng, cfg, "offense")
	
	return PlayerProfile.new(id, name, i, p, d, o)

func generate_many(
	rng: RandomNumberGenerator,
	cfg: GeneratorConfig,
	count: int,
	starting_id: int = 0,
	name_type: int = 0
) -> Array[PlayerProfile]:
	var out: Array[PlayerProfile] = []
	out.resize(count)
	for idx: int in range(count):
		out[idx] = generate_profile(rng, cfg, starting_id + idx, name_type)
	return out

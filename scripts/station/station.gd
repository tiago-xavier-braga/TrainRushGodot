class_name Station
extends Node3D
## One platform: wires its train, gates, wagon queues, traffic light, passengers and upgrades,
## and loads and saves its progress under `save_prefix` (e.g. "right_capacity_tier").

## Save keys of this station start with it; the defaults are in `save_defaults.json`.
@export var save_prefix: String = "right"
## Gate prices, gate 1 first.
@export var gate_prices: Array[int] = [0, 100, 200, 400]
@export var settings: ProgressionSettings

var capacity_tier: int = 0
var speed_tier: int = 0

var _gates: Array[FenceGate] = []

@onready var train: Train = $Train
@onready var _boarding: Boarding = $Boarding
@onready var _spawner: PassengerSpawner = $PassengerSpawner


func _ready() -> void:
	capacity_tier = _load("capacity_tier")
	speed_tier = _load("speed_tier")
	train.setup($TrainStart, $TrainStop, $TrainEnd, speed_tier)
	set_capacity_tier(capacity_tier)
	var wagons_unlocked: Array = _load("wagons_unlocked")
	for i in train.wagons.size():
		if wagons_unlocked[i]:
			train.wagons[i].unlock()
		_boarding.get_queue(i).setup(train.wagons[i], train, _spawner)
	var gates_unlocked: Array = _load("gates_unlocked")
	for gate: FenceGate in $Gates.get_children():
		var i := _gates.size()
		_gates.append(gate)
		gate.price = gate_prices[i]
		gate.unlocked = gates_unlocked[i]
		gate.setup(_spawner, _boarding)
		gate.bought.connect(save_progress)
	$TrafficLight.setup(train)
	$Revenue.setup(train, settings)
	# The upgrade plates sit in different places on each platform, so the level adds them.
	var upgrades := get_node_or_null("Upgrades")
	if upgrades:
		for upgrade in upgrades.get_children():
			upgrade.setup(self)
	train.approach()


func set_capacity_tier(tier: int) -> void:
	capacity_tier = tier
	for wagon in train.wagons:
		wagon.set_capacity(tier, settings.get_capacity(tier))


func set_speed_tier(tier: int) -> void:
	speed_tier = tier
	train.set_speed_tier(tier)


func get_locked_wagons() -> Array[Wagon]:
	var locked: Array[Wagon] = []
	for wagon in train.wagons:
		if not wagon.unlocked:
			locked.append(wagon)
	return locked


## Writes tiers, gates and wagons. Upgrades call it after changing something.
func save_progress() -> void:
	SaveKit.set_value(save_prefix + "_capacity_tier", capacity_tier)
	SaveKit.set_value(save_prefix + "_speed_tier", speed_tier)
	SaveKit.set_value(save_prefix + "_gates_unlocked", _gates.map(
		func(gate: FenceGate) -> bool: return gate.unlocked))
	SaveKit.set_value(save_prefix + "_wagons_unlocked", train.wagons.map(
		func(wagon: Wagon) -> bool: return wagon.unlocked))
	SaveKit.save()


func _load(key: String) -> Variant:
	return SaveKit.get_value(save_prefix + "_" + key)

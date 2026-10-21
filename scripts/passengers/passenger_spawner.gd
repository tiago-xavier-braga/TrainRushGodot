class_name PassengerSpawner
extends Node3D
## Pool of passengers that appear at a random point of an area around this node.

const PASSENGER_SCENE: PackedScene = preload("res://scenes/passengers/passenger.tscn")

@export var max_passengers: int = 50
## Width (x) and depth (z) of the spawn area, in world axes like the Unity version.
@export var area_size: Vector2 = Vector2(10.0, 7.0)
@export var model_scenes: Array[PackedScene] = []

var _available: Array[Passenger] = []
var _created: int = 0


## Returns a passenger walking out of the spawn area, or null when all are in use.
func activate() -> Passenger:
	var passenger := _take_passenger()
	if passenger == null:
		return null
	var half := area_size / 2.0
	passenger.global_position = global_position + Vector3(
		randf_range(-half.x, half.x), 0.0, randf_range(-half.y, half.y))
	passenger.global_basis = global_basis
	passenger.appear()
	return passenger


func release(passenger: Passenger) -> void:
	passenger.disappear(func() -> void: _available.append(passenger))


func _take_passenger() -> Passenger:
	if not _available.is_empty():
		return _available.pop_at(randi() % _available.size())
	if _created >= max_passengers:
		return null
	_created += 1
	var passenger: Passenger = PASSENGER_SCENE.instantiate()
	passenger.setup(model_scenes.pick_random())
	add_child(passenger)
	return passenger

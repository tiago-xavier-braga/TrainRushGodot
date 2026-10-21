class_name QueueLine
extends Node3D
## A line of places (the Marker3D children, front first). Passengers step forward when the
## place in front of them is free.

var _places: Array[Node3D] = []
var _passengers: Array[Passenger] = []


func _ready() -> void:
	for place: Node3D in get_children():
		_places.append(place)
		_passengers.append(null)


func is_last_free() -> bool:
	return _passengers.back() == null


## Sends the passenger to the last place.
func add_last(passenger: Passenger) -> void:
	_passengers[-1] = passenger
	passenger.destination = _places.back()


## The first passenger, if they have reached the front place; null otherwise.
func ready_first() -> Passenger:
	var first := _passengers[0]
	if first == null or not first.is_at_destination():
		return null
	return first


func remove_first() -> void:
	_passengers[0] = null
	step_forward()


func step_forward() -> void:
	for i in _places.size() - 1:
		if _passengers[i] == null and _passengers[i + 1] != null:
			_passengers[i] = _passengers[i + 1]
			_passengers[i + 1] = null
			_passengers[i].destination = _places[i]

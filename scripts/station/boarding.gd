class_name Boarding
extends Node3D
## Sends passengers coming through the gates to a wagon queue (the WagonQueue children).
## Prefers a queue whose wagon still has room.

var _queues: Array[WagonQueue] = []


func _ready() -> void:
	for queue: WagonQueue in get_children():
		_queues.append(queue)


func get_queue(index: int) -> WagonQueue:
	return _queues[index]


func has_free_queue() -> bool:
	return _queues.any(func(queue: WagonQueue) -> bool: return queue.can_take())


func add(passenger: Passenger) -> void:
	var target: WagonQueue = null
	for queue in _queues:
		if queue.can_take() and queue.wagon.has_room():
			target = queue
			break
	if target == null:
		for queue in _queues:
			if queue.can_take():
				target = queue
				break
	if target != null:
		target.add_last(passenger)

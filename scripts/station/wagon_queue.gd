class_name WagonQueue
extends QueueLine
## Queue in front of one wagon. While the train waits at the platform, the first passenger
## boards whenever the wagon has room.

var wagon: Wagon

var _train: Train
var _spawner: PassengerSpawner


func setup(queue_wagon: Wagon, train: Train, spawner: PassengerSpawner) -> void:
	wagon = queue_wagon
	_train = train
	_spawner = spawner


func _physics_process(_delta: float) -> void:
	if not wagon.unlocked:
		return
	step_forward()
	if _train.state != Train.State.WAITING_FOR_SIGNAL or not wagon.has_room():
		return
	var passenger := ready_first()
	if passenger == null:
		return
	_spawner.release(passenger)
	wagon.board()
	remove_first()


func can_take() -> bool:
	return wagon.unlocked and is_last_free()

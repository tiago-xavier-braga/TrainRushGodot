class_name FenceGate
extends StaticBody3D
## A revolving fence gate with a queue of passengers in front of it.
## Hold its plate to buy it. Once unlocked, standing on the plate opens the gate and lets
## the first passenger through whenever a wagon queue has room.

signal bought

@export var price: int = 0
@export var unlocked: bool = false

var _open: bool = false
var _spawner: PassengerSpawner
var _boarding: Boarding

@onready var _queue: QueueLine = $Queue
@onready var _plate: PressurePlate = $Plate
@onready var _animation_player: AnimationPlayer = $Model/AnimationPlayer


func _ready() -> void:
	_plate.player_entered.connect(_try_open)
	_plate.player_stayed.connect(_release_passenger)
	_plate.player_exited.connect(_try_close)
	_plate.held.connect(_try_unlock)


func setup(spawner: PassengerSpawner, boarding: Boarding) -> void:
	_spawner = spawner
	_boarding = boarding
	_plate.set_price(price)
	_plate.show_info(not unlocked)
	if unlocked:
		_plate.feedback.highlighted = true
	else:
		Economy.coins_changed.connect(_on_coins_changed)
		_on_coins_changed(Economy.coins)


func _physics_process(_delta: float) -> void:
	if not unlocked:
		return
	if _queue.is_last_free():
		var passenger := _spawner.activate()
		if passenger != null:
			_queue.add_last(passenger)
	_queue.step_forward()


func _try_open() -> void:
	if not unlocked:
		return
	if _open:
		_plate.feedback.play_failure()
		return
	_open = true
	_animation_player.play("open")


func _try_close() -> void:
	if not unlocked or not _open:
		return
	_open = false
	_animation_player.play("close")


func _release_passenger() -> void:
	if not unlocked:
		return
	var passenger := _queue.ready_first()
	if passenger == null or not _boarding.has_free_queue():
		return
	_boarding.add(passenger)
	_queue.remove_first()


func _try_unlock() -> void:
	if unlocked:
		return
	if not Economy.try_spend(price):
		_plate.feedback.play_failure()
		return
	unlocked = true
	Economy.coins_changed.disconnect(_on_coins_changed)
	_plate.feedback.play_success()
	_plate.show_info(false)
	bought.emit()


## Unity keeps the last state once the gate is bought, which is always "affordable".
func _on_coins_changed(coins: int) -> void:
	_plate.feedback.highlighted = coins >= price

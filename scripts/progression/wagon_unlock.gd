extends Node3D
## Plate that unlocks the station's next wagon. Disappears once every wagon is unlocked.

var _station: Station
var _price: int = 0

@onready var _plate: PressurePlate = $Plate


func setup(station: Station) -> void:
	_station = station
	_plate.held.connect(_try_unlock)
	Economy.coins_changed.connect(_on_coins_changed)
	_refresh()


func _try_unlock() -> void:
	var locked := _station.get_locked_wagons()
	if locked.is_empty():
		return
	if not Economy.try_spend(_price):
		_plate.feedback.play_failure()
		return
	_plate.feedback.play_success()
	locked[0].unlock()
	_station.save_progress()
	_refresh()


func _refresh() -> void:
	var locked := _station.get_locked_wagons()
	if locked.is_empty():
		_plate.disable()
		return
	var unlocked_count := _station.train.wagons.size() - locked.size()
	_price = _station.settings.get_wagon_price(unlocked_count)
	_plate.set_price(_price)
	_on_coins_changed(Economy.coins)


func _on_coins_changed(coins: int) -> void:
	_plate.feedback.highlighted = coins >= _price

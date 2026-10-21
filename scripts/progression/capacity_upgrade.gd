extends Node3D
## Plate that adds one seat to every wagon of the station.

var _station: Station
var _price: int = 0

@onready var _plate: PressurePlate = $Plate


func setup(station: Station) -> void:
	_station = station
	_plate.held.connect(_try_upgrade)
	Economy.coins_changed.connect(_on_coins_changed)
	_refresh()


func _try_upgrade() -> void:
	if not Economy.try_spend(_price):
		_plate.feedback.play_failure()
		return
	_plate.feedback.play_success()
	_station.set_capacity_tier(_station.capacity_tier + 1)
	_station.save_progress()
	_refresh()


func _refresh() -> void:
	_price = _station.settings.get_capacity_price(_station.capacity_tier)
	_plate.set_price(_price)
	_on_coins_changed(Economy.coins)


func _on_coins_changed(coins: int) -> void:
	_plate.feedback.highlighted = coins >= _price

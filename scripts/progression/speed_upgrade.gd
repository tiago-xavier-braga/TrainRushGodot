extends Node3D
## Plate that makes the station's train come back sooner. Stops at the minimum respawn time.

var _station: Station
var _price: int = 0

@onready var _plate: PressurePlate = $Plate


func setup(station: Station) -> void:
	_station = station
	_plate.held.connect(_try_upgrade)
	Economy.coins_changed.connect(_on_coins_changed)
	_refresh()


func _try_upgrade() -> void:
	if _station.train.is_max_speed_tier(_station.speed_tier) or not Economy.try_spend(_price):
		_plate.feedback.play_failure()
		return
	_plate.feedback.play_success()
	_station.set_speed_tier(_station.speed_tier + 1)
	_station.save_progress()
	_refresh()


func _refresh() -> void:
	_price = _station.settings.get_speed_price(_station.speed_tier)
	_plate.set_price(_price)
	_on_coins_changed(Economy.coins)


func _on_coins_changed(coins: int) -> void:
	_plate.feedback.highlighted = coins >= _price

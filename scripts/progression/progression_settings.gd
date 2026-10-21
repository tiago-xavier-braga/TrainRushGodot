class_name ProgressionSettings
extends Resource
## Prices and capacity per upgrade tier (Unity `ProgressionSettings`).

@export var ticket_price: int = 1
@export var base_capacity_price: int = 10
@export var capacity_price_multiplier: float = 5.0
@export var base_speed_price: int = 5
@export var speed_price_multiplier: float = 10.0
@export var base_capacity: int = 2
@export var capacity_multiplier: float = 1.0
@export var base_wagon_price: int = 150
@export var wagon_price_multiplier: float = 50.0


func get_capacity_price(tier: int) -> int:
	return _get_price(tier, base_capacity_price, capacity_price_multiplier)


func get_speed_price(tier: int) -> int:
	return _get_price(tier, base_speed_price, speed_price_multiplier)


func get_wagon_price(unlocked_wagons: int) -> int:
	return _get_price(unlocked_wagons, base_wagon_price, wagon_price_multiplier)


func get_capacity(tier: int) -> int:
	return base_capacity + roundi(capacity_multiplier * tier)


func _get_price(tier: int, base_price: int, multiplier: float) -> int:
	return roundi(base_price + multiplier * tier)

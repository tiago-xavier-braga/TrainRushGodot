extends Node
## Player coins, shared by both stations. Registered as the `Economy` autoload.
## Saved after every change, like Unity's `EconomyController`.

signal coins_changed(coins: int)

const SAVE_KEY: String = "coins"

var coins: int = 0


func _ready() -> void:
	coins = SaveKit.get_value(SAVE_KEY)


func add_coins(amount: int) -> void:
	_set_coins(coins + amount)


## Spends `amount` if the player has it. Returns false (and spends nothing) otherwise.
func try_spend(amount: int) -> bool:
	if coins < amount:
		return false
	_set_coins(coins - amount)
	return true


func _set_coins(value: int) -> void:
	coins = value
	SaveKit.set_value(SAVE_KEY, coins)
	SaveKit.save()
	coins_changed.emit(coins)

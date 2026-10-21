extends Control
## Coin counter. The number shrinks away and pops back with the new value.

const POP_DURATION: float = 0.5

var _tween: TweenHandle

@onready var _label: Label = $Value


func _ready() -> void:
	_label.text = str(Economy.coins)
	Economy.coins_changed.connect(_on_coins_changed)


func _on_coins_changed(coins: int) -> void:
	if _tween:
		LeafTween.cancel(_tween)
	_label.pivot_offset = _label.size / 2.0
	_tween = LeafTween.to(_label.scale, Vector2.ZERO, POP_DURATION, _label.set_scale) \
		.set_ease(LeafTweenEasing.EaseType.OUT_ELASTIC) \
		.set_on_complete(_show_coins.bind(coins)).get_handle()


func _show_coins(coins: int) -> void:
	_label.text = str(coins)
	_tween = LeafTween.to(Vector2.ZERO, Vector2.ONE, POP_DURATION, _label.set_scale) \
		.set_ease(LeafTweenEasing.EaseType.OUT_ELASTIC).get_handle()

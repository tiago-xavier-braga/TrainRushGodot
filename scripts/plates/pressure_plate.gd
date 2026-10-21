class_name PressurePlate
extends Area3D
## A floor plate the player triggers by standing on it for `hold_time` seconds.
## Standing on it keeps re-triggering `held` every `hold_time`, like the Unity version.

signal player_entered
signal player_stayed
signal held
signal player_exited

@export var hold_time: float = 2.0
@export var icon: Texture2D:
	set(value):
		icon = value
		if is_node_ready():
			_icon.texture = icon

var _player_inside: bool = false
var _hold_elapsed: float = 0.0

## Bobbing, blinking and sounds; controllers call it to show success or failure.
@onready var feedback: PlateFeedback = $Feedback
@onready var _info: Node3D = $Info
@onready var _icon: Sprite3D = $Info/Icon
@onready var _price: Node3D = $Info/Price
@onready var _price_label: Label3D = $Info/Price/Value


func _ready() -> void:
	_icon.texture = icon
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if not _player_inside:
		return
	player_stayed.emit()
	_hold_elapsed += delta
	if _hold_elapsed < hold_time:
		return
	_hold_elapsed = 0.0
	held.emit()


func set_price(price: int) -> void:
	_price.visible = true
	_price_label.text = str(price)


func hide_price() -> void:
	_price.visible = false


## Icon and price (Unity hides the plate's canvas once a gate is bought).
func show_info(info_visible: bool) -> void:
	_info.visible = info_visible


## Hides the plate and stops it from reacting, e.g. when every wagon is unlocked.
func disable() -> void:
	hide()
	set_deferred("monitoring", false)
	_player_inside = false


func _on_body_entered(body: Node3D) -> void:
	if not body is Player:
		return
	_player_inside = true
	_hold_elapsed = 0.0
	player_entered.emit()


func _on_body_exited(body: Node3D) -> void:
	if not body is Player:
		return
	_player_inside = false
	_hold_elapsed = 0.0
	player_exited.emit()

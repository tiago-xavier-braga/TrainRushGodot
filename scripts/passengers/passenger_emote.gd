class_name PassengerEmote
extends Sprite3D
## A passenger who stands idle too long shows a random annoyed emote for a few seconds
## (Unity `DissatisfactionController`). The timer only runs while the passenger is idle.

const EMOTES: Array[Texture2D] = [
	preload("res://assets/textures/ui/txt_emote_anger.tres"),
	preload("res://assets/textures/ui/txt_emote_cross.tres"),
	preload("res://assets/textures/ui/txt_emote_sleep.tres"),
	preload("res://assets/textures/ui/txt_emote_gloom.tres"),
]
const POP_DURATION: float = 1.0

@export var patience: float = 15.0
@export var show_time: float = 5.0

var _idle_time: float = 0.0
var _showing: bool = false
var _tween: TweenHandle

@onready var _passenger: Passenger = get_parent()


func _ready() -> void:
	scale = Vector3.ZERO
	hide()


func _process(delta: float) -> void:
	if _showing or not _passenger.is_idle():
		return
	_idle_time += delta
	if _idle_time < patience:
		return
	_showing = true
	texture = EMOTES.pick_random()
	show()
	_pop(Vector3.ONE)
	get_tree().create_timer(show_time).timeout.connect(reset)


## Hides the emote and restarts the patience timer.
func reset() -> void:
	_idle_time = 0.0
	if not _showing:
		return
	_showing = false
	_pop(Vector3.ZERO)


func _pop(to: Vector3) -> void:
	if _tween:
		LeafTween.cancel(_tween)
	_tween = LeafTween.to(scale, to, POP_DURATION, set_scale) \
		.set_ease(LeafTweenEasing.EaseType.OUT_ELASTIC).get_handle()

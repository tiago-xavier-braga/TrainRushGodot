class_name FloatingText
extends Node3D
## Text that pops up, rises and disappears (Unity `CameraFacingTextAnimation`).
## Its children are billboards, so it always faces the camera.

@export var rise: float = 4.0
@export var duration: float = 0.8

var _start: Vector3
var _playing: bool = false

@onready var _label: Label3D = $Label


func _ready() -> void:
	_start = position
	hide()


## Ignored while the previous text is still rising, like the Unity version.
func play(text: String) -> void:
	if _playing:
		return
	_playing = true
	_label.text = text
	position = _start
	scale = Vector3.ZERO
	show()
	LeafTween.to(Vector3.ZERO, Vector3.ONE, duration, set_scale) \
		.set_ease(LeafTweenEasing.EaseType.OUT_ELASTIC)
	LeafTween.to(_start, _start + Vector3.UP * rise, duration, set_position) \
		.set_ease(LeafTweenEasing.EaseType.OUT_ELASTIC).set_on_complete(_finish)


func _finish() -> void:
	hide()
	position = _start
	_playing = false

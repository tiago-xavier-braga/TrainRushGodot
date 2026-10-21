class_name TouchJoystick
extends Control
## On-screen stick for touch screens (Unity `OnScreenStick`). It presses the same move actions
## as the keyboard, with the stick's strength, so the player script needs nothing special.
## Touches arrive as emulated mouse events, so it can also be tried with a mouse.

## How far the knob travels from the center, in pixels (Unity: 50 at 1080p).
@export var movement_range: float = 33.0

var _dragging: bool = false

@onready var _knob: Control = $Knob


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()
	_center_knob(Vector2.ZERO)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		_move_stick(event.position if _dragging else size / 2.0)
	elif event is InputEventMouseMotion and _dragging:
		_move_stick(event.position)


func _move_stick(local_position: Vector2) -> void:
	var offset := (local_position - size / 2.0).limit_length(movement_range)
	_center_knob(offset)
	var stick := offset / movement_range
	_press_axis("move_right", "move_left", stick.x)
	_press_axis("move_down", "move_up", stick.y)


func _center_knob(offset: Vector2) -> void:
	_knob.position = size / 2.0 + offset - _knob.size / 2.0


func _press_axis(positive: StringName, negative: StringName, value: float) -> void:
	Input.action_release(positive)
	Input.action_release(negative)
	if value > 0.0:
		Input.action_press(positive, value)
	elif value < 0.0:
		Input.action_press(negative, -value)

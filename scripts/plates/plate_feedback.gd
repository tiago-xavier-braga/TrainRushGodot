class_name PlateFeedback
extends Node
## Plate animation and sounds (Unity `PressurePlateAnimation`). While the plate can be used,
## its floor marker bobs; it sinks while the player stands on it, and blinks green or red on
## success or failure.

const MIN_Y: float = 0.01
const MAX_Y: float = 0.2
const BOB_SPEED: float = 0.2
const SINK_SPEED: float = 5.0
const BLINK_DURATION: float = 2.0
const BLINK_SPEED: float = 6.0
const DEFAULT_COLOR := Color.WHITE
const SUCCESS_COLOR := Color(0.4117647, 0.99215686, 0.18039216)
const FAILURE_COLOR := Color(0.99215686, 0.18039216, 0.18039216)

## Bob to tell the player this plate can be used (affordable, train waiting...).
var highlighted: bool = false

var _player_on: bool = false
var _bob_time: float = 0.0
var _blink_elapsed: float = -1.0
var _blink_color: Color
var _material: StandardMaterial3D

@onready var _plate: PressurePlate = get_parent()
@onready var _marker: Node3D = $"../Model"
@onready var _enter_sound: AudioStreamPlayer = $Enter
@onready var _exit_sound: AudioStreamPlayer = $Exit
@onready var _success_sound: AudioStreamPlayer = $Success
@onready var _failure_sound: AudioStreamPlayer = $Failure


func _ready() -> void:
	var mesh: MeshInstance3D = _marker.find_children("*", "MeshInstance3D", true, false)[0]
	_material = mesh.get_active_material(0).duplicate()
	mesh.material_override = _material
	_plate.player_entered.connect(_on_player_entered)
	_plate.player_exited.connect(_on_player_exited)


func _process(delta: float) -> void:
	var y := _marker.global_position.y
	if _player_on or not highlighted:
		y = maxf(y - delta * SINK_SPEED, MIN_Y)
	else:
		_bob_time += delta * BOB_SPEED
		y = MIN_Y + pingpong(_bob_time, MAX_Y - MIN_Y)
	_marker.global_position.y = y
	if _blink_elapsed < 0.0:
		return
	_blink_elapsed += delta
	if _blink_elapsed >= BLINK_DURATION:
		_stop_blink()
		return
	_material.albedo_color = DEFAULT_COLOR.lerp(_blink_color, absf(sin(_blink_elapsed * BLINK_SPEED)))


func play_success() -> void:
	_success_sound.play()
	_blink(SUCCESS_COLOR)


func play_failure() -> void:
	_failure_sound.play()
	_blink(FAILURE_COLOR)


func _blink(color: Color) -> void:
	_blink_color = color
	_blink_elapsed = 0.0


func _stop_blink() -> void:
	_blink_elapsed = -1.0
	_material.albedo_color = DEFAULT_COLOR


func _on_player_entered() -> void:
	_player_on = true
	_bob_time = 0.0
	_enter_sound.play()


func _on_player_exited() -> void:
	_player_on = false
	_stop_blink()
	_exit_sound.play()

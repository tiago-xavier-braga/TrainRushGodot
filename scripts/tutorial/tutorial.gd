class_name Tutorial
extends Node3D
## First-run guide (Unity `TutorialController`). The arrow points at the first gate until the
## starting wagons are full, then at the traffic light. Unity's check runs every frame while the
## train departs, so the first departure already ends the tutorial; the port keeps that.

signal completed

enum Step { FENCE, TRAFFIC_LIGHT, COMPLETED }

const SAVE_KEY: String = "tutorial_completed"
const ARROW_POP_DURATION: float = 1.0
## The arrow bobs down by this much and back, every two seconds (Unity `ArrowAnimation`).
const BOB_HEIGHT: float = 1.0
const BOB_DURATION: float = 1.0

var step: Step = Step.FENCE

var _station: Station
var _arrow_tween: TweenHandle

@onready var _arrow: Node3D = $Arrow
@onready var _arrow_model: Node3D = $Arrow/Model
@onready var _fence_target: Node3D = $FenceTarget
@onready var _light_target: Node3D = $TrafficLightTarget


func _ready() -> void:
	_arrow.scale = Vector3.ZERO
	if SaveKit.get_value(SAVE_KEY):
		step = Step.COMPLETED
		set_process(false)
		return
	var top := _arrow_model.position
	LeafTween.to(top, top + Vector3.DOWN * BOB_HEIGHT, BOB_DURATION, _arrow_model.set_position) \
		.set_ease(LeafTweenEasing.EaseType.IN_OUT_SINE).set_loop(-1).set_ping_pong()
	_station = get_parent()
	await _station.ready
	_station.train.state_changed.connect(_on_train_state_changed)
	_point_at(_fence_target)


func _process(_delta: float) -> void:
	if step != Step.FENCE:
		return
	for wagon in _station.train.wagons:
		if wagon.unlocked and wagon.boarded < wagon.capacity:
			return
	step = Step.TRAFFIC_LIGHT
	_point_at(_light_target)


func _on_train_state_changed(state: Train.State) -> void:
	if step != Step.TRAFFIC_LIGHT or state != Train.State.DEPARTING:
		return
	step = Step.COMPLETED
	_pop(Vector3.ZERO)
	SaveKit.set_value(SAVE_KEY, true)
	SaveKit.save()
	completed.emit()


## Shrinks the arrow, moves it to `target`, then grows it back. Uses local position/rotation
## (the targets are siblings): a global rotation can't be set while the scale is zero.
func _point_at(target: Node3D) -> void:
	_pop(Vector3.ZERO, func() -> void:
		_arrow.position = target.position
		_arrow.rotation = target.rotation
		_pop(Vector3.ONE))


func _pop(to: Vector3, on_complete: Callable = Callable()) -> void:
	if _arrow_tween:
		LeafTween.cancel(_arrow_tween)
	_arrow_tween = LeafTween.to(_arrow.scale, to, ARROW_POP_DURATION, _arrow.set_scale) \
		.set_ease(LeafTweenEasing.EaseType.OUT_ELASTIC).set_on_complete(on_complete).get_handle()

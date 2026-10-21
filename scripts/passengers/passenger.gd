class_name Passenger
extends Node3D
## Walks straight to its destination marker, then turns to face the marker's direction.

const SPAWN_DURATION: float = 1.0

@export var speed: float = 5.0
@export var rotation_speed: float = 10.0
@export var stop_distance: float = 0.1

var destination: Node3D

var _model: CharacterModel
var _tween: TweenHandle

@onready var _emote: PassengerEmote = $Emote


## Builds the passenger with one of the Kenney character models.
func setup(model_scene: PackedScene) -> void:
	_model = CharacterModel.create(model_scene)
	add_child(_model)


func _physics_process(delta: float) -> void:
	if destination == null:
		return
	var direction := destination.global_position - global_position
	direction.y = 0.0
	var target: Basis
	if direction.length() <= stop_distance:
		_model.set_state(CharacterModel.State.IDLE)
		target = destination.global_basis.orthonormalized()
	else:
		_model.set_state(CharacterModel.State.WALKING)
		global_position += direction.limit_length(speed * delta)
		target = Basis.looking_at(direction)
	global_basis = global_basis.slerp(target, minf(rotation_speed * delta, 1.0)).orthonormalized()


func is_idle() -> bool:
	return visible and _model.state == CharacterModel.State.IDLE


func is_at_destination() -> bool:
	return global_position.distance_to(destination.global_position) < stop_distance


## Grows in from nothing, like Unity's spawn animation.
func appear() -> void:
	show()
	_scale_to(Vector3.ONE, Vector3.ZERO)


## Shrinks away, then hides and calls `on_finished`.
func disappear(on_finished: Callable) -> void:
	destination = null
	_emote.reset()
	_scale_to(Vector3.ZERO, _model.scale, func() -> void:
		hide()
		on_finished.call())


## Scales the model, not this node, so the rotation code keeps an orthonormal basis.
func _scale_to(to: Vector3, from: Vector3, on_complete: Callable = Callable()) -> void:
	if _tween:
		LeafTween.cancel(_tween)
	_model.scale = from
	_tween = LeafTween.to(from, to, SPAWN_DURATION, _model.set_scale) \
		.set_ease(LeafTweenEasing.EaseType.OUT_ELASTIC) \
		.set_on_complete(on_complete).get_handle()

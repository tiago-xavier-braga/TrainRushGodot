class_name Wagon
extends Node3D
## A wagon behind the train. Only unlocked wagons get a model (and so a collider) and take
## passengers. The model follows the station's capacity tier, swells as passengers board, and
## a "full" bubble shows above it once every seat is taken.

const SPAWN_DURATION: float = 1.0
## Spawn animations start here, not at zero: a zero-scaled collider makes the physics fail.
const SPAWN_SCALE := Vector3(0.01, 0.01, 0.01)
const BOARDING_DURATION: float = 0.5
## Model scale when full (Unity `WagonBoardingAnimation`): wider and taller, same length.
const FULL_SCALE := Vector3(1.2, 1.2, 1.0)

@export var models: Array[WagonData] = []

var unlocked: bool = false
var capacity: int = 0
var boarded: int = 0

var _data: WagonData
var _model: Node3D
var _mesh: Node3D
var _mesh_scale: Vector3
var _spawn_tween: TweenHandle
var _boarding_tween: TweenHandle
var _alert_tween: TweenHandle
var _alert_visible: bool = false

@onready var _holder: Node3D = $Model
@onready var _alert: Node3D = $Alert
@onready var _upgrade_sound: AudioStreamPlayer = $UpgradeSound


func _ready() -> void:
	_set_alert_alpha(0.0)


func unlock() -> void:
	if unlocked:
		return
	unlocked = true
	_create_model()


## Seats and model for a capacity tier.
func set_capacity(tier: int, seats: int) -> void:
	capacity = seats
	var data := _data_for(tier)
	var changed := data != _data
	_data = data
	if not unlocked:
		return
	if changed:
		_create_model()
	# Unity plays it on every capacity upgrade, even when the model stays the same.
	_upgrade_sound.play()


func has_room() -> bool:
	return unlocked and boarded < capacity


func board() -> void:
	boarded += 1
	_update_boarding()


func empty() -> void:
	boarded = 0
	_update_boarding()


## First model whose tier is at least `tier`, like Unity's `WagonSpawnController`.
func _data_for(tier: int) -> WagonData:
	for data in models:
		if data.tier_upgrade >= tier:
			return data
	return models.back()


func _create_model() -> void:
	if _model:
		LeafTween.cancel(_spawn_tween)
		if _boarding_tween:
			LeafTween.cancel(_boarding_tween)
		_model.queue_free()
	_model = _data.model.instantiate()
	_holder.add_child(_model)
	_mesh = _model.get_node("Model/Mesh")
	_mesh_scale = _mesh.scale
	_model.scale = SPAWN_SCALE
	_spawn_tween = LeafTween.to(SPAWN_SCALE, Vector3.ONE, SPAWN_DURATION, _model.set_scale) \
		.set_ease(LeafTweenEasing.EaseType.OUT_ELASTIC).get_handle()


## Only the mesh swells: scaling the body would stretch its collider unevenly.
func _update_boarding() -> void:
	if not unlocked or capacity == 0:
		return
	var fill := float(boarded) / capacity
	var target := _mesh_scale * Vector3.ONE.lerp(FULL_SCALE, fill)
	if _boarding_tween:
		LeafTween.cancel(_boarding_tween)
	_boarding_tween = LeafTween.to(_mesh.scale, target, BOARDING_DURATION, _mesh.set_scale) \
		.set_ease(LeafTweenEasing.EaseType.OUT_ELASTIC).get_handle()
	_show_alert(boarded >= capacity)


func _show_alert(show_full: bool) -> void:
	if show_full == _alert_visible:
		return
	_alert_visible = show_full
	if _alert_tween:
		LeafTween.cancel(_alert_tween)
	var from: float = (_alert.get_child(0) as Sprite3D).modulate.a
	var to := 1.0 if show_full else 0.0
	_alert_tween = LeafTween.to(from, to, BOARDING_DURATION, _set_alert_alpha) \
		.set_ease(LeafTweenEasing.EaseType.OUT_ELASTIC).get_handle()


func _set_alert_alpha(alpha: float) -> void:
	for sprite: Sprite3D in _alert.get_children():
		sprite.modulate.a = alpha

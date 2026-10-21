class_name Train
extends Node3D
## Train cycle: approach the platform, wait for the signal, depart, then come back after the
## respawn time. The speed tier shortens the respawn time and changes the train model.

signal state_changed(state: State)

enum State { IDLE, APPROACHING, WAITING_FOR_SIGNAL, DEPARTING, FINALIZED }

@export var speed: float = 10.0
@export var base_respawn_time: float = 10.0
@export var respawn_reduction_per_tier: float = 0.5
@export var min_respawn_time: float = 4.0
@export var models: Array[TrainData] = []

var state: State = State.IDLE
var wagons: Array[Wagon] = []
var respawn_time: float = 10.0

var _from: Vector3
var _to: Vector3
var _duration: float = 0.0
var _elapsed: float = 0.0
var _start: Node3D
var _stop: Node3D
var _end: Node3D
var _data: TrainData
var _model: Node3D
var _spawn_tween: TweenHandle

@onready var _respawn_timer: Timer = $RespawnTimer
@onready var _model_holder: Node3D = $Model
@onready var _movement_sound: AudioStreamPlayer = $Sounds/Movement
@onready var _horn_sound: AudioStreamPlayer = $Sounds/Horn
@onready var _upgrade_sound: AudioStreamPlayer = $Sounds/Upgrade


func _ready() -> void:
	for wagon: Wagon in $Wagons.get_children():
		wagons.append(wagon)
	_respawn_timer.timeout.connect(approach)


func _physics_process(delta: float) -> void:
	if state != State.APPROACHING and state != State.DEPARTING:
		return
	_elapsed += delta
	var t := clampf(_elapsed / _duration, 0.0, 1.0)
	global_position = _from.lerp(_to, smoothstep(0.0, 1.0, t))
	# Unity raises the moving sound with the trip's progress.
	_movement_sound.volume_db = linear_to_db(t)
	if t < 1.0:
		return
	_movement_sound.stop()
	if state == State.APPROACHING:
		_horn_sound.play()
		_set_state(State.WAITING_FOR_SIGNAL)
	else:
		_finalize()


## Markers for where the train appears, stops at the platform and leaves.
func setup(start: Node3D, stop: Node3D, end: Node3D, speed_tier: int) -> void:
	_start = start
	_stop = stop
	_end = end
	respawn_time = _respawn_time_for(speed_tier)
	_data = models[0]
	for data in models:
		if data.tier_update >= speed_tier:
			_data = data
			break
	_create_model()


func set_speed_tier(tier: int) -> void:
	respawn_time = _respawn_time_for(tier)
	# Unity's TrainUpgradeController: one model at a time, and never the last one.
	if _data.order >= models.size() - 1:
		return
	var next := models[_data.order]
	if tier < next.tier_update:
		return
	_data = next
	_create_model()
	_upgrade_sound.play()


func is_max_speed_tier(tier: int) -> bool:
	return base_respawn_time - respawn_reduction_per_tier * (tier + 1) <= min_respawn_time


func approach() -> void:
	_move(_start.global_position, _stop.global_position)
	_set_state(State.APPROACHING)


func depart() -> void:
	_move(_stop.global_position, _end.global_position)
	_horn_sound.play()
	_set_state(State.DEPARTING)


func _respawn_time_for(tier: int) -> float:
	return maxf(min_respawn_time, base_respawn_time - respawn_reduction_per_tier * tier)


func _create_model() -> void:
	if _model:
		LeafTween.cancel(_spawn_tween)
		_model.queue_free()
	_model = _data.model.instantiate()
	_model_holder.add_child(_model)
	_model.scale = Wagon.SPAWN_SCALE
	_spawn_tween = LeafTween.to(
		Wagon.SPAWN_SCALE, Vector3.ONE, Wagon.SPAWN_DURATION, _model.set_scale) \
		.set_ease(LeafTweenEasing.EaseType.OUT_ELASTIC).get_handle()


func _finalize() -> void:
	for wagon in wagons:
		wagon.empty()
	_set_state(State.FINALIZED)
	_respawn_timer.start(respawn_time)


func _move(from: Vector3, to: Vector3) -> void:
	_from = from
	_to = to
	_duration = absf(to.z - from.z) / speed
	_elapsed = 0.0
	global_position = from
	_movement_sound.volume_db = linear_to_db(0.0)
	_movement_sound.play()


func _set_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(state)

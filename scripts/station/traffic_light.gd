class_name TrafficLight
extends Node3D
## Red while the train comes in, green when the player pulls the lever, yellow once it left.

const LEVER_ANGLE: float = 50.0
const LEVER_DURATION: float = 2.0

@export var off_material: Material
@export var red_material: Material
@export var yellow_material: Material
@export var green_material: Material

var _train: Train
var _lever_tween: TweenHandle

@onready var _red: MeshInstance3D = $Model/RedOn
@onready var _yellow: MeshInstance3D = $Model/YellowOn
@onready var _green: MeshInstance3D = $Model/GreenOn
@onready var _handle: Node3D = $Lever.find_child("handle")
@onready var _plate: PressurePlate = $Plate


func _ready() -> void:
	_plate.held.connect(_release_train)
	_plate.show_info(false)


func setup(train: Train) -> void:
	_train = train
	_train.state_changed.connect(_on_train_state_changed)


func _release_train() -> void:
	if _train.state != Train.State.WAITING_FOR_SIGNAL:
		_plate.feedback.play_failure()
		return
	_plate.feedback.play_success()
	_plate.feedback.highlighted = false
	_set_lights(false, false, true)
	_train.depart()
	_rotate_lever(LEVER_ANGLE, -LEVER_ANGLE)


func _on_train_state_changed(state: Train.State) -> void:
	match state:
		Train.State.APPROACHING:
			_set_lights(true, false, false)
			_rotate_lever(-LEVER_ANGLE, LEVER_ANGLE)
		Train.State.WAITING_FOR_SIGNAL:
			_plate.feedback.highlighted = true
		Train.State.FINALIZED:
			_set_lights(false, true, false)


func _set_lights(red: bool, yellow: bool, green: bool) -> void:
	_red.material_override = red_material if red else off_material
	_yellow.material_override = yellow_material if yellow else off_material
	_green.material_override = green_material if green else off_material


## Unity mirrors the model on X, so its +50 degree handle angle is -50 here.
func _rotate_lever(from_degrees: float, to_degrees: float) -> void:
	if _lever_tween:
		LeafTween.cancel(_lever_tween)
	var from := Vector3(0.0, 0.0, -from_degrees)
	_handle.rotation_degrees = from
	_lever_tween = LeafTween.to(from, Vector3(0.0, 0.0, -to_degrees), LEVER_DURATION,
		_handle.set_rotation_degrees).set_ease(LeafTweenEasing.EaseType.OUT_ELASTIC).get_handle()

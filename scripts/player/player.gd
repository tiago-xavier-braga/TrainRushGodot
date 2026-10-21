class_name Player
extends CharacterBody3D
## Top-down movement on the ground plane; turns smoothly toward where it walks.

@export var speed: float = 5.0
@export var rotation_speed: float = 10.0
@export var model_material: Material

@onready var _model: CharacterModel = $Model


func _ready() -> void:
	_model.set_material(model_material)


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input.x, 0.0, input.y)
	velocity = direction * speed
	move_and_slide()
	if direction.is_zero_approx():
		_model.set_state(CharacterModel.State.IDLE)
		return
	_model.set_state(CharacterModel.State.WALKING)
	var target := Basis.looking_at(direction)
	basis = basis.slerp(target, minf(rotation_speed * delta, 1.0)).orthonormalized()

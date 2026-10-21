class_name CharacterModel
extends Node3D
## Holds a Kenney character model and plays its idle/walk animations.

enum State { IDLE, WALKING }

## Kenney models face +Z and are half the size used in Unity.
const MODEL_TRANSFORM := Transform3D(
	Vector3(-2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0), Vector3(0.0, 0.0, -2.0), Vector3.ZERO)
const ANIMATIONS: Dictionary = {State.IDLE: "idle", State.WALKING: "walk"}

var state: State = State.IDLE

var _animation_player: AnimationPlayer


static func create(model_scene: PackedScene) -> CharacterModel:
	var character_model := CharacterModel.new()
	var model: Node3D = model_scene.instantiate()
	model.transform = MODEL_TRANSFORM
	character_model.add_child(model)
	return character_model


func _ready() -> void:
	_animation_player = find_child("AnimationPlayer", true, false)
	for animation_name: String in ANIMATIONS.values():
		_animation_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	_animation_player.play(ANIMATIONS[state])


func set_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	_animation_player.play(ANIMATIONS[state])


## Replaces every surface material, e.g. to give the player a different texture.
func set_material(material: Material) -> void:
	for mesh_instance: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		mesh_instance.material_override = material

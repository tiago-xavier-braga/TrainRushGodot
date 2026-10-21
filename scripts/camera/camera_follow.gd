extends Camera3D
## Keeps a fixed offset from the target and looks at it.

@export var target: Node3D
@export var offset: Vector3 = Vector3(0.0, 18.0, 18.0)


func _process(_delta: float) -> void:
	global_position = target.global_position + offset
	look_at(target.global_position)

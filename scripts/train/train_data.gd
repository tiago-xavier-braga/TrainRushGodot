class_name TrainData
extends Resource
## One train look, unlocked by the speed upgrade tier.

@export var order: int = 1
@export var model: PackedScene
## Speed tier that switches to this model.
@export var tier_update: int = 0

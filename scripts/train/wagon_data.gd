class_name WagonData
extends Resource
## One wagon look. A wagon uses the first model whose `tier_upgrade` is at least the capacity
## tier (Unity rule).

@export var model: PackedScene
@export var tier_upgrade: int = 0

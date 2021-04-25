extends Node2D

onready var player = $Light/AnimationPlayer

func _ready() -> void:
	var offset = randf() * 0.5
	player.play('Idle')
	player.seek(offset)

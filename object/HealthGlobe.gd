extends Area2D
class_name HealthGlobe

onready var animation = $Sprite/AnimationPlayer
onready var collect_sound = $Collect

var collected = false

func _ready() -> void:
	animation.play('Bob')
	animation.seek(randf(), true)

func collect() -> void:
	collected = true
	animation.play('FadeOut')
	collect_sound.play()
	yield(get_tree().create_timer(1.25), 'timeout')
	queue_free()

extends KinematicBody2D

onready var sprite = $AnimatedSprite
onready var snowsteps = $SnowSteps
onready var winter_snow_loop = $WinterSnowLoop

const ACCELERATION = 650
const MAX_SPEED = 50
const FRICTION = 500

export(float) var stamina = 10.0
export(float) var stamina_regen = 1.0
var current_stamina: float

var velocity = Vector2.ZERO

func _ready() -> void:
	current_stamina = stamina
	winter_snow_loop.play()

func _physics_process(delta: float) -> void:
	var input: Vector2 = Vector2.ZERO
	input.x = Input.get_action_strength('ui_right') - Input.get_action_strength('ui_left')
	input.y = Input.get_action_strength('ui_down') - Input.get_action_strength('ui_up')

	if input.length() > 0:
		if sprite.animation != 'Walking':
			sprite.play('Walking')
			snowsteps.play(0.5 + randf())
		input = input.normalized()
		velocity = velocity.move_toward(input * MAX_SPEED, ACCELERATION * delta)
	else:
		if sprite.animation != 'Idle':
			sprite.play('Idle')
			snowsteps.stop()
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	velocity = move_and_slide(velocity)
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false


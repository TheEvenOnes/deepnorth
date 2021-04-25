extends KinematicBody2D

const ACCELERATION = 650
const MAX_SPEED = 50
const FRICTION = 500

var velocity = Vector2.ZERO

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	var input: Vector2 = Vector2.ZERO
	input.x = Input.get_action_strength('ui_right') - Input.get_action_strength('ui_left')
	input.y = Input.get_action_strength('ui_down') - Input.get_action_strength('ui_up')

	if input.length() > 0:
		input = input.normalized()
		velocity = velocity.move_toward(input * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	velocity = move_and_slide(velocity)

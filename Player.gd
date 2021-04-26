extends KinematicBody2D

onready var sprite = $AnimatedSprite
onready var snowsteps = $Sounds/SnowSteps
onready var winter_snow_loop = $Sounds/WinterSnowLoop
onready var wolf_boss = $Sounds/WolfBoss
onready var dash = $Sounds/Dash
onready var info_text = $Camera2D/CanvasLayer/Control/Info
onready var info_text_anim = $Camera2D/CanvasLayer/Control/Info/AnimationPlayer
onready var stamina_indicator = $Camera2D/CanvasLayer/Control/StaminaIndicator

const ACCELERATION = 650
const MAX_SPEED = 50
const FRICTION = 500
const DASH_SPEED = 200

export(float) var stamina = 10.0
export(float) var stamina_regen = 1.0
var current_stamina: float

var velocity = Vector2.ZERO
var last_direction = Vector2.RIGHT

enum State {
	Idle
	Walking
	Dashing
}
var state = State.Idle
var previous_state = State.Idle

func next_state(new_state: int) -> void:
	previous_state = state
	state = new_state

func _ready() -> void:
	current_stamina = stamina
	winter_snow_loop.play()
	yield(get_tree().create_timer(1.0), 'timeout')
	wolf_boss.play()
	yield(get_tree().create_timer(2.0), 'timeout')
	info_text = 'Wolf  howls  in  the  distance, be  careful'
	info_text_anim.play('FadeIn')
	yield(get_tree().create_timer(6.0), 'timeout')
	info_text_anim.play_backwards('FadeIn')


func process_idle(delta: float) -> void:
	if sprite.animation != 'Idle':
		sprite.animation = 'Idle'

	var input: Vector2 = Vector2.ZERO
	input.x = Input.get_action_strength('ui_right') - Input.get_action_strength('ui_left')
	input.y = Input.get_action_strength('ui_down') - Input.get_action_strength('ui_up')

	if input.length() > 0.0:
		next_state(State.Walking)
		process_walking(delta)
	elif Input.is_action_just_pressed('ui_accept'):
		next_state(State.Dashing)
		process_dashing(delta)
	else:
		current_stamina = min(current_stamina + delta * stamina_regen, stamina)
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)


func process_walking(delta: float) -> void:
	if previous_state != State.Walking:
		next_state(State.Walking)
		sprite.play('Walking')
		snowsteps.play(0.5 + randf())
		next_state(State.Walking)

	var input: Vector2 = Vector2.ZERO
	input.x = Input.get_action_strength('ui_right') - Input.get_action_strength('ui_left')
	input.y = Input.get_action_strength('ui_down') - Input.get_action_strength('ui_up')

	if Input.is_action_just_pressed('ui_accept') and current_stamina > 3.33:
		snowsteps.stop()
		next_state(State.Dashing)
		process_dashing(delta)
	elif not input.length() > 0.0:
		snowsteps.stop()
		next_state(State.Idle)
		process_idle(delta)
	else:
		current_stamina = min(current_stamina + delta * stamina_regen * 0.25, stamina)
		input = input.normalized()
		last_direction = input
		velocity = velocity.move_toward(input * MAX_SPEED, ACCELERATION * delta)


func process_dashing(delta: float) -> void:
	if previous_state != State.Dashing:
		next_state(State.Dashing)
		current_stamina -= 3.33
		sprite.play('Dash')
		snowsteps.stop()
		dash.play()
		velocity = last_direction * DASH_SPEED

	if velocity.length() <= 0.001:
		dash.stop()
		next_state(State.Idle)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)


func process_movement() -> void:
	velocity = move_and_slide(velocity)
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false

func update_gui() -> void:
	stamina_indicator.rect_size.x = current_stamina / stamina * 40

func _physics_process(delta: float) -> void:
	match state:
		State.Idle: process_idle(delta)
		State.Walking: process_walking(delta)
		State.Dashing: process_dashing(delta)
	process_movement()
	update_gui()

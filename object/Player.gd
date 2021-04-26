extends KinematicBody2D
class_name Player

var game_state = preload('res://level/GameState.tres')

onready var sprite = $AnimatedSprite
onready var anim_player = $AnimatedSprite/AnimationPlayer

onready var snowsteps = $Sounds/SnowSteps
onready var winter_snow_loop = $Sounds/WinterSnowLoop
onready var wolf_boss = $Sounds/WolfBoss
onready var dash = $Sounds/Dash
onready var slash = $Sounds/Slash

onready var info_text = $Camera2D/CanvasLayer/Control/Info
onready var info_text_anim = $Camera2D/CanvasLayer/Control/Info/AnimationPlayer
onready var stamina_indicator = $Camera2D/CanvasLayer/Control/StaminaIndicator
onready var health_indicator = $Camera2D/CanvasLayer/Control/HealthIndicator
onready var sun_shards_counter = $Camera2D/CanvasLayer/Control/SunShardsCounter
onready var sun_shards_anim = $Camera2D/CanvasLayer/Control/SunShardIcon/AnimationPlayer

onready var collect_box = $Collectbox
onready var hurt_box = $Hurtbox
onready var hurt_box_collider = $Hurtbox/CollisionShape2D

const ACCELERATION = 650
const MAX_SPEED = 50
const FRICTION = 500
const DASH_SPEED = 200

export(float) var health = 10.0
var current_health = health * 0.5

export(float) var stamina = 10.0
export(float) var stamina_regen = 2.0
var current_stamina: float
var sun_shards: float = 0

var velocity = Vector2.ZERO
var last_direction = Vector2.RIGHT
var slashing_timer: float = 0
var dead = false

enum State {
	PreGame
	Idle
	Walking
	Dashing
	Slashing
	Dead
	Victory
}
var state = State.PreGame
var previous_state = State.Idle

func next_state(new_state: int) -> void:
	previous_state = state
	state = new_state

func _ready() -> void:
	collect_box.connect('area_entered', self, '_on_area_entered')
	hurt_box.connect('area_entered', self, '_on_area_entered_hurtbox')
	hurt_box_collider.disabled = true
	current_stamina = stamina
	winter_snow_loop.play()
	yield(get_tree().create_timer(1.0), 'timeout')
	# wolf_boss.play()
	yield(get_tree().create_timer(2.0), 'timeout')
	info_text.text = 'Explore  towards  the  North'
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
	elif Input.is_action_just_pressed('Primary Attack') and current_stamina > 1.0:
		next_state(State.Slashing)
		process_slashing(delta)
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

	if Input.is_action_just_pressed('ui_accept') and current_stamina > 1.5:
		snowsteps.stop()
		next_state(State.Dashing)
		process_dashing(delta)
	elif not input.length() > 0.0:
		snowsteps.stop()
		next_state(State.Idle)
		process_idle(delta)
	elif Input.is_action_just_pressed('Primary Attack') and current_stamina > 1.0:
		snowsteps.stop()
		next_state(State.Slashing)
		process_slashing(delta)
	else:
		current_stamina = min(current_stamina + delta * stamina_regen * 0.25, stamina)
		input = input.normalized()
		last_direction = input
		velocity = velocity.move_toward(input * MAX_SPEED, ACCELERATION * delta)


func process_dashing(delta: float) -> void:
	if previous_state != State.Dashing:
		next_state(State.Dashing)
		current_stamina -= 1.5
		sprite.play('Dash')
		snowsteps.stop()
		dash.play()
		velocity = last_direction * DASH_SPEED

	if velocity.length() <= 0.001:
		dash.stop()
		next_state(State.Idle)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

func process_slashing(delta: float) -> void:
	if previous_state != State.Slashing:
		slashing_timer = 0.2
		next_state(State.Slashing)
		current_stamina -= 1.0
		sprite.play('Slash')
		velocity *= 0
		slash.play()

	hurt_box_collider.disabled = not sprite.frame == 2

	slashing_timer -= delta
	if slashing_timer <= 0:
		hurt_box_collider.disabled = true
		next_state(State.Idle)

func process_movement() -> void:
	velocity = move_and_slide(velocity)
	if velocity.x < 0:
		sprite.flip_h = true
		hurt_box.transform.x = -hurt_box.transform.x
	elif velocity.x > 0:
		sprite.flip_h = false
		hurt_box.transform.x = -hurt_box.transform.x

func take_damage(amount: float, from: Vector2) -> void:
	current_health -= amount
	anim_player.play('Shake')
	var back_off = (from - position).normalized() * 5.0
	position -= back_off
	if current_health <= 0.0 and not dead:
		die()

func die():
	dead = true
	next_state(State.Dead)
	sprite.stop()
	snowsteps.stop()
	dash.stop()
	$Camera2D/CanvasLayer/Control/Overlay.visible = true
	$Camera2D/CanvasLayer/Control/Overlay/AnimationPlayer.play('FadeIn')
	velocity *= 0

func process_overlap() -> void:
	pass

func update_gui() -> void:
	health_indicator.rect_size.x = current_health / health * 40
	stamina_indicator.rect_size.x = current_stamina / stamina * 40
	sun_shards_counter.text = str(sun_shards) + 'x'

func _physics_process(delta: float) -> void:
	match state:
		State.Idle: process_idle(delta)
		State.Walking: process_walking(delta)
		State.Dashing: process_dashing(delta)
		State.Slashing: process_slashing(delta)
	process_movement()
	process_overlap()
	update_gui()
	if get_tree().get_nodes_in_group('enemy').size() == 0 and state != State.Victory:
		next_state(State.Victory)
		sprite.stop()
		snowsteps.stop()
		dash.stop()
		$Camera2D/CanvasLayer/Control/Victory.visible = true
		$Camera2D/CanvasLayer/Control/Victory/AnimationPlayer.play('FadeIn')


func is_dashing() -> bool:
	return state == State.Dashing

func _on_area_entered(area: Area2D) -> void:
	if area is SunShard and not area.collected:
		area.collect()
		sun_shards_anim.play('MiniBob')
		sun_shards += 1
	elif area is HealthGlobe and not area.collected:
		area.collect()
		current_health = min(current_health + 1, health)

func _on_area_entered_hurtbox(enemy: Area2D) -> void:
	if enemy is Enemy:
		enemy.take_damage(1, position)

func _unhandled_key_input(event: InputEventKey) -> void:
	if event.pressed and event.scancode == KEY_ESCAPE:
		get_tree().quit()
	if event.pressed and event.scancode == KEY_SPACE and (state == State.Dead or state == State.Victory):
		game_state.day = 1
		get_tree().reload_current_scene()
	if event.pressed and event.scancode == KEY_SPACE and state == State.PreGame:
		game_state.day = 1
		$Camera2D/CanvasLayer/Control/Hint/AnimationPlayer.play('FadeOut')
		yield(get_tree().create_timer(1.0), 'timeout')
		next_state(State.Idle)

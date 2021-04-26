extends Area2D
class_name Enemy

var SunShard = preload('res://object/SunShard.tscn')
var HealthGlobe = preload('res://object/HealthGlobe.tscn')

onready var sprite = $AnimatedSprite
onready var enemy_anim = $AnimatedSprite/AnimationPlayer
onready var light_anim = $AnimatedSprite/Position2D/Light/AnimationPlayer
onready var take_damage_particles = $TakeDamage
onready var player_detector = $PlayerDetector
onready var life_counter = $Control/Life
onready var life_counter_width = life_counter.rect_size.x

export(float) var chase_speed = 5.0
export(float) var roam_speed = 3.0
export(float) var health = 5.0
export(float) var decision_cooldown = 3.0
var decide_in: float
var current_health: float
var chase_target = null
var random_direction = Vector2.ZERO

var loot_table = [
	'health',
	'health',
	'health',
	'sunshard'
]

enum State {
	Idle,
	Roaming,
	Chasing,
	Dying,
}
var state = State.Idle

func _ready() -> void:
	add_to_group('enemy')
	var offset = randf() * 0.5
	light_anim.play('Idle')
	light_anim.seek(offset)
	current_health = health
	decide_in = decision_cooldown
	state = State.Idle
	life_counter.visible = false
	player_detector.connect('body_entered', self, '_on_body_entered')
	player_detector.connect('body_exited', self, '_on_body_exited')
	connect('body_entered', self, '_on_player_entered')

func take_damage(amount: float, from: Vector2) -> void:
	current_health -= amount
	enemy_anim.play('TakeDamage')
	take_damage_particles.emitting = true
	var back_off = (from - position).normalized() * 5.0
	position -= back_off
	life_counter.visible = true
	life_counter.rect_size.x = (current_health / health) * life_counter_width
	if current_health <= 0.0:
		die()

func die() -> void:
	$CollisionShape2D.disabled = true
	$PlayerDetector/CollisionShape2D.disabled = true
	disconnect('body_entered', self, '_on_player_entered')
	state = State.Dying
	enemy_anim.play('Die')
	if randf() > 0.5:
		var index = round(min(randf() * (loot_table.size() - 1), loot_table.size() - 1))
		match loot_table[index]:
			'health':
				var child = HealthGlobe.instance()
				child.position = position
				get_parent().add_child(child)
			'sunshard':
				var child = SunShard.instance()
				child.position = position
				get_parent().add_child(child)
	yield(get_tree().create_timer(1.0), 'timeout')
	queue_free()

func _on_body_entered(body) -> void:
	if body.is_in_group('player'):
		chase_target = body
		state = State.Chasing

func _on_body_exited(body) -> void:
	if body.is_in_group('player'):
		chase_target = null
		state = State.Idle

func _on_player_entered(body) -> void:
	if body.is_in_group('player') and not body.is_dashing():
		body.take_damage(1, position)

func process_idle(delta: float) -> void:
	decide_in -= delta
	if decide_in <= 0:
		decide_in = decision_cooldown
		state = State.Roaming


func process_roaming(delta: float) -> void:
	if random_direction.length() == 0:
		random_direction = Vector2(
			(0.1 + randf()) * 2.0 - 1.0,
			0.3 * ((0.1 + randf()) * 2.0 - 1.0)
		)

	position += random_direction * delta * roam_speed

	var target_direction = random_direction
	if target_direction.x < 0:
		sprite.flip_h = true
		if take_damage_particles.direction.x < 0:
			take_damage_particles.direction.x = -take_damage_particles.direction.x

	elif target_direction.x > 0:
		sprite.flip_h = false
		if take_damage_particles.direction.x > 0:
			take_damage_particles.direction.x = -take_damage_particles.direction.x

	decide_in -= delta
	if decide_in <= 0:
		random_direction = Vector2.ZERO
		decide_in = decision_cooldown
		state = State.Idle


func process_chasing(delta: float) -> void:
	var target_direction = (chase_target.position - position).normalized()
	position += target_direction * delta * chase_speed
	if target_direction.x < 0:
		sprite.flip_h = true
		if take_damage_particles.direction.x < 0:
			take_damage_particles.direction.x = -take_damage_particles.direction.x

	elif target_direction.x > 0:
		sprite.flip_h = false
		if take_damage_particles.direction.x > 0:
			take_damage_particles.direction.x = -take_damage_particles.direction.x


func _process(delta: float) -> void:
	match state:
		State.Idle: process_idle(delta)
		State.Roaming: process_roaming(delta)
		State.Chasing: process_chasing(delta)

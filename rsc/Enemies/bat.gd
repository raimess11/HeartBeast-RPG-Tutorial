extends KinematicBody2D

const EnemyDeathEffect = preload("res://rsc/Effects/EnemyDeathEffect.tscn")

export var acceleration = 300
export var speed = 50
export var friction = 200

enum{
	Idle,
	Wander,
	Chase
}

var velocity = Vector2.ZERO
var knockback = Vector2.ZERO

var state = Chase

onready var sprite = $AnimatedSprite
onready var stats = $Stats
onready var PlayerDetectionZone = $PlayerDetectionZone
onready var hurtbox = $HurtBoxes
onready var softCollision = $SoftCollision
onready var wanderController = $WanderControler
onready var animationPlayer = $AnimationPlayer

func _ready() -> void:
	state = pick_random_state([Idle, Wander])

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, friction * delta)
	knockback = move_and_slide(knockback) 
	match state:
		Idle:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			seek_player()
			if wanderController.get_time_left() == 0:
				update_state()
		Wander:
			seek_player()
			if wanderController.get_time_left() == 0:
				update_state()
			update_velocity(wanderController.target_position, delta) 
			if global_position.distance_to(wanderController.target_position) <= 4:
				update_state()
		Chase:
			var player = PlayerDetectionZone.player
			if player != null:
				update_velocity(player.global_position, delta)
			else:
				state = Idle
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 400
	
	velocity = move_and_slide(velocity)

func update_velocity(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * speed, acceleration * delta)
	sprite.flip_h = velocity.x < 0
func update_state():
	state = pick_random_state([Wander, Idle])
	wanderController.start_wander_timer(rand_range(1, 3))

func seek_player():
	if PlayerDetectionZone.can_see_player():
		state = Chase

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func _on_HurtBoxes_area_entered(area):
	stats.health -= area.damage
	knockback = area.knockback_vector * 140
	hurtbox.create_hit_effect()
	hurtbox.start_invincibility(0.3)

func _on_Stats_no_health() -> void:
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position



func _on_HurtBoxes_invincibility_started() -> void:
	animationPlayer.play("start")


func _on_HurtBoxes_invincibility_ended() -> void:
	animationPlayer.play("stop")

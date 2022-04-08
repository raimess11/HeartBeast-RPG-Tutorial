extends KinematicBody2D

export var acceleration = 800
export var speed = 100
export var friction = 800
export var roll_speed = 125

enum{
	move,
	roll,
	attack
}

var state = move
var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN 
var stats = PlayerStats

const PlayerHurtSound = preload("res://rsc/Player/PlayerHurtSound.tscn")

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var swordhitbox = $HitBoxPivot/SwordHitBoxes
onready var hurtbox = $HurtBoxes
onready var blinkAnimation = $BlinkAnimation

func _ready() -> void:
	randomize()
	stats.connect("no_health", self, "queue_free")
	animationTree.active = true
	swordhitbox.knockback_vector = roll_vector

func _physics_process(delta):
	match state:
		move:
			move_state(delta)
		roll:
			roll_state(delta)
		attack:
			attack_state(delta)
	

func move_state(delta):
	
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		swordhitbox.knockback_vector = input_vector
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Attack/blend_position", input_vector)
		animationTree.set("parameters/Roll/blend_position", input_vector)
		animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * speed, acceleration * delta)
		
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	_move()
	
	if Input.is_action_just_pressed("Roll"):
		state = roll
	
	if Input.get_action_strength("Attack"):
		state = attack
	

func _move():
	velocity = move_and_slide(velocity)

func attack_state(delta):
	velocity = Vector2.ZERO
	animationState.travel("Attack")

func roll_state(delta):
	velocity = roll_vector * roll_speed
	animationState.travel("Roll")
	_move()
	

func roll_animation_finish():
	state = move

func attack_animation_finish():
	state = move

func _on_HurtBoxes_area_entered(area: Area2D) -> void:
	PlayerStats.health -= area.damage
	hurtbox.start_invincibility(0.5)
	hurtbox.create_hit_effect()
	var playerHurtSound = PlayerHurtSound.instance()
	get_tree().current_scene.add_child(playerHurtSound)



func _on_HurtBoxes_invincibility_started() -> void:
	blinkAnimation.play("start")


func _on_HurtBoxes_invincibility_ended() -> void:
	blinkAnimation.play("stop")

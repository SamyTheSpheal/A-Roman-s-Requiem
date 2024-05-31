extends CharacterBody2D

@export var WALK_SPEED = 95
@export var ACCELERATION = 1000
@export var FRICTION = 1000
@export var STAIRS_MULTIPLIER = 3
@export var KNOCKBACK_POWER = 200
@export var KNOCKBACK_RESISTANCE = 65
@export var DASH_MULTIPLIER = 2
@export var DASH_FRICTION = 500
@export var HALF_SWING_ANGLE = 100
@export var SWING_SPEED = 40
@export var ATTACK_DISTANCE = 80

@export var RUN_ANIM_SPEED = 0.5

enum StairTypes {NONE, UP_DOWN, LEFT, RIGHT}

@onready var player = get_parent().get_node("Player")
@onready var axis = Vector2.ZERO
@onready var knockback_axis = Vector2.ZERO
@onready var target_speed = 0
@onready var stair_type = StairTypes.NONE
@onready var y_bias = 0
@onready var speed_multiplier = 1
@onready var knocked_back = false
@onready var dashing = false
@onready var slashing = false
@onready var isdead = false
@onready var current_knockback_speed = 0
@onready var sword_direction = 0
@onready var sword_hitbox = $Arm
@onready var sword_collision = !$Arm/Area2D/CollisionShape2D.disabled
@onready var sword_start_rotation = 0
@onready var sword_end_rotation = 0
@onready var opacity = 1
	
func _physics_process(delta):
	if not isdead:
		move(delta)
		$Arm/Area2D/Swish.frame = 0
	if knocked_back:
		knockback(current_knockback_speed, delta)
	check_overlapping_bodies(delta)
	update_animation()

func move(delta):
	match stair_type:
		StairTypes.UP_DOWN:
			speed_multiplier = STAIRS_MULTIPLIER
		StairTypes.RIGHT:
			y_bias = 0
			speed_multiplier = STAIRS_MULTIPLIER
		StairTypes.LEFT:
			y_bias = 0
			speed_multiplier = STAIRS_MULTIPLIER
		StairTypes.NONE:
			y_bias = 0
			speed_multiplier = 1
	axis.x = 0
	axis.y = 4
		
	axis = axis.normalized()
	
	if axis == Vector2.ZERO:
		if velocity.length() > (FRICTION * delta):
			velocity -= velocity.normalized() * (FRICTION * delta)
		else:
			velocity = Vector2.ZERO
	else:
		target_speed = WALK_SPEED * speed_multiplier
		velocity += (axis * ACCELERATION * delta)
		velocity = velocity.limit_length(target_speed)
	move_and_slide()
			
func knockback(speed, delta):
	current_knockback_speed = speed
	if not knocked_back:
		knocked_back = true
		knockback_axis = -axis.normalized()
		var angle = global_position.angle_to_point(player.global_position)
		velocity += knockback_axis * current_knockback_speed * delta
		death(angle)
	else:
		current_knockback_speed -= KNOCKBACK_RESISTANCE
		velocity += knockback_axis * current_knockback_speed * delta
		if current_knockback_speed <= 0:
			knocked_back = false
	move_and_slide()
	
func death(angle):
	$Sprite2D.visible = false
	$Arm.visible = false
	$Death.visible = true
	$Death.rotation = angle
	$CollisionShape2D.disabled = true 
	$Arm/Area2D/CollisionShape2D.disabled = true
	isdead = true
	await get_tree().create_timer(1).timeout
	disappear()
	
func disappear():
	while opacity > 0:
		opacity -= .1
		modulate.a = opacity
		await get_tree().create_timer(.3,false).timeout
	queue_free()
	
func check_overlapping_bodies(delta):
	var overlapping_bodies = $Arm/Area2D.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.name == "Player":
			body.damage()
			if not body.knocked_back:
				body.knockback_entity = self
				body.knockback(KNOCKBACK_POWER, delta)

func update_animation():
	if velocity.length() != 0:
		$AnimationPlayer.play("enemy_tall_run")
		$AnimationPlayer.speed_scale = (velocity.length() / 50) * RUN_ANIM_SPEED
	else:
		$AnimationPlayer.play("enemy_tall_run")
		
func _on_stairs_right_body_entered(body):
	stair_type = StairTypes.RIGHT
func _on_stairs_left_body_entered(body):
	stair_type = StairTypes.LEFT
func _on_stairs_up_down_body_entered(body):
	stair_type = StairTypes.UP_DOWN
func _on_stairs_right_body_exited(body):
	stair_type = StairTypes.NONE
func _on_stairs_left_body_exited(body):
	stair_type = StairTypes.NONE
func _on_stairs_up_down_body_exited(body):
	stair_type = StairTypes.NONE

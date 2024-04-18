extends CharacterBody2D

@export var WALK_SPEED = 95
@export var ACCELERATION = 1000
@export var FRICTION = 1000
@export var STAIRS_MULTIPLIER = 0.75
@export var KNOCKBACK_POWER = 200
@export var KNOCKBACK_RESISTANCE = 30
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
@onready var current_knockback_speed = 0
@onready var sword_direction = 0
@onready var sword_hitbox = $Arm
@onready var sword_collision = !$Arm/Area2D/CollisionShape2D.disabled
@onready var sword_start_rotation = 0
@onready var sword_end_rotation = 0
	
func _physics_process(delta):
	if (player.global_position.distance_to(self.global_position) <= ATTACK_DISTANCE):
		slash(delta)
		dash(delta)
	else:
		move(delta)
	if knocked_back:
		knockback(current_knockback_speed, delta)
	check_overlapping_bodies(delta)
	update_animation()

func move(delta):
	match stair_type:
		StairTypes.UP_DOWN:
			speed_multiplier = STAIRS_MULTIPLIER
		StairTypes.RIGHT:
			y_bias = -sign(axis.x)
			speed_multiplier = STAIRS_MULTIPLIER
		StairTypes.LEFT:
			y_bias = sign(axis.x)
			speed_multiplier = STAIRS_MULTIPLIER
		StairTypes.NONE:
			y_bias = 0
			speed_multiplier = 1
	axis = player.get_position() - self.global_position
		
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

func dash(delta):
	if not dashing:
		axis =  player.global_position - self.global_position
		axis = axis.normalized()
		velocity += axis * WALK_SPEED * DASH_MULTIPLIER
		dashing = true
	else:
		if velocity.length() > (DASH_FRICTION * delta):
			velocity -= velocity.normalized() * (DASH_FRICTION * delta)
		else:
			velocity = Vector2.ZERO
			dashing = false
		
	move_and_slide()

func slash(delta):
	if not slashing:
		var sword_axis = get_global_mouse_position() - sword_hitbox.global_position
		sword_direction = sword_axis.angle()
		sword_start_rotation = sword_direction + deg_to_rad(-HALF_SWING_ANGLE)
		sword_end_rotation = sword_direction + deg_to_rad(HALF_SWING_ANGLE)
		sword_hitbox.rotation = sword_start_rotation
		slashing = true
		sword_collision = true
	else:
		var progress = (sword_hitbox.rotation - sword_start_rotation) / (sword_end_rotation - sword_start_rotation)
		var sine_progress = sin(progress * PI)
		var adjusted_speed = lerp(1, SWING_SPEED, sine_progress)
		sword_hitbox.rotation += deg_to_rad(adjusted_speed)
		if sword_hitbox.rotation > sword_end_rotation:
			slashing = false
			sword_collision = false
			
func knockback(speed, delta):
	current_knockback_speed = speed
	if not knocked_back:
		knocked_back = true
		knockback_axis = -axis.normalized()
		velocity += knockback_axis * current_knockback_speed * delta
	else:
		current_knockback_speed -= KNOCKBACK_RESISTANCE
		velocity += knockback_axis * current_knockback_speed * delta
		if current_knockback_speed <= 0:
			knocked_back = false
	move_and_slide()
	
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

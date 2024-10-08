extends CharacterBody2D

@export var AUTO_Y_MOVEMENT = 50
@export var HORIZONTAL_MOVEMENT = 50
@export var WALKSPEED = 100
@export var SPRINTSPEED = 1
@export var ACCELERATION = 1000
@export var FRICTION = 1000
@export var STAIRS_MULTIPLIER = 0.75
@export var DASH_MULTIPLIER = 30
@export var DASH_FRICTION = 9999
@export var HALF_SWING_ANGLE = 100
@export var SWING_SPEED = 40
@export var KNOCKBACK_POWER = 2000
@export var KNOCKBACK_RESISTANCE = 50

@export var RUN_ANIM_SPEED = 1.1

enum StairTypes {NONE, UP_DOWN, LEFT, RIGHT}

@onready var health = 100
@onready var axis = Vector2.ZERO
@onready var speed_offset = 0
@onready var target_speed = Vector2.ZERO
@onready var stair_type = StairTypes.NONE
@onready var y_bias = 0
@onready var speed_multiplier = 50
@onready var speed_multiple = 1
@onready var left_click_pressed = false
@onready var left_click_just_pressed = false
@onready var dashing = false
@onready var slashing = false
@onready var sword_direction = 0
@onready var sword_hitbox = $SwordHitbox
@onready var sword_collision = !$SwordHitbox/CollisionShape2D.disabled
@onready var sword_start_rotation = 0
@onready var sword_end_rotation = 0
@onready var dead = false
@onready var knockback_entity = null
@onready var knocked_back = false
@onready var knockback_axis = Vector2.ZERO
@onready var current_knockback_speed = 0
@onready var knockback_velocity = Vector2.ZERO

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				left_click_pressed = true
				left_click_just_pressed = true
			else:
				left_click_pressed = false
				left_click_just_pressed = false
				
func update_just_pressed():
	if left_click_just_pressed:
		left_click_just_pressed = false

func _ready():
	sword_collision = false
	
func _physics_process(delta):
	if not dead:
		if left_click_just_pressed or slashing:
			slash(delta)
		if left_click_just_pressed or dashing:
			dash(delta)
		if not dashing:
			move(delta)
		if knocked_back:
			knockback(current_knockback_speed, delta)
		update_just_pressed()
		check_overlapping_bodies(delta)
		update_animation()
	elif dead:
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	update_speed_bar()

func death():
	dead = true
	
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
			
	axis.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	axis.y = y_bias + int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
		
	axis = axis.normalized()
	
	if axis.y == 0:
		velocity.y = -AUTO_Y_MOVEMENT * speed_multiplier

	if axis == Vector2.ZERO:
		if velocity.length() > AUTO_Y_MOVEMENT:
			velocity -= velocity.normalized() * (FRICTION * delta)
		else:
			velocity.x = 0
	else:
		if (Input.is_key_pressed(KEY_SHIFT)):
			speed_offset = SPRINTSPEED * speed_multiple
		else:
			speed_offset = WALKSPEED * speed_multiple
		target_speed = Vector2(sign(axis.x) * (HORIZONTAL_MOVEMENT + speed_offset), -AUTO_Y_MOVEMENT + (sign(axis.y) * speed_offset))
		velocity = target_speed
		velocity = velocity.limit_length(max(HORIZONTAL_MOVEMENT, AUTO_Y_MOVEMENT * speed_multiplier * .75) + speed_offset)

	move_and_slide()

func dash(delta):
	if not dashing:
		axis = get_global_mouse_position() - self.global_position
		axis = axis.normalized()
		velocity += axis * speed_offset
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
		velocity += axis * speed_offset * speed_multiplier * DASH_MULTIPLIER
		$SwordHitbox/Swish.frame = 1
	else:
		var progress = (sword_hitbox.rotation - sword_start_rotation) / (sword_end_rotation - sword_start_rotation)
		var sine_progress = sin(progress * PI)
		var adjusted_speed = lerp(1, SWING_SPEED, sine_progress)
		sword_hitbox.rotation += deg_to_rad(adjusted_speed)
		
		# Update frame based on the progress
		if progress > 0.2 and progress <= 0.8:
			$SwordHitbox/Swish.frame = 2
		else:
			$SwordHitbox/Swish.frame = 1
			
		if sword_hitbox.rotation > sword_end_rotation:
			slashing = false
			sword_collision = false
			$SwordHitbox/Swish.frame = 0
			
			

func damage():
	speed_multiple -= 1
	damage_flicker()
	
func enemy_hit():
	speed_multiple += 1
	
func update_speed_bar():
	$ProgressBar.value = speed_multiple
	
func damage_flicker():
	modulate.a = .2
	await get_tree().create_timer(.3,false).timeout
	modulate.a = 1
	await get_tree().create_timer(.3,false).timeout
	modulate.a = .2
	await get_tree().create_timer(.3,false).timeout
	modulate.a = 1

func knockback(speed, delta):
	if not knocked_back:
		current_knockback_speed = speed
		knocked_back = true
		knockback_axis = -(knockback_entity.global_position - self.global_position).normalized()
		velocity += knockback_axis * current_knockback_speed
	else:
		current_knockback_speed -= KNOCKBACK_RESISTANCE
		velocity = knockback_axis * current_knockback_speed
		if current_knockback_speed <= 0:
			knocked_back = false
	move_and_slide()
	
func check_overlapping_bodies(delta):
	var overlapping_bodies = $SwordHitbox.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("enemy") and sword_collision:
			enemy_hit()
			body.knockback(KNOCKBACK_POWER, delta)
			
func update_animation():
	if velocity.length() != 0:
		$AnimationPlayer.play("peter_run")
		$AnimationPlayer.speed_scale = (velocity.length() / 50) * RUN_ANIM_SPEED
	else:
		$AnimationPlayer.play("peter_idle")
	
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


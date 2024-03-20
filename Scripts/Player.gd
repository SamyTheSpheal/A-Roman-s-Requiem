extends CharacterBody2D

@export var AUTO_Y_MOVEMENT = 50
@export var HORIZONTAL_MOVEMENT = 50
@export var WALKSPEED = 10
@export var SPRINTSPEED = 25
@export var ACCELERATION = 1000
@export var FRICTION = 1000
@export var STAIRS_MULTIPLIER = 0.75
@export var DASH_MULTIPLIER = 1.5
@export var DASH_FRICTION = 400
@export var HALF_SWING_ANGLE = 100
@export var SWING_SPEED = 40
@export var KNOCKBACK_POWER = 400
@export var KNOCKBACK_RESISTANCE = 500

@export var RUN_ANIM_SPEED = 1.1

enum StairTypes {NONE, UP_DOWN, LEFT, RIGHT}

@onready var health = 100
@onready var axis = Vector2.ZERO
@onready var speed_offset = 0
@onready var target_speed = Vector2.ZERO
@onready var stair_type = StairTypes.NONE
@onready var y_bias = 0
@onready var speed_multiplier = 1
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
@onready var knocked_back = false
@onready var knockback_axis = Vector2.ZERO
@onready var current_knockback_speed = 0

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
		if left_click_just_pressed or dashing:
			dash(delta)
		if left_click_just_pressed or slashing:
			slash(delta)
		if not dashing:
			move(delta)
		if knocked_back:
			knockback(current_knockback_speed, delta)
		update_just_pressed()
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
			
	axis.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	axis.y = y_bias + int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
		
	axis = axis.normalized()
	
	if axis.y == 0:
		velocity.y = -AUTO_Y_MOVEMENT

	if axis == Vector2.ZERO:
		if velocity.length() > AUTO_Y_MOVEMENT:
			velocity -= velocity.normalized() * (FRICTION * delta)
		else:
			velocity.x = 0
	else:
		if (Input.is_key_pressed(KEY_SHIFT)):
			speed_offset = SPRINTSPEED * speed_multiplier
		else:
			speed_offset = WALKSPEED * speed_multiplier
		target_speed = Vector2(sign(axis.x) * (HORIZONTAL_MOVEMENT + speed_offset), -AUTO_Y_MOVEMENT + (sign(axis.y) * speed_offset))
		velocity = target_speed
		velocity = velocity.limit_length(max(HORIZONTAL_MOVEMENT, AUTO_Y_MOVEMENT) + speed_offset)

	move_and_slide()

func dash(delta):
	if not dashing:
		axis = get_global_mouse_position() - self.global_position
		axis = axis.normalized()
		velocity += axis * speed_offset * DASH_MULTIPLIER
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

func damage():
	health -= 1
	set_health_bar(health)

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
	var overlapping_bodies = $SwordHitbox.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.name == "Enemy" and sword_collision:
			body.knockback(KNOCKBACK_POWER, delta)
			print("e")
			
func set_health_bar(value):
	$ProgressBar.value = value

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


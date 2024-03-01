extends CharacterBody2D

@export var WALKSPEED = 65
@export var SPRINTSPEED = 265
@export var ACCELERATION = 1000
@export var FRICTION = 1000
@export var STAIRS_MULTIPLIER = 0.75
@export var DASH_MULTIPLIER = 1.5
@export var DASH_FRICTION = 400

enum StairTypes {NONE, UP_DOWN, LEFT, RIGHT}

@onready var axis = Vector2.ZERO
@onready var target_speed = 0
@onready var stair_type = StairTypes.NONE
@onready var y_bias = 0
@onready var speed_multiplier = 1
@onready var left_click_pressed = false
@onready var left_click_just_pressed = false
@onready var slashing = false

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
	
func _physics_process(delta):
	if left_click_just_pressed or slashing:
		slash(delta)
	else:
		move(delta)
	update_just_pressed()
	
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
	
	if axis == Vector2.ZERO:
		if velocity.length() > (FRICTION * delta):
			velocity -= velocity.normalized() * (FRICTION * delta)
		else:
			velocity = Vector2.ZERO
	else:
		if (Input.is_key_pressed(KEY_SHIFT)):
			target_speed = SPRINTSPEED * speed_multiplier
		else:
			target_speed = WALKSPEED * speed_multiplier
		velocity += (axis * ACCELERATION * delta)
		velocity = velocity.limit_length(target_speed)
	
	if velocity.x < 0:
		$Sprite2D.scale.x = -abs($Sprite2D.scale.x)
	elif velocity.x > 0:
		$Sprite2D.scale.x = abs($Sprite2D.scale.x)
		
	move_and_slide()
	
func slash(delta):
	if not slashing:
		axis = get_global_mouse_position() - self.global_position
		axis = axis.normalized()
		velocity += axis * target_speed * DASH_MULTIPLIER
		slashing = true
	else:
		if velocity.length() > (DASH_FRICTION * delta):
			velocity -= velocity.normalized() * (DASH_FRICTION * delta)
		else:
			velocity = Vector2.ZERO
			slashing = false
		
	move_and_slide()
	
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


func _on_mc_death_body_entered(body):
	print("ded")

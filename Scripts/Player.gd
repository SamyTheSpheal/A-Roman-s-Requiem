extends CharacterBody2D

@export var WALKSPEED = 75
@export var SPRINTSPEED = 105
@export var ACCELERATION = 1000
@export var FRICTION = 1000
@export var STAIRSMULTIPLIER= 0.75

enum StairTypes {NONE, UP_DOWN, LEFT, RIGHT}

@onready var axis = Vector2.ZERO
@onready var target_speed = 0
@onready var stair_type = StairTypes.NONE
@onready var y_bias = 0
@onready var speed_multiplier = 1

func _physics_process(delta):
	move(delta)


func move(delta):
	match stair_type:
		StairTypes.RIGHT:
			y_bias = -sign(axis.x)
			speed_multiplier = STAIRSMULTIPLIER
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
	
	move_and_slide()

func _on_stairs_right_body_entered(body):
	pass # Replace with function body.
	stair_type = StairTypes.RIGHT
func _on_stairs_right_body_exited(body):
	stair_type = StairTypes.NONE

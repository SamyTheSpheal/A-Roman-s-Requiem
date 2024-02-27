extends CharacterBody2D

@export var SPEED = 95
@export var ACCELERATION = 1000
@export var FRICTION = 1000

@onready var axis = Vector2.ZERO

func _physics_process(delta):
	move(delta)
	
func move(delta):
	axis.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	axis.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	axis = axis.normalized()
	
	if axis == Vector2.ZERO:
		if velocity.length() > (FRICTION * delta):
			velocity -= velocity.normalized() * (FRICTION * delta)
		else:
			velocity = Vector2.ZERO
	else:
		velocity += (axis * ACCELERATION * delta)
		velocity = velocity.limit_length(SPEED)
	
	move_and_slide()

extends CharacterBody2D

@export var WALK_SPEED = 265
@export var ACCELERATION = 1000
@export var FRICTION = 1000
@export var STAIRS_MULTIPLIER = 0.75

enum StairTypes {NONE, UP_DOWN, LEFT, RIGHT}

@onready var player = get_parent().get_node("Player")
@onready var axis = Vector2.ZERO
@onready var target_speed = 0
@onready var sword_rotation = 0
@onready var swing = 0
@onready var swinging = false
@onready var stair_type = StairTypes.NONE
@onready var y_bias = 0
@onready var speed_multiplier = 1

func _physics_process(delta):
	move(delta)
	swing_sword(delta)
	update_sword(delta)

func swing_sword(delta):
	var direction_axis = (player.get_position() - self.global_position)
	if direction_axis.length() < 130:
		if not swinging:
			swing = -120
			swinging = true
		else:
			swing += RandomNumberGenerator.new().randi_range(14,25)
			if swing > 120:
				swinging = false
	else:
		swing = 0
	
func update_sword(delta):
	sword_rotation = atan2(axis.y, axis.x) + deg_to_rad(45 + swing)
	$Sword.rotation = sword_rotation
	
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
	
	if velocity.x < 0:
		$Sprite2D.scale.x = -abs($Sprite2D.scale.x)
	elif velocity.x > 0:
		$Sprite2D.scale.x = abs($Sprite2D.scale.x)
	
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

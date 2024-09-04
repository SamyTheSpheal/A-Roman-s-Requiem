extends CharacterBody2D	

@export var DEFAULT_AUTO_Y_MOVEMENT = 100
@export var DEFAULT_X_MOVEMENT = 40
@export var DASH_ACCELERATION = 1000
@export var DASH_FRICTION = 1000
@export var RUN_ANIM_SPEED = 1.2

@onready var velocity_modifier = 1
@onready var velocity_capped = false
@onready var dead = false
@onready var slashing = false

func _input_horizontal():
	var input_angle = Input.get_axis("left","right")
	velocity.x = input_angle * DEFAULT_X_MOVEMENT

func _ready():
	pass # Replace with function body.
	
func death():
	dead = true
	
func vcap():
	velocity_capped = true
	velocity_modifier = 1
	
func update_animation():
	if velocity.length() != 0:
		$AnimationPlayer.play("peter_run")
		$AnimationPlayer.speed_scale = (velocity.length() / 50) * RUN_ANIM_SPEED
	else:
		$AnimationPlayer.play("peter_idle")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if not velocity_capped:
		velocity_modifier += .01
	if not dead:
		if not slashing:
			_input_horizontal()
			velocity.y = -DEFAULT_AUTO_Y_MOVEMENT * velocity_modifier
			update_animation()
			move_and_slide()
		elif dead:
			get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

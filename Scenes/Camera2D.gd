extends Camera2D

@export var CAMERA_SPEED = 50

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move_camera(delta)
	
func move_camera(delta):
	position.y -= CAMERA_SPEED * delta

func _physics_process(delta):
	var overlapping_bodies = $Area2D.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.name == "Player":
			body.damage()

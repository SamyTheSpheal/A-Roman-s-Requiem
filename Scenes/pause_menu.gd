extends Control

var pause_menu_path : String

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if not get_tree().paused:
			get_tree().paused = true
			visible = true
		else:
			get_tree().paused = false
			visible = false



func _on_resume_pressed():
	get_tree().paused = false
	visible = false
	
func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_quit_pressed():
	get_tree().quit()

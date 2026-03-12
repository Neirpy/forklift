extends Node3D

func _input(event):
	# Retour au menu
	if event.is_action_pressed("back_to_menu"):
		get_tree().change_scene_to_file("res://mainMenu.tscn")

extends Node3D

@onready var label: Label = $forklift/Hud/Label
@onready var forklift: BaseCar = $forklift

func _input(event):
	# Retour au menu
	if event.is_action_pressed("back_to_menu"):
		get_tree().change_scene_to_file("res://mainMenu.tscn")


func _on_area_parcours_body_entered(_body: Node3D) -> void:
	var current_medal = ""
	# On détermine la médaille selon la couleur du label
	if label.label_settings.font_color == Color.GOLD:
		current_medal = "Or 🥇"
	elif label.label_settings.font_color == Color.SILVER:
		current_medal = "Argent 🥈"
	else:
		current_medal = "Bronze 🥉"
	
	# ON SAUVEGARDE DANS LE SINGLETON avant de changer de scène
	# On identifie le niveau par son nom de fichier
	var level_id = get_tree().current_scene.scene_file_path.get_file().get_basename()
	GameManager.save_medal(level_id, current_medal)
	
	get_tree().change_scene_to_file("res://mainMenu.tscn")

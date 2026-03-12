extends Node3D

@onready var label: Label = $forklift/Hud/Label
@onready var area_parcours: Area3D = $AreaParcours
@onready var area_palette: Area3D = $AreaPalette1

# Liste pour stocker les palettes actuellement dans la zone
var pallets_in_area = []
var check_pallets : bool = false

func _ready():
	area_parcours.hide()
	
	# Connexion directe de l'unique zone
	area_palette.body_entered.connect(_on_area_palette_body_entered)
	area_palette.body_exited.connect(_on_area_palette_body_exited)

func _on_area_palette_body_entered(body: Node3D):
	# On vérifie si l'objet qui entre est une palette (via son groupe)
	if body.is_in_group("palettes"):
		if not body in pallets_in_area:
			pallets_in_area.append(body)
			check_victory()

func _on_area_palette_body_exited(body: Node3D):
	if body in pallets_in_area:
		pallets_in_area.erase(body)
		check_victory()

func check_victory():
	# Condition simple : Est-ce qu'il y a 2 palettes (ou plus) dans la liste ?
	if pallets_in_area.size() >= 2:
		check_pallets = true
		area_parcours.show()
	else:
		check_pallets = false
		area_parcours.hide()

func _on_area_parcours_body_entered(_body: Node3D) -> void:
	# On vérifie que c'est le forklift qui touche la zone de fin
	if check_pallets and _body.name == "forklift": 
		save_and_exit()

func save_and_exit():
	var current_medal = "🥉"
	if label.label_settings.font_color == Color.GOLD:
		current_medal = "🥇"
	elif label.label_settings.font_color == Color.SILVER:
		current_medal = "🥈"
	
	var level_id = get_tree().current_scene.scene_file_path.get_file().get_basename()
	GameManager.save_medal(level_id, current_medal)
	get_tree().change_scene_to_file("res://mainMenu.tscn")

func _input(event):
	if event.is_action_pressed("back_to_menu"):
		get_tree().change_scene_to_file("res://mainMenu.tscn")

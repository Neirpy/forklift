extends Node3D

@onready var label: Label = $forklift/Hud/Label
@onready var area_parcours: Area3D = $AreaParcours

var occupation = {} # Clé: Area3D, Valeur: Array de corps présents
var check_pallets : bool = false

func _input(event):
	# Retour au menu
	if event.is_action_pressed("back_to_menu"):
		get_tree().change_scene_to_file("res://mainMenu.tscn")
		
func _ready():
	area_parcours.hide() # On cache la zone de fin au départ
	for i in range(1, 5):
		var area_path = "AreaPalette" + str(i)
		if has_node(area_path):
			var area = get_node(area_path)
			occupation[area] = []
			# On connecte en passant l'area en paramètre supplémentaire via bind
			area.body_entered.connect(_on_area_entered.bind(area))
			area.body_exited.connect(_on_area_exited.bind(area))

func _on_area_entered(body: Node3D, area: Area3D):
	if body is RigidBody3D:
		if not body in occupation[area]:
			occupation[area].append(body)
			check_victory()

func _on_area_exited(body: Node3D, area: Area3D):
	if body in occupation[area]:
		occupation[area].erase(body)
		check_victory() # Important de vérifier aussi quand on sort !

func check_victory():
	var zones_occupees = 0
	
	for area in occupation:
		if occupation[area].size() > 0:
			zones_occupees += 1
	
	# On gagne si les 4 zones ont au moins un objet
	if zones_occupees == 4:
		check_pallets = true
		area_parcours.show()
	else:
		check_pallets = false
		area_parcours.hide()

func _on_area_parcours_body_entered(_body: Node3D) -> void:
	# On vérifie si c'est bien le joueur (forklift) qui entre dans la zone de fin
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

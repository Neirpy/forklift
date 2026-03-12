extends Node3D

# Chemins vers les scènes
const SCENE_1 = "res://scenes/main1.tscn"
const SCENE_2 = "res://scenes/main2.tscn"
const SCENE_3 = "res://scenes/main3.tscn"

@onready var victory: AudioStreamPlayer = $Victory

@onready var medaille_1: Label = $forklift/Hud/Medaille1
@onready var medaille_2: Label = $forklift/Hud/Medaille2
@onready var medaille_3: Label = $forklift/Hud/Medaille3

@onready var affichage_score: Label3D = $"AffichageScore"

func _ready():
	# Connexion des signaux
	$AreaMenuLvl1.body_entered.connect(_on_body_entered.bind(SCENE_1))
	$AreaMenuLvl2.body_entered.connect(_on_body_entered.bind(SCENE_2))
	$AreaMenuLvl3.body_entered.connect(_on_body_entered.bind(SCENE_3))
	
	# Mise à jour de l'affichage avec les données persistantes
	actualiser_affichage_medailles()

func actualiser_affichage_medailles():
	# On va chercher les emojis stockés dans le GameManager
	var m1 = GameManager.medals["main1"]
	var m2 = GameManager.medals["main2"]
	var m3 = GameManager.medals["main3"]
	
	affichage_score.text = "Niveau 1: " + m1 + "\nNiveau 2: " + m2 + "\nNiveau 3: " + m3
	
	if m1 == "🥇" and m2 == "🥇" and m3 == "🥇":
		victory.play()
		affichage_score.text += "\n Bravo tu as obtenu toutes les médailles, \n Tu maitrises le chariot comme personne !"

func _on_body_entered(body, scene_path: String):
	# On vérifie si l'objet qui entre est bien le chariot
	if body is BaseCar:
		get_tree().change_scene_to_file(scene_path)

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

# 2. On met à jour l'affichage dès que le menu est prêt
	actualiser_affichage()

func actualiser_affichage():
	# On récupère les emojis stockés dans le GameManager
	# Si c'est vide, on peut mettre un texte par défaut comme "---"
	var m1 = GameManager.medals["main1"] if GameManager.medals["main1"] != "" else "❌"
	var m2 = GameManager.medals["main2"] if GameManager.medals["main2"] != "" else "❌"
	var m3 = GameManager.medals["main3"] if GameManager.medals["main3"] != "" else "❌"
	
	# Mise à jour du panneau 3D
	affichage_score.text = "MES MÉDAILLES : \n\nLvl 1 : " + m1 + "\nLvl 2 : " + m2 + "\nLvl 3 : " + m3
	if m1 == "Or 🥇" and m2 == "Or 🥇" and m3 == "Or 🥇":
		victory.play()
		affichage_score.text += "\n Bravo tu as obtenu toutes les médailles, \n Tu maitrises le chariot comme personne !"

func _on_body_entered(body, scene_path: String):
	# On vérifie si l'objet qui entre est bien le chariot
	if body is BaseCar:
		get_tree().change_scene_to_file(scene_path)

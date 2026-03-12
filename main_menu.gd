extends Node3D

# Chemins vers les scènes
const SCENE_1 = "res://scenes/main1.tscn"
const SCENE_2 = "res://scenes/main2.tscn"
const SCENE_3 = "res://scenes/main3.tscn"

@onready var medailles: Label = $forklift/Hud/Medailles
@onready var affichage_score: Label3D = $"AffichageScore"


func _ready():
	# Connexion des signaux pour les Area3D
	$AreaMenuLvl1.body_entered.connect(_on_body_entered.bind(SCENE_1))
	$AreaMenuLvl2.body_entered.connect(_on_body_entered.bind(SCENE_2))
	$AreaMenuLvl3.body_entered.connect(_on_body_entered.bind(SCENE_3))
	affichage_score.text = medailles.text

func _on_body_entered(body, scene_path: String):
	# On vérifie si l'objet qui entre est bien le chariot
	if body is BaseCar:
		get_tree().change_scene_to_file(scene_path)

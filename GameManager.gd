extends Node

const SAVE_PATH = "user://save_medals.json"

var medals = {
	"main1": "",
	"main2": "",
	"main3": ""
}

func _ready():
	load_game() # On charge les médailles dès le lancement du jeu

# Fonction pour enregistrer une médaille
func save_medal(level_name: String, medal_emoji: String):
	medals[level_name] = medal_emoji
	save_game() # On sauvegarde immédiatement sur le "disque" virtuel

# --- LOGIQUE DE SAUVEGARDE ---

func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(medals)
		file.store_string(json_string)
		file.close()
		# Très important pour le web : force la synchronisation
		print("Sauvegarde réussie dans IndexedDB")

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return # Pas encore de sauvegarde
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var data = JSON.parse_string(content)
		if data is Dictionary:
			medals = data
			print("Données chargées : ", medals)
		file.close()

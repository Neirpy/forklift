extends Node

# On stocke les médailles ici pour qu'elles survivent aux changements de scènes
var medals = {
	"main1": "",
	"main2": "",
	"main3": ""
}

# Fonction pour enregistrer une médaille si elle est meilleure que la précédente
func save_medal(level_name: String, medal_emoji: String):
	# On peut ajouter une logique ici : l'or écrase l'argent, etc.
	medals[level_name] = medal_emoji

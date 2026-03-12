extends VehicleBody3D
class_name BaseCar

#emoji médailles 
# 🥇 🥈 🥉

var liste_medals_act : Array[String] = []

@onready var consigne: Label = $Hud/Consigne
var consigne_text : Array[String] = [
	"Regarde autour de toi, \n il faut que tu ailles dans la zone d'arrivée \n le plus rapidement possible. \n Appuie sur accélérer pour commencer.",
	"Déplacer les 4 palettes (boutons Y et A)\nsur les 4 emplacements (jaunes)\nle plus rapidement possible.\nUne fois les palettes déplacées,\nil faut aller dans la zone verte.",
	"Déplacer les 2 palettes à\nla zone de dépôt indiquée\nen traversant le parcours.\nUne fois les palettes déplacées,\nil faut aller dans la zone verte."
]

@onready var car: BaseCar = $"."
@onready var fourche: MeshInstance3D = $Mat/Fourche
@onready var mat: MeshInstance3D = $Mat
@onready var volant: MeshInstance3D = $fokrlift/Volant

@onready var wait_consigne: Timer = $WaitConsigne

#camera
@export var controller_sensitivity: float = 3.0
@export var tilt_upper_limit: float = deg_to_rad(80)
@export var tilt_lower_limit: float = deg_to_rad(-80)

@onready var speed_label: Label = $Hud/speed
@onready var label: Label = $Hud/Label
var init_position : Vector3
var init_transform : Transform3D

# --- VALEURS AJUSTÉES POUR CHARIOT ---
@export var STEER_SPEED = 2.0      # Plus réactif pour un petit chariot
@export var STEER_LIMIT = 0.5      # Évite de se retourner
@export var engine_force_value = 40.0 # Augmenté pour bouger la masse
@export var MAX_SPEED_KMH = 20.0    # limite de 20 km/h
#Basis (l'orientation) de départ du volant
var volant_basis_initiale : Basis

var speed_kmH : float
var steer_target = 0

var min_height_fork : float = -0.1
var max_height_fork : float = 1.70

var min_angle_mat : float = -0.18
var max_angle_mat :float = 0.0

var time_elapsed: float = 0.0
var is_timer_active: bool = false

var path
var nom_fich

var start_act : bool = false
var wait_act : bool = false
var can_drive : bool = false

func _ready():
	init_transform = car.global_transform
	path = get_tree().current_scene.scene_file_path
	nom_fich = path.get_file().get_basename()
	volant_basis_initiale = volant.transform.basis
	if nom_fich == "main1":
		consigne.text = consigne_text[0]
		wait_consigne.start()
		can_drive = false
	if nom_fich == "main2":
		consigne.text = consigne_text[1]
		wait_consigne.start()
		can_drive = false
	if nom_fich == "main3":
		consigne.text = consigne_text[2]
		wait_consigne.start()
		can_drive = false


# Nouvelle fonction pour gérer les seuils de médailles
func update_label_color(gold: int, silver: int):
	if time_elapsed < gold:
		label.label_settings.font_color = Color.GOLD
	elif time_elapsed < silver:
		label.label_settings.font_color = Color.SILVER
	else:
		label.label_settings.font_color = Color.SADDLE_BROWN # Bronze

func _physics_process(delta):
	if nom_fich != "mainMenu" and wait_act:
		if start_act:
			consigne.hide()
			wait_act = false
			is_timer_active = true
			label.label_settings.font_color = Color.GOLD
	elif nom_fich == "mainMenu" :
		can_drive = true
	
	# Calcul propre de la vitesse en Km/h
	speed_kmH = linear_velocity.length() * 3.6
	
	handle_camera_look(delta)
	process_tilt(delta)
	process_fork(delta)
	process_accel(delta)
	process_steer(delta)
	process_brake(delta)
	traction(linear_velocity.length()) # Utilise m/s pour la force vers le bas
	
	speed_label.text = str(round(speed_kmH)) + " Km/h"
	
	var silver_timer : int = 0
	var gold_timer : int = 0
	
	if is_timer_active:
		time_elapsed += delta
		label.text = format_time(time_elapsed)
		if nom_fich == "main1":
			silver_timer = 45 # 45 sec.
			gold_timer = 30 # 30 sec
		elif nom_fich == "main2":
			silver_timer = 330 # 5 min. 30 sec.
			gold_timer = 250 # 4 min. 10 sec.
		elif nom_fich == "main3":
			silver_timer = 180 # 3 min.
			gold_timer = 150 # 2 min. 30 sec.
		update_label_color(gold_timer, silver_timer)
		

func handle_camera_look(delta: float):
	# Récupérer les deux axes du stick droit d'un coup
	var look_vector = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	
	if look_vector.length() > 0:
		# 1. Rotation Horizontale (Pivot)
		# On utilise delta pour que la vitesse soit la même peu importe les FPS
		$Camera3D.rotate_y(-look_vector.x * controller_sensitivity * delta)
		
		# 2. Rotation Verticale (Camera)
		var new_tilt = $Camera3D.rotation.x - (look_vector.y * controller_sensitivity * delta)
		
		# On limite l'angle pour éviter le tournis
		$Camera3D.rotation.x = clamp(new_tilt, tilt_lower_limit, tilt_upper_limit)

func process_tilt(delta):
	if Input.is_action_pressed("tilt_in"):
		mat.rotation.x += .1 * delta
		mat.rotation.x = clampf(mat.rotation.x, min_angle_mat, max_angle_mat)
	if Input.is_action_pressed("tilt_out"):
		mat.rotation.x -= .1 * delta
		mat.rotation.x = clampf(mat.rotation.x, min_angle_mat, max_angle_mat)

func process_fork(delta):
	if Input.is_action_pressed("fork_up"):
		fourche.position.y += .25 * delta
		fourche.position.y = clampf(fourche.position.y, min_height_fork, max_height_fork)
	if Input.is_action_pressed("fork_down"):
		fourche.position.y -= .25 * delta
		fourche.position.y = clampf(fourche.position.y, min_height_fork, max_height_fork)

func process_accel(_delta):
	var forward_input = Input.is_action_pressed("forward")
	var backward_input = Input.is_action_pressed("backward")
	
	
	# LIMITEUR DE VITESSE
	if speed_kmH >= MAX_SPEED_KMH and forward_input:
		engine_force = 0
		return

	if speed_kmH >= 10 and backward_input:
		engine_force = 0
		return

	if forward_input and can_drive:
		# Couple électrique : Puissance constante jusqu'à la limite
		start_act = true
		engine_force = -engine_force_value /3
		return
		
	if backward_input and can_drive:
		# Marche arrière souvent plus lente sur un chariot
		engine_force = engine_force_value /4
		return

	engine_force = 0

func process_brake(_delta):
	if Input.is_action_pressed("break"):
		brake = 3.0 # Un chariot s'arrête vite
	else:
		# Frein moteur léger (typiquement électrique)
		brake = 0.1 

func process_steer(delta):
	steer_target = Input.get_action_strength("right") - Input.get_action_strength("left")
	steer_target *= STEER_LIMIT
	steering = move_toward(steering, steer_target, STEER_SPEED * delta)
	
	# --- LOGIQUE DU VOLANT EN BASIS ---
	# 1. On calcule l'angle voulu (180° max)
	var angle_volant = -(steering / STEER_LIMIT) * PI

	# 2. On définit l'axe local Y du volant
	# (On prend le Y de la basis initiale pour qu'il tourne bien sur son axe "propre")
	var axe_local_y = volant_basis_initiale.y.normalized()

	# 3. On applique la rotation à partir de la basis initiale
	# On repart de l'inclinaison d'origine et on applique la rotation locale
	volant.transform.basis = volant_basis_initiale.rotated(axe_local_y, angle_volant)

func traction(speed_ms):
	# Plaque le chariot au sol proportionnellement à sa vitesse
	apply_central_force(Vector3.DOWN * speed_ms * 10.0)

func _input(event):
	if event.is_action_pressed("reset"):
		# Correction du reset pour éviter les comportements bizarres
		global_transform = init_transform
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO

func _on_area_detect_palette_body_entered(body: Node3D) -> void:
# On vérifie si le nom du body contient "pallet" (en minuscules pour éviter les erreurs)
	if body.name.to_lower().contains("pallet"):
		print("Palette détectée : ", body.name)
		# Ajoute ici ton code pour "attacher" la palette ou la soulever
	else:
		print("Objet ignoré : ", body.name)

func _on_area_detect_palette_body_exited(body: Node3D) -> void:
	if body.name.to_lower().contains("pallet"):
		print("Palette déposée : ", body.name)
		# Ajoute ici ton code pour "attacher" la palette ou la soulever
	else:
		print("Objet déposé : ", body.name)
	pass # Replace with function body.

# Fonction pour transformer des secondes en format 00:00:00
func format_time(time: float) -> String:
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	# %02d permet de forcer l'affichage de 2 chiffres (ex: 01 au lieu de 1)
	return "%02d:%02d:%02d" % [minutes, seconds, milliseconds]

# Pour arrêter le chrono quand on a fini une mission
func stop_timer():
	is_timer_active = false

func _on_wait_consigne_timeout() -> void:
	wait_act = true
	can_drive = true
	pass # Replace with function body.

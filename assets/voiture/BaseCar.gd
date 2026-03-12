extends VehicleBody3D
class_name BaseCar

@onready var car: BaseCar = $"."
@onready var fourche: MeshInstance3D = $Mat/Fourche
@onready var mat: MeshInstance3D = $Mat
@onready var volant: MeshInstance3D = $fokrlift/Volant

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

var speed_kmH : float
var steer_target = 0

var min_height_fork : float = -0.1
var max_height_fork : float = 1.70

var min_angle_mat : float = -0.18
var max_angle_mat :float = 0.0

func _ready():
	init_transform = car.global_transform

func _physics_process(delta):
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
	label.text = "Chariot Électrique"

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

	if forward_input:
		# Couple électrique : Puissance constante jusqu'à la limite
		engine_force = -engine_force_value /3
		return
		
	if backward_input:
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
		print("Palette déposé : ", body.name)
		# Ajoute ici ton code pour "attacher" la palette ou la soulever
	else:
		print("Objet déposé : ", body.name)
	pass # Replace with function body.

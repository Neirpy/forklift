extends VehicleBody3D
class_name BaseCar

@onready var car: BaseCar = $"."
@onready var fourche: MeshInstance3D = $Mat/Fourche
@onready var mat: MeshInstance3D = $Mat
@onready var volant: MeshInstance3D = $fokrlift/Volant

@onready var speed_label: Label = $Hud/speed
@onready var label: Label = $Hud/Label
var init_position : Vector3
var init_transform : Transform3D

# --- VALEURS AJUSTÉES POUR CHARIOT ---
@export var STEER_SPEED = 2.0      # Plus réactif pour un petit chariot
@export var STEER_LIMIT = 0.5      # Évite de se retourner
@export var engine_force_value = 40.0 # Augmenté pour bouger la masse
@export var MAX_SPEED_KMH = 25.0    # Ta limite de 25 km/h

var speed_kmH : float
var steer_target = 0

var min_height_fork : float = 0.0
var max_height_fork : float = 1.70

var min_angle_mat : float = -0.18
var max_angle_mat :float = 0.0

func _ready():
	init_transform = car.global_transform

func _physics_process(delta):
	if Input.is_action_pressed("fork_up"):
		fourche.position.y += .25 * delta
		fourche.position.y = clampf(fourche.position.y, min_height_fork, max_height_fork)
	if Input.is_action_pressed("fork_down"):
		fourche.position.y -= .25 * delta
		fourche.position.y = clampf(fourche.position.y, min_height_fork, max_height_fork)
	if Input.is_action_pressed("tilt_in"):
		mat.rotation.x += .1 * delta
		mat.rotation.x = clampf(mat.rotation.x, min_angle_mat, max_angle_mat)
	if Input.is_action_pressed("tilt_out"):
		mat.rotation.x -= .1 * delta
		mat.rotation.x = clampf(mat.rotation.x, min_angle_mat, max_angle_mat)
	
	# Calcul propre de la vitesse en Km/h
	speed_kmH = linear_velocity.length() * 3.6
	
	process_accel(delta)
	process_steer(delta)
	process_brake(delta)
	traction(linear_velocity.length()) # Utilise m/s pour la force vers le bas
	
	speed_label.text = str(round(speed_kmH)) + " Km/h"
	label.text = "Chariot Électrique"

func process_accel(_delta):
	var forward_input = Input.is_action_pressed("forward")
	var backward_input = Input.is_action_pressed("backward")
	
	# LIMITEUR DE VITESSE
	if speed_kmH >= MAX_SPEED_KMH and forward_input:
		engine_force = 0
		return

	if speed_kmH >= MAX_SPEED_KMH/3 and backward_input:
		engine_force = 0
		return

	if forward_input:
		# Couple électrique : Puissance constante jusqu'à la limite
		engine_force = -engine_force_value * 0.5
		return
		
	if backward_input:
		# Marche arrière souvent plus lente sur un chariot
		engine_force = engine_force_value /3
		return

	engine_force = 0

func process_brake(_delta):
	if Input.is_action_pressed("break"):
		brake = 5.0 # Un chariot s'arrête vite
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

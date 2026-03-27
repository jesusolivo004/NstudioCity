extends CharacterBody3D

# --- 1. REFERENCIAS DE NODOS ---
@onready var raycast = $Camera3D/RayCast3D
@onready var pivot = $Pivot
@onready var camera = $Camera3D
@onready var anim = $Pivot/MODELO3D/AnimationPlayer
@onready var anim_tree = $AnimationTree

# --- 2. VARIABLES DE ESTADO (Las 28 animaciones) ---
var esta_agachado: bool = false
var esta_herido: bool = false
var esta_muriendo: bool = false
var esta_curandose: bool = false
var esta_reaccionando: bool = false
var aterrizaje_suave: bool = false
var tiene_arma_equipada: bool = false
var esta_apuntando: bool = false
var esta_disparando: bool = false
var esta_recargando: bool = false
var esta_equipando: bool = false
var esta_guardando_pistola: bool = false
var esta_atacando: bool = false
var agachado_activado: bool = false
var esta_cayendo_alto: bool = false
var esta_levantandose: bool = false
var saltando: bool = false
var esta_corriendo: bool = false
var esta_sentado: bool = false
var dice_si_senor: bool = false
var es_michaele: bool = false

# --- 3. CONFIGURACIÓN TÉCNICA ---
const SENSITIVITY = 0.008
const CAMERA_HEIGHT = 1.5
var max_fall_height: float = 0.0
const CAMERA_SMOOTH = 15.0
const CAMERA_OFFSET_H: float = 0.8
const ZOOM_IDLE = 2.5
const ZOOM_MOVE = 3.2
const ZOOM_AIM = 1.8
const ZOOM_FAST_SMOOTH = 0.3 
const SPEED_WALK = 5.0
const SPEED_RUN = 10.0
const SPEED_CROUCH = 2.5
const JUMP_VELOCITY = 5.5
const LERP_VAL = 0.15
var cansado: bool = false
var cam_rot_h: float = 0.0
var cam_rot_v: float = 0.0
var stamina: float = 100.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var esta_en_plataforma: bool = false
var velocidad_suelo_plataforma: Vector3 = Vector3.ZERO

# --- 4. INICIALIZACIÓN ---
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if anim:
		anim.animation_finished.connect(_on_animation_finished)
	camera.set_meta("last_dist", ZOOM_IDLE)
	if has_node("HealthComponent"):
		$HealthComponent.on_death.connect(_on_player_death)
		$HealthComponent.on_health_changed.connect(_revisar_estado_herido)
	print("Sistema Latido Crítico: 28 Animaciones Unidas y Seguras.")
	
func _revisar_estado_herido(vida_actual: float):
	esta_herido = (vida_actual <= 25)

func _on_player_death():
	esta_muriendo = true

# --- 5. CONTROL DE CÁMARA ---
func _unhandled_input(event):
	if event is InputEventMouseMotion and not esta_muriendo:
		cam_rot_h -= event.relative.x * SENSITIVITY
		cam_rot_v += event.relative.y * SENSITIVITY
		cam_rot_v = clamp(cam_rot_v, deg_to_rad(-40), deg_to_rad(60))

# --- 6. BUCLE PRINCIPAL ---
func _physics_process(delta):
	if esta_muriendo:
		manejar_muerte(delta)
		return
		
	actualizar_logica_salud_y_stamina(delta)

	# --- GRAVEDAD Y LÓGICA DE DAÑO POR CAÍDA (MEJORADO) ---
	if not is_on_floor():
		velocity.y -= gravity * delta
		if global_position.y > max_fall_height:
			max_fall_height = global_position.y
			if not is_on_floor():
				velocity.y -= gravity * delta
	# ESTO ES LO QUE TE SALVA:
				if Input.is_key_pressed(KEY_E):
					$Camera3D/RayCast3D.force_raycast_update() # Obliga al rayo a trabajar YA
					if $Camera3D/RayCast3D.is_colliding():
						aterrizaje_suave = true
		
		# DETECCIÓN DE EMERGENCIA: Tecla E en el aire
		if Input.is_key_pressed(KEY_E):
			raycast.force_raycast_update() # Obligamos al rayo a detectar ya
			if raycast.is_colliding():
				var dist_aux = global_position.distance_to(raycast.get_collision_point())
				if dist_aux >= 80.0: # Bajamos un poco el rango para asegurar
					aterrizaje_suave = true
					print("SISTEMA DE SEGURIDAD ACTIVADO")
	else:
		if max_fall_height > 0.0:
			var fall_distance = max_fall_height - global_position.y
			
			if aterrizaje_suave == true:
				print("¡Sobreviviste! Aterrizaje suave exitoso.")
			else:
				if fall_distance >= 18.0:
					var damage_to_apply = (fall_distance - 12.0) * 2.0
					if has_node("HealthComponent"):
						$HealthComponent.take_damage(damage_to_apply)
						print("Daño por caída: ", damage_to_apply)
		
		# Reinicio al tocar suelo
		max_fall_height = 0.0
		aterrizaje_suave = false

	# --- SALTO ---
	if Input.is_action_just_pressed("ui_select") and is_on_floor() and not agachado_activado:
		velocity.y = JUMP_VELOCITY
		saltando = true
		
	# --- DETECTAR EL SUELO DEL AVIÓN ---
	esta_en_plataforma = false
	velocidad_suelo_plataforma = Vector3.ZERO
	
	if is_on_floor() and raycast.is_colliding():
		var objeto_tocado = raycast.get_collider()
		if objeto_tocado and objeto_tocado.name.to_upper().contains("PISO"):
			esta_en_plataforma = true
			var avion = objeto_tocado.get_parent().get_parent() 
			if avion.has_method("_get_velocidad_vuelo_real"):
				velocidad_suelo_plataforma = avion._get_velocidad_vuelo_real()
	
	# --- CÁLCULO DE MOVIMIENTO ---
	procesar_teclas_acciones()

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var move_dir = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, cam_rot_h).normalized()

	if move_dir.length() > 0.1 and not esta_levantandose:
		var current_speed = SPEED_WALK
		if esta_corriendo: current_speed = SPEED_RUN
		if esta_agachado or esta_herido: current_speed = SPEED_CROUCH
		
		velocity.x = lerp(velocity.x, move_dir.x * current_speed, LERP_VAL) + velocidad_suelo_plataforma.x
		velocity.z = lerp(velocity.z, move_dir.z * current_speed, LERP_VAL) + velocidad_suelo_plataforma.z
		
		var target_angle = atan2(-move_dir.x, -move_dir.z)
		pivot.rotation.y = lerp_angle(pivot.rotation.y, target_angle, LERP_VAL)
	else:
		velocity.x = lerp(velocity.x, velocidad_suelo_plataforma.x, LERP_VAL)
		velocity.z = lerp(velocity.z, velocidad_suelo_plataforma.z, LERP_VAL)
	
	move_and_slide()
	decidir_y_reproducir_animacion(move_dir, delta)
	procesar_camara_dinamica(delta)

# --- 7. SISTEMA DE ANIMACIÓN ---
func decidir_y_reproducir_animacion(move_dir: Vector3, _delta: float):
	var playback = $AnimationTree.get("parameters/playback")
	
	if not is_on_floor():
		var distancia_al_suelo = 999.0
		if raycast.is_colliding():
			distancia_al_suelo = global_position.distance_to(raycast.get_collision_point())
			
		if distancia_al_suelo >= 140.0:
			playback.travel("RUNTODIVE_A")
			camera.fov = lerp(camera.fov, 85.0, _delta * 2.0)
		elif distancia_al_suelo >= 110.0 or aterrizaje_suave:
			playback.travel("CAERDELCIELO_A")
			camera.fov = lerp(camera.fov, 75.0, _delta * 2.0)
		else:
			playback.travel("JUMP_A")
		return

	if esta_muriendo:
		playback.travel("MUERTE_A")
		return

	if esta_levantandose:
		playback.travel("LEVANTARSEDECAERDELCIELO_A")
		return

	if esta_agachado:
		playback.travel("AGACHADO_A")
	elif move_dir.length() > 0.1:
		if esta_herido: playback.travel("HERIDO_A")
		elif esta_corriendo: playback.travel("RUN_A")
		else: playback.travel("CAMINAR_A")
	else:
		if esta_herido: playback.travel("IDLEHERIDO_A")
		else: playback.travel("IDLE_A")

# --- 8. INPUTS Y LÓGICA ---
func procesar_teclas_acciones():
	# Correr
	esta_corriendo = Input.is_key_pressed(KEY_SHIFT) and not agachado_activado and not cansado
	# Agacharse
	esta_agachado = Input.is_key_pressed(KEY_C)
	
	# Disparo / Ataque
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if tiene_arma_equipada and esta_apuntando:
			if not esta_disparando:
				esta_disparando = true
				disparar_balazo()
		elif not tiene_arma_equipada:
			esta_atacando = true
	else:
		esta_disparando = false
		
	# Equipar Arma (Tecla 3)
	if Input.is_key_pressed(KEY_3):
		if not camera.has_meta("t3_p"):
			tiene_arma_equipada = !tiene_arma_equipada
			camera.set_meta("t3_p", true)
	else:
		camera.set_meta("t3_p", false)

func actualizar_logica_salud_y_stamina(delta):
	if esta_corriendo and velocity.length() > 1.0:
		stamina = max(0.0, stamina - 5.0 * delta)
		if stamina <= 0: cansado = true
	else:
		stamina = min(100.0, stamina + 15.0 * delta)
		if stamina > 30.0: cansado = false

func procesar_camara_dinamica(delta):
	var target_zoom = ZOOM_IDLE
	if esta_apuntando: target_zoom = ZOOM_AIM
	elif velocity.length() > 6.0: target_zoom = ZOOM_MOVE
	
	var cur_dist = lerp(camera.get_meta("last_dist"), target_zoom, ZOOM_FAST_SMOOTH)
	camera.set_meta("last_dist", cur_dist)
	
	var cam_pos = Vector3(sin(cam_rot_h)*cos(cam_rot_v), sin(cam_rot_v), cos(cam_rot_h)*cos(cam_rot_v)) * cur_dist
	var offset_derecha = Vector3(cos(cam_rot_h), 0, -sin(cam_rot_h)) * CAMERA_OFFSET_H
	var target_pos = global_position + Vector3(0, CAMERA_HEIGHT, 0) + cam_pos + offset_derecha
	camera.global_position = camera.global_position.lerp(target_pos, CAMERA_SMOOTH * delta)
	camera.look_at(global_position + Vector3(0, CAMERA_HEIGHT, 0) + offset_derecha)

func manejar_muerte(_delta):
	velocity = Vector3.ZERO
	play_safe("MUERTE_A")

func play_safe(anim_name: String):
	if anim == null: return
	var final_name = anim_name.replace("/", ":")
	if anim.current_animation != final_name:
		if anim.has_animation(final_name):
			anim.play(final_name, 0.1)

func _on_animation_finished(anim_name: String):
	if "LEVANTARSE" in anim_name: esta_levantandose = false
	if "JUMP" in anim_name: saltando = false

func disparar_balazo():
	if raycast.is_colliding():
		var objeto = raycast.get_collider()
		if objeto.has_method("receive_damage"):
			objeto.receive_damage(20.0)

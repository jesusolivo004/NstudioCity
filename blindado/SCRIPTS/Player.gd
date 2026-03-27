extends CharacterBody3D#############################
# --- 1. REFERENCIAS DE NODOS ---
@onready var raycast = $Camera3D/RayCast3D
@onready var pivot = $Pivot
@onready var camera = $Camera3D
@onready var anim = $Pivot/MODELO3D/AnimationPlayer
# --- 2. VARIABLES DE ESTADO (Las 28 animaciones) ---##################################################
var esta_agachado: bool = false  # <--- Añade esto aquí
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
# --- 3. CONFIGURACIÓN TÉCNICA (Sensibilidad y Velocidades) ---##########################################
const SENSITIVITY = 0.008
const CAMERA_HEIGHT = 1.5
var max_fall_height: float = 0.0 # Guardará la y máxima alcanzada
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
# --- 4. INICIALIZACIÓN ---##############################################################
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if anim:
		anim.animation_finished.connect(_on_animation_finished)
	camera.set_meta("last_dist", ZOOM_IDLE)
	$HealthComponent.on_death.connect(_on_player_death)
	$HealthComponent.on_health_changed.connect(_revisar_estado_herido)
	print("Sistema Latido Crítico: 28 Animaciones Unidas.")
	
func _revisar_estado_herido(vida_actual: float):
	if vida_actual <= 25:
		esta_herido = true
	else:
		esta_herido = false
func _on_player_death():
	esta_muriendo = true
	# Forzamos al árbol a ir a muerte
	##$AnimationTree.get("parameters/playback").travel("MUERTE_A")
# --- 5. CONTROL DE CÁMARA ---########################################################
func _unhandled_input(event):
	if event is InputEventMouseMotion and not esta_muriendo:
		cam_rot_h -= event.relative.x * SENSITIVITY
		cam_rot_v += event.relative.y * SENSITIVITY
		cam_rot_v = clamp(cam_rot_v, deg_to_rad(-40), deg_to_rad(60))

# --- 6. BUCLE PRINCIPAL ---
func _physics_process(delta):######################################################################
	if esta_muriendo:
		manejar_muerte(delta)
		return
	actualizar_logica_salud_y_stamina(delta)
	procesar_teclas_acciones()
# --- 6. GRAVEDAD Y LÓGICA DE DAÑO POR CAÍDA ---
	if not is_on_floor():
		velocity.y -= gravity * delta
		if global_position.y > max_fall_height:
			max_fall_height = global_position.y
		
	# DETECCIÓN DE EMERGENCIA: Si presionas E en el aire a más de 100m
	if Input.is_key_pressed(KEY_E):
		if raycast.is_colliding():
			var dist_aux = global_position.distance_to(raycast.get_collision_point())
			if dist_aux >= 100.0:
				aterrizaje_suave = true
				# Opcional: Cambia el color del personaje o imprime para saber que funcionó
				print("SISTEMA DE SEGURIDAD ACTIVADO")

	else:
	# MOMENTO DEL IMPACTO (Cuando toca el suelo)
		if max_fall_height > 0.0:
			var fall_distance = max_fall_height - global_position.y
		
		# Solo calculamos daño si NO activamos el aterrizaje suave
			if aterrizaje_suave == true:
				print("¡Sobreviviste! Aterrizaje suave exitoso.")
			else:
			# Si NO presionó E a tiempo, calculamos el daño normal
				if fall_distance >= 20.0:
					var damage_to_apply = (fall_distance - 15.0) * 2.0
					$HealthComponent.take_damage(damage_to_apply)
					print("Daño por caída: ", damage_to_apply)
		
		# REINICIO TOTAL (Esto siempre al final del impacto)
		max_fall_height = 0.0
		aterrizaje_suave = false
		# Salto (Se mantiene igual)
	if Input.is_action_just_pressed("ui_select") and not agachado_activado and not esta_levantandose:
			velocity.y = JUMP_VELOCITY
			saltando = true
		
	# --- 1. DETECTAR EL SUELO DEL AVIÓN ---
	esta_en_plataforma = false
	velocidad_suelo_plataforma = Vector3.ZERO
	
	if is_on_floor():
		# Usamos el RayCast para verificar qué estamos tocando
		if raycast_suelo_fisico.is_colliding():
			var objeto_tocado = raycast_suelo_fisico.get_collider()
			
			# Comprobamos si el objeto tocado es el StaticBody3D del avión (o si tiene la palabra 'PISO')
			if objeto_tocado.name.to_upper().contains("PISO"):
				esta_en_plataforma = true
				
				# Aquí está el truco: Obtenemos la velocidad REAL del avión en ese frame.
				# Como el avión se mueve con translate(), calculamos su velocidad por frame.
				var avion = objeto_tocado.get_parent().get_parent() # Ajusta la ruta si es necesario (Static -> Mesh -> Avión)
				if avion.has_method("_get_velocidad_vuelo_real"): # Creamos esta función en el avión
					velocidad_suelo_plataforma = avion._get_velocidad_vuelo_real()
	
	# --- 2. CÁLCULO DE MOVIMIENTO DEL PERSONAJE ---
	procesar_teclas_acciones()

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var move_dir = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, cam_rot_h).normalized()

	if move_dir.length() > 0.1 and not esta_levantandose:
		var current_speed = SPEED_WALK
		if esta_corriendo: current_speed = SPEED_RUN
		if agachado_activado or esta_herido: current_speed = SPEED_CROUCH
		
		# --- 3. EL TRUCO DE LA VELOCIDAD ---
		# Calculamos la velocidad de caminata normal
		var target_velocity_x = lerp(velocity.x, move_dir.x * current_speed, LERP_VAL)
		var target_velocity_z = lerp(velocity.z, move_dir.z * current_speed, LERP_VAL)
		
		# Y le SUMAMOS la velocidad del suelo si estamos en la plataforma
		velocity.x = target_velocity_x + velocidad_suelo_plataforma.x
		velocity.z = target_velocity_z + velocidad_suelo_plataforma.z
		
		# (Resto de tu código de rotación del pivote se queda igual)
	else:
		# Si está quieto, aún así debe moverse CON la plataforma
		velocity.x = lerp(velocity.x, velocidad_suelo_plataforma.x, LERP_VAL)
		velocity.z = lerp(velocity.z, velocidad_suelo_plataforma.z, LERP_VAL)
	
	# Llamamos a move_and_slide() como siempre
	move_and_slide()
	procesar_camara_dinamica(delta)

# --- 7. SISTEMA DE ANIMACIÓN CON ANIMATIONTREE ---######################################################
func decidir_y_reproducir_animacion(move_dir: Vector3, _delta: float):
	var playback = $AnimationTree.get("parameters/playback")
	var reticulo = get_node("HUD/CenterContainer/Point")
# --- 2. PRIORIDADES DE ANIMACIÓN ---
# 1. Primero chequeamos si está en el aire (Volar/Caer tiene prioridad total)
	if not is_on_floor():
		var distancia_al_suelo = 999.0
		if raycast.is_colliding():
			# Calculamos la distancia real entre el personaje y el punto de choque del rayo
			var punto_choque = raycast.get_collision_point()
			distancia_al_suelo = global_position.distance_to(punto_choque)
			
		if distancia_al_suelo >= 140.0:
			playback.travel("RUNTODIVE_A")
			if distancia_al_suelo >= 140.0:
				camera.fov = lerp(camera.fov, 85.0, _delta * 2.0) # Cámara se abre (efecto velocidad)
			else:
				camera.fov = lerp(camera.fov, 75.0, _delta * 2.0) # Cámara vuelve a lo normal
			return # Si está haciendo la picada, no hace falta ver si murió aún
			
		elif distancia_al_suelo >= 110.0:
			playback.travel("CAERDELCIELO_A")
			return
		else:
			playback.travel("JUMP_A")
		return

	# --- LÓGICA DE MUERTE (Solo si ya tocó el suelo) ---
	if esta_muriendo:
		playback.travel("MUERTE_A")
		return
# 3. El resto de animaciones (Suelo)
	if esta_levantandose:
		playback.travel("LEVANTARSEDECAERDELCIELO_A")
		return
# ... resto del código

	if esta_agachado:
		playback.travel("AGACHADO_A")
		return 
	# --- 3. MOVIMIENTO (NORMAL O HERIDO) ---
	if move_dir.length() > 0.1:
		if esta_herido:
			playback.travel("HERIDO_A")
		elif esta_corriendo:
			playback.travel("RUN_A")
		else:
			playback.travel("CAMINAR_A")
	else:
		if esta_herido:
			playback.travel("IDLEHERIDO_A")
		else:
			playback.travel("IDLE_A")
######################################play_safe(anim_a_poner)###########################################

# --- 8. INPUTS Y LÓGICA ---###########################################
func procesar_teclas_acciones():##############################################################PROCESARTECLAAS
	
	# Dentro de func procesar_teclas_acciones():
	if Input.is_key_pressed(KEY_E) and not is_on_floor():
		# Usamos el RayCast para saber la distancia
		print("TECLA E DETECTADA")
		if raycast.is_colliding():
			var punto = raycast.get_collision_point()
			var distancia = global_position.distance_to(punto)
		
		# Si estamos a más de 100 metros
			if distancia >= 100.0:
				aterrizaje_suave = true
				print("¡Aterrizaje suave ACTIVADO! No habrá daño.")
				play_safe("CAERDELCIELO_A")
			# OPCIONAL: Aquí puedes activar una animación de paracaídas o planeo
	
	# Shift para correr
	esta_corriendo = Input.is_key_pressed(KEY_SHIFT) and not agachado_activado and not cansado
	# Tecla C: Agacharse
	if Input.is_key_pressed(KEY_C):
		esta_agachado = true # <--- Ponemos el interruptor en "Encendido"
	else:
		esta_agachado = false # <--- Si sueltas C, se apaga
	# Dentro de la función procesar_teclas_acciones()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if tiene_arma_equipada and esta_apuntando:
			if not esta_disparando: # Esto evita que dispare cada milisegundo
				esta_disparando = true
				disparar_balazo()
		elif not tiene_arma_equipada:
			esta_atacando = true
	else:
		esta_disparando = false
	# Tecla 3: Equipar (Simplificado)
	if Input.is_key_pressed(KEY_3):
		if not camera.has_meta("t3_p"):
			tiene_arma_equipada = !tiene_arma_equipada
			if tiene_arma_equipada: esta_equipando = true
			else: esta_guardando_pistola = true
			camera.set_meta("t3_p", true)
	else:
		camera.set_meta("t3_p", false)
##############################################################
func actualizar_logica_salud_y_stamina(delta):############################################################
	if esta_corriendo and velocity.length() > 1.0:
		# Gasto de 5.0 por segundo (100 / 5 = 20 segundos de carrera)
		stamina = max(0.0, stamina - 5.0 * delta)
		if stamina <= 0: cansado = true # Se cansó totalmente
	else:
		# Recuperación de 15.0 por segundo (Se llena en 6.6 segundos)
		stamina = min(100.0, stamina + 15.0 * delta)
		if stamina > 30.0: cansado = false # Solo puede volver a correr tras recuperar un poco
	#################################################################################################################
func procesar_camara_dinamica(delta):
	var target_zoom = ZOOM_IDLE
	if esta_apuntando: target_zoom = ZOOM_AIM
	elif velocity.length() > 6.0: target_zoom = ZOOM_MOVE
	
	var cur_dist = lerp(camera.get_meta("last_dist"), target_zoom, ZOOM_FAST_SMOOTH)
	camera.set_meta("last_dist", cur_dist)
	
	# Cálculo del círculo alrededor del player
	var cam_pos = Vector3(sin(cam_rot_h)*cos(cam_rot_v), sin(cam_rot_v), cos(cam_rot_h)*cos(cam_rot_v)) * cur_dist
	# --- EL TRUCO PARA LA DERECHA ---
	# Esto crea un vector que siempre apunta a la derecha de donde mira la cámara
	var offset_derecha = Vector3(cos(cam_rot_h), 0, -sin(cam_rot_h)) * CAMERA_OFFSET_H
	# Sumamos la posición del player + altura + círculo + desplazamiento a la derecha
	var target_pos = global_position + Vector3(0, CAMERA_HEIGHT, 0) + cam_pos + offset_derecha
	camera.global_position = camera.global_position.lerp(target_pos, CAMERA_SMOOTH * delta)
	# Miramos un punto desplazado para que el personaje no tape el centro
	camera.look_at(global_position + Vector3(0, CAMERA_HEIGHT, 0) + offset_derecha)
#######################################################
func manejar_muerte(_delta):#######################################################################
	velocity = Vector3.ZERO
	play_safe("MUERTE_A")
################################################
# --- 9. SEGURIDAD Y LIMPIEZA (VERSIÓN DEFINITIVA) ---
func play_safe(anim_name: String):#################################################################
	if anim == null: return
	# 1. Ajuste de nombre para librerías (ACCIONES: o EMOTES:)
	var final_name = anim_name.replace("/", ":")
	if anim.current_animation == final_name and anim.is_playing():
		return 
	# 3. Intentamos reproducir la animación
	if anim.has_animation(final_name):
		# Usamos un valor de mezcla (0.1) para que no se vea cortado
		anim.play(final_name, 0.1)
	else:
		# Intento de respaldo para la librería [Global]
		if anim.has_animation(anim_name):
			if anim.current_animation != anim_name:
				anim.play(anim_name, 0.1)
		else:
			# Si llegas aquí, es que el nombre está mal escrito en el script
			push_warning("OJO: No encuentro la animación: " + final_name)
#################################################
func _on_animation_finished(anim_name: String):#####################################################
	if "PUNCH" in anim_name: esta_atacando = false
	if "RECARGANDO" in anim_name: esta_recargando = false
	if "EQUIPAR" in anim_name: esta_equipando = false
	if "GUARDAR" in anim_name: esta_guardando_pistola = false
	if "LEVANTARSE" in anim_name: esta_levantandose = false
	if "JUMP" in anim_name: saltando = false
func disparar_balazo():
	# Verificamos si el rayo chocó con algo
	if raycast.is_colliding():
		var objeto = raycast.get_collider() # Obtenemos el objeto golpeado
		var punto_impacto = raycast.get_collision_point() # Dónde pegó exactamente
		print("Le diste a: ", objeto.name)
		# SI EL OBJETO TIENE VIDA (HitboxComponent)
		if objeto.has_method("receive_damage"):
			objeto.receive_damage(20.0) # Le quitamos 20 de vida

extends CharacterBody3D

# --- 1. REFERENCIAS DE NODOS ---
@onready var raycast = $Camera3D/RayCast3D
@onready var pivot = $Pivot
@onready var camera = $Camera3D
@onready var anim = $Pivot/MODELO3D/AnimationPlayer
@onready var anim_tree = $AnimationTree

@export var hud_manager: HUDManager
@export var anim_handler: AnimationHandler
@export var cam_manager: CameraManager
@export var health_manager: HealthManager
@export var interact_manager: InteractionManager # <--- NUEVO: Arrastra el nodo aquí

# --- 2. VARIABLES DE ESTADO (Mantenidas todas) ---
var esta_agachado: bool = false
var esta_herido: bool = false
var esta_muriendo: bool = false
var aterrizaje_suave: bool = false
var tiene_arma_equipada: bool = false
var esta_apuntando: bool = false
var esta_disparando: bool = false
var esta_atacando: bool = false
var agachado_activado: bool = false
var esta_levantandose: bool = false
var esta_corriendo: bool = false

# --- 3. CONFIGURACIÓN TÉCNICA (Mantenida) ---
var max_fall_height: float = 0.0
const SPEED_WALK = 5.0
const SPEED_RUN = 10.0
const SPEED_CROUCH = 2.5
const JUMP_VELOCITY = 5.5
const LERP_VAL = 0.15
var cansado: bool = false
var stamina: float = 100.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var velocidad_suelo_plataforma: Vector3 = Vector3.ZERO

# --- 4. INICIALIZACIÓN ---
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if anim:
		anim.animation_finished.connect(_on_animation_finished)
	
	if health_manager:
		health_manager.al_morir.connect(func(): esta_muriendo = true)
		health_manager.al_herirse.connect(func(valor): esta_herido = valor)

# --- 5. ENTRADAS ---
func _unhandled_input(event):
	if cam_manager:
		cam_manager.manejar_entrada(event)

func _input(event):
# Dentro del _input(event) en Player.gd
	if event.is_action_pressed("tecla_inventario"): # Tu tecla TAB
		var estado = !hud_manager.inventario.visible
		hud_manager.mostrar_inventario_solo_jugador(estado)
	# En el _input del Player.gd
	if event.is_action_pressed("tecla_interaccion"):
	# Solo intentamos interactuar si el Manager detectó un objeto válido previamente
		if interact_manager and interact_manager.objeto_actual != null:
			interact_manager.intentar_interactuar()

# --- 6. BUCLE PRINCIPAL ---
func _physics_process(delta):
	if esta_muriendo:
		velocity = Vector3.ZERO
		move_and_slide()
		return
		
	actualizar_logica_salud_y_stamina(delta)

	# Lógica de gravedad (Tu lógica original intacta)
	if not is_on_floor():
		velocity.y -= gravity * delta
		raycast.force_raycast_update()
		if raycast.is_colliding():
			var punto_colision = raycast.get_collision_point()
			var distancia = global_position.distance_to(punto_colision)
			
			if hud_manager:
				if distancia <= 222.0 and distancia > 70.0 and not aterrizaje_suave:
					hud_manager.mostrar_alerta_proximidad(true)
				else:
					hud_manager.mostrar_alerta_proximidad(false)

			if Input.is_key_pressed(KEY_E) and distancia <= 190.0:
				aterrizaje_suave = true
				velocity.y = max(velocity.y, -5.0) 
				if anim_tree:
					anim_tree.get("parameters/playback").travel("CAERDELCIELO_A")
		else:
			aterrizaje_suave = false
		
		if global_position.y > max_fall_height:
			max_fall_height = global_position.y
	else:
		if max_fall_height > 0.0:
			var fall_distance = max_fall_height - global_position.y
			if not aterrizaje_suave and fall_distance >= 18.0:
				var daño = (fall_distance - 12.0) * 2.5
				health_manager.recibir_daño(daño)
				if hud_manager:
					var fuerza_sangre = clamp(daño / 100.0, 0.4, 1.0)
					hud_manager.efecto_impacto_sangre(fuerza_sangre)
		max_fall_height = 0.0
		aterrizaje_suave = false

	if Input.is_action_just_pressed("ui_select") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	procesar_teclas_acciones()
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	var forward = cam_manager.global_transform.basis.z
	var right = cam_manager.global_transform.basis.x
	var move_dir = (forward * input_dir.y + right * input_dir.x)
	move_dir.y = 0
	move_dir = move_dir.normalized()

	if move_dir.length() > 0.1 and not esta_levantandose:
		var current_speed = SPEED_WALK
		if esta_corriendo: current_speed = SPEED_RUN
		if esta_agachado or esta_herido: current_speed = SPEED_CROUCH
		
		velocity.x = lerp(velocity.x, move_dir.x * current_speed, LERP_VAL)
		velocity.z = lerp(velocity.z, move_dir.z * current_speed, LERP_VAL)
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-move_dir.x, -move_dir.z), LERP_VAL)
	else:
		velocity.x = lerp(velocity.x, 0.0, LERP_VAL)
		velocity.z = lerp(velocity.z, 0.0, LERP_VAL)
	
	move_and_slide()
	
	if cam_manager:
		cam_manager.actualizar_posicion(delta, velocity.length(), esta_apuntando)
	if anim_handler:
		anim_handler.actualizar_animaciones(self, move_dir, delta)
	
	# NUEVO: El Manager revisa si hay algo interactuable cada frame
	if interact_manager:
		interact_manager.manejar_interaccion(delta)

# --- 7. FUNCIONES DE APOYO (Originales) ---
func procesar_teclas_acciones():
	esta_corriendo = Input.is_key_pressed(KEY_SHIFT) and not cansado
	esta_agachado = Input.is_key_pressed(KEY_C)
	esta_apuntando = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

func actualizar_logica_salud_y_stamina(delta):
	if esta_corriendo and velocity.length() > 1.0:
		stamina = max(0.0, stamina - 10.0 * delta)
		if stamina <= 0: cansado = true
	else:
		stamina = min(100.0, stamina + 20.0 * delta)
		if stamina > 30.0: cansado = false

func _on_animation_finished(anim_name: String):
	if "LEVANTARSE" in anim_name: esta_levantandose = false

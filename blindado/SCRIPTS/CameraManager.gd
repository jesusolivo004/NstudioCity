extends Camera3D
class_name CameraManager

# --- CONFIGURACIÓN ---
@export var player: CharacterBody3D
@export_group("Sensibilidad y Rotación")
const SENSITIVITY = 0.008
const V_LIMIT_UP = 60.0
const V_LIMIT_DOWN = -40.0

@export_group("Zoom Dinámico")
const ZOOM_IDLE = 2.5
const ZOOM_MOVE = 3.2
const ZOOM_AIM = 1.8
const ZOOM_SMOOTH = 0.3
const CAMERA_HEIGHT = 1.5
const CAMERA_OFFSET_H = 0.8

var cam_rot_h: float = 0.0
var cam_rot_v: float = 0.0
var current_zoom: float = ZOOM_IDLE

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	top_level = true # Hace que la cámara no herede la rotación brusca del modelo

func manejar_entrada(event: InputEvent):
	if event is InputEventMouseMotion and player and not player.esta_muriendo:
		cam_rot_h -= event.relative.x * SENSITIVITY
		cam_rot_v += event.relative.y * SENSITIVITY
		cam_rot_v = clamp(cam_rot_v, deg_to_rad(V_LIMIT_DOWN), deg_to_rad(V_LIMIT_UP))

func actualizar_posicion(delta: float, velocidad_player: float, apuntando: bool):
	# 1. Calcular el Zoom según el estado
	var target_zoom = ZOOM_IDLE
	if apuntando: target_zoom = ZOOM_AIM
	elif velocidad_player > 6.0: target_zoom = ZOOM_MOVE
	
	current_zoom = lerp(current_zoom, target_zoom, ZOOM_SMOOTH)
	
	# 2. Calcular posición matemática
	var cam_pos = Vector3(
		sin(cam_rot_h) * cos(cam_rot_v), 
		sin(cam_rot_v), 
		cos(cam_rot_h) * cos(cam_rot_v)
	) * current_zoom
	
	var offset_derecha = Vector3(cos(cam_rot_h), 0, -sin(cam_rot_h)) * CAMERA_OFFSET_H
	var target_pos = player.global_position + Vector3(0, CAMERA_HEIGHT, 0) + cam_pos + offset_derecha
	
	# 3. Aplicar movimiento suave
	global_position = global_position.lerp(target_pos, 15.0 * delta)
	look_at(player.global_position + Vector3(0, CAMERA_HEIGHT, 0) + offset_derecha)

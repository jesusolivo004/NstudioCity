extends Node3D

@export var motor_1: Node3D
@export var motor_2: Node3D
@export var sonido_motor: AudioStreamPlayer3D 

@export var velocidad_giro: float = 10.0
@export var velocidad_vuelo: float = 20.0 # Qué tan rápido avanza el avión
var ultima_posicion: Vector3
var tiempo_motores: float = 30.0
var tiempo_vuelo_total: float = 300.0 # 5 minutos en segundos
var esta_girando: bool = true
var en_vuelo: bool = true

func _ready():
	if sonido_motor:
		sonido_motor.play()

func _process(delta: float):
	# --- 1. LÓGICA DE LOS MOTORES (30 Segundos) ---
	if esta_girando:
		tiempo_motores -= delta
		if tiempo_motores > 0:
			if motor_1: motor_1.rotate_y(velocidad_giro * delta)
			if motor_2: motor_2.rotate_y(velocidad_giro * delta)
		else:
			esta_girando = false
			# Opcional: bajar el volumen en lugar de stop seco
			if sonido_motor: sonido_motor.stop()

	# --- 2. LÓGICA DE MOVIMIENTO Z (5 Minutos) ---
	if en_vuelo:
		tiempo_vuelo_total -= delta
		
		if tiempo_vuelo_total > 0:
			# Movemos el avión en el eje Z global
			# Si quieres que vaya hacia adelante, usa + o - dependiendo de tu modelo
			global_translate(Vector3(0, 0, velocidad_vuelo * delta))
		else:
			en_vuelo = false
			print("El avión ha completado sus 5 minutos de vuelo.")
func _physics_process(delta):
	ultima_posicion = global_position
	# Tu código de movimiento aquí (global_translate)

func _get_velocidad_vuelo_real() -> Vector3:
	return (global_position - ultima_posicion) / get_physics_process_delta_time()

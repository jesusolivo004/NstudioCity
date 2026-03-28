extends Node3D

@export var motor_1: Node3D
@export var motor_2: Node3D
@export var sonido_motor: AudioStreamPlayer3D 

@export var velocidad_giro: float = 10.0
@export var velocidad_vuelo: float = 20.0
var ultima_posicion: Vector3
var tiempo_motores: float = 30.0
var tiempo_vuelo_total: float = 150.0 
var esta_girando: bool = true
var en_vuelo: bool = true

func _ready():
	if sonido_motor: sonido_motor.play()
	ultima_posicion = global_position

func _physics_process(delta: float):
	ultima_posicion = global_position # Guardar antes de mover
	
	if esta_girando:
		tiempo_motores -= delta
		if tiempo_motores > 0:
			if motor_1: motor_1.rotate_y(velocidad_giro * delta)
			if motor_2: motor_2.rotate_y(velocidad_giro * delta)
		else:
			esta_girando = false
			if sonido_motor: sonido_motor.stop()

	if en_vuelo:
		tiempo_vuelo_total -= delta
		if tiempo_vuelo_total > 0:
			global_translate(Vector3(0, 0, velocidad_vuelo * delta))
		else:
			en_vuelo = false

func _get_velocidad_vuelo_real() -> Vector3:
	return (global_position - ultima_posicion) / get_physics_process_delta_time()

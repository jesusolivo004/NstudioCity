extends Node
class_name AnimationHandler

@export var anim_tree: AnimationTree
@onready var playback = anim_tree.get("parameters/playback")

func _ready():
	if anim_tree:
		playback = anim_tree.get("parameters/playback")
	else:
		push_error("¡Cuidado! No has asignado el AnimationTree en el Inspector de AnimationHandler.")
		
# Función principal que llama el Player
func actualizar_animaciones(player: CharacterBody3D, move_dir: Vector3, _delta: float):
	
	if not player.is_on_floor():
		_manejar_aire(player) # Quitamos delta de aquí si no se usa dentro
		return

	if player.esta_muriendo:
		playback.travel("MUERTE_A")
		return

	if player.esta_levantandose:
		playback.travel("LEVANTARSEDECAERDELCIELO_A")
		return

	_manejar_suelo(player, move_dir)

# Usamos _ antes de los parámetros que no usamos para quitar el Warning
func _manejar_aire(player: CharacterBody3D):
	var ray = player.get_node("Camera3D/RayCast3D")
	var distancia = 999.0
	
	if ray.is_colliding():
		distancia = player.global_position.distance_to(ray.get_collision_point())
			
	# 1. Si estamos cerca del suelo (menos de 15 metros), es un salto normal
	if distancia < 10.0:
		playback.travel("JUMP_A")
		
	# 2. Si estamos en caída libre extrema (más de 180 como pediste)
	elif distancia >= 200.0:
		playback.travel("RUNTODIVE_A")
		
	# 3. Si estamos en caída media o aterrizaje de emergencia
	elif distancia <= 190.0 or player.aterrizaje_suave:
		playback.travel("CAERDELCIELO_A")
		
	# 4. Por defecto, si nada de lo anterior se cumple
	else:
		playback.travel("JUMP_A")

func _manejar_suelo(player: CharacterBody3D, move_dir: Vector3):
	if player.esta_agachado:
		playback.travel("AGACHADO_A")
	elif move_dir.length() > 0.1:
		if player.esta_herido: 
			playback.travel("HERIDO_A")
		elif player.esta_corriendo: 
			playback.travel("RUN_A")
		else: 
			playback.travel("CAMINAR_A")
	else:
		if player.esta_herido: 
			playback.travel("IDLEHERIDO_A")
		else: 
			playback.travel("IDLE_A")

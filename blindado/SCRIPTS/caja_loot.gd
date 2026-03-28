extends Node3D

@export var item_nombre: String = "Botiquín"
var jugador_cerca: bool = false
var hud: HUDManager

func _ready():
	# Conectamos las señales del Area3D (el nodo hijo)
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		jugador_cerca = true
		hud = body.hud_manager
		hud.mostrar_mensaje_accion("Presiona E para recoger " + item_nombre, true)

func _on_body_exited(body):
	if body.is_in_group("Player"):
		jugador_cerca = false
		if hud:
			hud.mostrar_mensaje_accion("", false)

func _input(event):
	if jugador_cerca and event.is_action_pressed("tecla_interaccion"): # Crea esta tecla (E)
		recoger_item()

func recoger_item():
	print("Recogido: ", item_nombre)
	# Aquí podrías añadirlo al ItemList del HUD
	hud.item_list.add_item(item_nombre)
	hud.mostrar_mensaje_accion("", false)
	queue_free() # La caja desaparece

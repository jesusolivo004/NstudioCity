extends Node
class_name InteractionManager

@export var raycast: RayCast3D
@export var hud_manager: HUDManager

var objeto_actual = null

func manejar_interaccion(_delta):
	if not raycast: return
	
	if raycast.is_colliding():
		var col = raycast.get_collider()
		
		# Verificamos si el nombre del objeto es "CUBO" o "CajaLoot"
		if col.name == "CUBO" or col.name == "CajaLoot":
			objeto_actual = col
			hud_manager.mostrar_mensaje_accion("Presiona [E] para saquear", true)
		else:
			limpiar_interaccion()
	else:
		limpiar_interaccion()

func intentar_interactuar():
	if objeto_actual and objeto_actual.has_method("interactuar"):
		objeto_actual.interactuar(hud_manager)

func limpiar_interaccion():
	objeto_actual = null
	if hud_manager:
		hud_manager.mostrar_mensaje_accion("", false)

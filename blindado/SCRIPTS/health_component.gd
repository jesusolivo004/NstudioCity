extends Node
class_name HealthManager

signal al_morir
signal al_cambiar_salud(nueva_vida)
signal al_herirse(esta_herido) # Nueva: avisa si la vida es menor al 25%

@export var max_health: float = 100.0
@onready var current_health: float = max_health

func recibir_daño(cantidad: float):
	current_health -= cantidad
	al_cambiar_salud.emit(current_health)
	
	# Avisar si está en estado crítico (para animaciones de herido)
	al_herirse.emit(current_health <= 25.0)
	
	if current_health <= 0:
		al_morir.emit()
		print("Entidad eliminada.")

func curar(cantidad: float):
	current_health = min(current_health + cantidad, max_health)
	al_cambiar_salud.emit(current_health)
	al_herirse.emit(current_health <= 25.0)

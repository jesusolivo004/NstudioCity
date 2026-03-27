extends Node
class_name HealthComponent

# Estas señales avisan al Player y a la Barra de Vida
signal on_death
signal on_health_changed(current_health)

@export var max_health: float = 100.0
@onready var current_health: float = max_health

func take_damage(amount: float):
	current_health -= amount
	on_health_changed.emit(current_health) # Avisa a los demás
	
	if current_health <= 0:
		on_death.emit() # Avisa que murió
		print("Entidad sin vida.")

func heal(amount: float):
	current_health = min(current_health + amount, max_health)
	on_health_changed.emit(current_health)

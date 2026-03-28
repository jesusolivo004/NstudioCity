extends Area3D
class_name HitboxComponent

# Aquí le decimos a qué componente de salud le mandaremos el daño
@export var health_component: Node

func receive_damage(amount: float):
	if health_component:
		health_component.take_damage(amount)

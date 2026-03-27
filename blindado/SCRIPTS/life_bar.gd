extends ProgressBar

# Arrastra el nodo HealthComponent del Player aquí en el Inspector
@export var health_node: HealthComponent 

func _ready():
	# Nos "suscribimos" a la señal que ya creamos antes
	if health_node:
		health_node.on_health_changed.connect(_actualizar_barra)
		# Ponemos el valor inicial
		value = health_node.current_health

func _actualizar_barra(nueva_vida):
	value = nueva_vida
	
	# Si la vida es baja, mostramos el cuadro rojo con un poco de transparencia
	var filtro = get_node("../FiltroSangre")
	if nueva_vida <= 25:
		filtro.color.a = 0.3 # Rojo suave
	else:
		filtro.color.a = 0.0 # Invisible

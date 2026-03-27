extends Control

# Esta es la variable que leerá el Player al soltar la "T"
var emote_seleccionado = "" 

# Diccionario con las animaciones para cada uno de los 9 espacios
# Los ángulos de Godot: 0° es Derecha, 90° es Abajo, 180° es Izquierda, 270° es Arriba
var lista_emotes = {
	"Derecha": "EMOTES/MICHAELE_A",     # 0° - 40°
	"Abajo_Der": "",                    # 40° - 80°
	"Abajo": "",                        # 80° - 120°
	"Abajo_Izq": "",                    # 120° - 160°
	"Izquierda": "",                    # 160° - 200°
	"Arriba_Izq": "",                   # 200° - 240°
	"Arriba": "EMOTES/SISEÑOR_A",       # 240° - 280°
	"Arriba_Der": "",                   # 280° - 320°
	"Derecha_Sup": ""                   # 320° - 360°
}

func _ready():
	hide() # Empieza oculta
	restablecer_iluminacion_todos()

func _physics_process(_delta):
	if is_visible_in_tree():
		procesar_seleccion_ruleta()

func procesar_seleccion_ruleta():
	var centro = get_global_rect().get_center()
	var mouse_pos = get_global_mouse_position()
	var vector = mouse_pos - centro
	
	# "Zona Muerta": Si el mouse está muy cerca del centro, no elige nada
	if vector.length() < 40:
		restablecer_iluminacion_todos()
		emote_seleccionado = ""
		return

	# Obtener ángulo de 0 a 360
	var angulo = rad_to_deg(vector.angle())
	if angulo < 0: angulo += 360
	
	restablecer_iluminacion_todos()
	
	# Lógica de 9 secciones (40 grados cada una)
	if angulo >= 0 and angulo < 40:
		iluminar_y_preparar("Derecha", "Emote_Michael") # Cambia el nombre al de tu nodo
		
	elif angulo >= 40 and angulo < 80:
		iluminar_y_preparar("Abajo_Der", "TuNodo2")
		
	elif angulo >= 80 and angulo < 120:
		iluminar_y_preparar("Abajo", "TuNodo3")
		
	elif angulo >= 120 and angulo < 160:
		iluminar_y_preparar("Abajo_Izq", "TuNodo4")
		
	elif angulo >= 160 and angulo < 200:
		iluminar_y_preparar("Izquierda", "TuNodo5")
		
	elif angulo >= 200 and angulo < 240:
		iluminar_y_preparar("Arriba_Izq", "TuNodo6")
		
	elif angulo >= 240 and angulo < 280:
		# Este suele ser el Norte/Arriba
		iluminar_y_preparar("Arriba", "Emote_SISEÑOR") 
		
	elif angulo >= 280 and angulo < 320:
		iluminar_y_preparar("Arriba_Der", "TuNodo8")
		
	elif angulo >= 320 and angulo <= 360:
		iluminar_y_preparar("Derecha_Sup", "TuNodo9")

func iluminar_y_preparar(seccion, nombre_nodo):
	emote_seleccionado = lista_emotes[seccion]
	
	if has_node(nombre_nodo):
		var icono = get_node(nombre_nodo)
		# Ponemos el icono en Amarillo brillante
		icono.modulate = Color(1, 1, 0, 1) 
		# Efecto opcional: hacerlo un poco más grande
		icono.scale = Vector2(1.1, 1.1)

func restablecer_iluminacion_todos():
	# Limpia todos los hijos que sean iconos (TextureRect o Sprite2D)
	for hijo in get_children():
		if hijo is TextureRect or hijo is Sprite2D:
			# Blanco con transparencia (se ve grisáceo/apagado)
			hijo.modulate = Color(1, 1, 1, 0.5) 
			hijo.scale = Vector2(1, 1)

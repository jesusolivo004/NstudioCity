extends CanvasLayer
class_name HUDManager

# --- REFERENCIAS A HIJOS ---
@onready var filtro_sangre = $FiltroSangre
@onready var progress_bar = $ProgressBar
@onready var inventario = $Inventario
@onready var item_list = $Inventario/ItemList
@onready var mensaje_interaccion = $MensajeInteraccion
@onready var alerta_salto = $AlertaSalto

# --- REFERENCIA AL PLAYER (Se asigna en el Inspector) ---
@export var health_manager: HealthManager
var tween_alerta: Tween

func _ready():
	# Nos conectamos a las señales del componente de salud
	if health_manager:
		health_manager.al_cambiar_salud.connect(_actualizar_interfaz)
		health_manager.al_morir.connect(_on_muerte)
	
	# Configuramos estado inicial
	filtro_sangre.modulate.a = 0
	inventario.visible = false
func mostrar_alerta_proximidad(mostrar: bool):
	if mostrar:
		if alerta_salto.visible: return # Ya se está mostrando
		alerta_salto.visible = true
		
		# Crear efecto de parpadeo "vivo"
		if tween_alerta: tween_alerta.kill() # Limpiar anterior
		tween_alerta = create_tween().set_loops() # Bucle infinito
		alerta_salto.modulate.a = 0.3 # Empezar un poco transparente
		
		# Va a rojo vivo en 0.4 seg y vuelve a transparente en 0.4 seg
		tween_alerta.tween_property(alerta_salto, "modulate:a", 1.0, 0.4)
		tween_alerta.tween_property(alerta_salto, "modulate:a", 0.3, 0.4)
	else:
		alerta_salto.visible = false
		if tween_alerta: tween_alerta.kill()
		
func _actualizar_interfaz(vida_actual: float):
	# 1. Actualizar Barra de Vida
	progress_bar.value = vida_actual
	
	# 2. Actualizar Filtro de Sangre (Opacidad según daño)
	var intensidad = 1.0 - (vida_actual / 100.0)
	var tween = get_tree().create_tween()
	tween.tween_property(filtro_sangre, "modulate:a", intensidad * 0.7, 0.4)
	
	# 3. Cambiar color de la barra si es crítico
	if vida_actual <= 25:
		progress_bar.modulate = Color.RED
	else:
		progress_bar.modulate = Color.WHITE
func mostrar_mensaje_accion(texto: String, mostrar: bool):
	mensaje_interaccion.text = texto
	mensaje_interaccion.visible = mostrar

func _on_muerte():
	# Efecto visual de muerte en el HUD
	var tween = get_tree().create_tween()
	tween.tween_property(filtro_sangre, "modulate:a", 1.0, 2.0)
	print("HUD: Jugador ha muerto")

# --- CONTROL DE INVENTARIO ---
func mostrar_inventario(valor: bool):
	inventario.visible = valor
	if valor:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

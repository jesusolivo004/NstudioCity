extends CanvasLayer
class_name HUDManager

# --- REFERENCIAS A HIJOS ---
@onready var filtro_sangre = $FiltroSangre
@onready var progress_bar = $ProgressBar
@onready var inventario = $Inventario
@onready var item_list_jugador = $Inventario/ItemList_Jugador
@onready var item_list_caja = $Inventario/ItemList_Caja
@onready var mensaje_interaccion = $MensajeInteraccion
@onready var alerta_salto = $AlertaSalto

@export var health_manager: HealthManager
var tween_alerta: Tween

func _ready():
	if health_manager:
		health_manager.al_cambiar_salud.connect(_actualizar_interfaz)
		health_manager.al_morir.connect(_on_muerte)
	item_list_caja.item_activated.connect(_on_item_caja_seleccionado)
	filtro_sangre.modulate.a = 0
	inventario.visible = false
	alerta_salto.visible = false

# Función para cuando abres la caja con E
func mostrar_inventario_loot(mostrar: bool, items: Array = []):
	inventario.visible = mostrar
	if mostrar:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		item_list_jugador.visible = true # Ves tu mochila
		item_list_caja.visible = true    # Ves el botín
		# ... (aquí el código para llenar los items que ya tienes)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Función para cuando presionas TAB (Inventario personal)
func mostrar_inventario_solo_jugador(mostrar: bool):
	inventario.visible = mostrar
	if mostrar:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		item_list_jugador.visible = true  # Ves tu mochila
		item_list_caja.visible = false    # OCULTAS la caja
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# --- ALERTAS Y EFECTOS ---
func mostrar_alerta_proximidad(mostrar: bool):
	if mostrar:
		if alerta_salto.visible: return
		alerta_salto.visible = true
		if tween_alerta: tween_alerta.kill()
		tween_alerta = create_tween().set_loops()
		tween_alerta.tween_property(alerta_salto, "modulate:a", 1.0, 0.4)
		tween_alerta.tween_property(alerta_salto, "modulate:a", 0.3, 0.4)
	else:
		alerta_salto.visible = false
		if tween_alerta: tween_alerta.kill()

func efecto_impacto_sangre(intensidad: float):
	var tween = create_tween()
	filtro_sangre.modulate.a = clamp(intensidad, 0.5, 1.0)
	tween.tween_property(filtro_sangre, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE)

func _actualizar_interfaz(vida_actual: float):
	progress_bar.value = vida_actual
	var intensidad = 1.0 - (vida_actual / 100.0)
	filtro_sangre.modulate.a = intensidad * 0.7
	progress_bar.modulate = Color.RED if vida_actual <= 25 else Color.WHITE

func mostrar_mensaje_accion(texto: String, mostrar: bool):
	mensaje_interaccion.text = texto
	mensaje_interaccion.visible = mostrar

func _on_muerte():
	create_tween().tween_property(filtro_sangre, "modulate:a", 1.0, 2.0)

func mostrar_inventario(valor: bool):
	inventario.visible = valor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if valor else Input.MOUSE_MODE_CAPTURED)
func _on_item_caja_seleccionado(index: int):
	# 1. Obtenemos el nombre y el icono del objeto que tocamos
	var nombre_item = item_list_caja.get_item_text(index)
	var icono_item = item_list_caja.get_item_icon(index)
	
	# 2. Lo añadimos a NUESTRO inventario (la lista del jugador)
	item_list_jugador.add_item(nombre_item, icono_item)
	
	# 3. Lo borramos de la caja (porque ya lo agarramos)
	item_list_caja.remove_item(index)
	
	# 4. Mensaje de confirmación en consola para estar seguros
	print("Recogiste: ", nombre_item)
	
	# Opcional: Si la caja queda vacía, cerramos el inventario
	if item_list_caja.get_item_count() == 0:
		mostrar_inventario_loot(false)

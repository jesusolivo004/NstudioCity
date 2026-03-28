extends StaticBody3D # O extends StaticBody3D, como lo tengas
class_name CajaDeLoot # <-- ESTA LÍNEA ES CLAVE

# --- El resto de tu código de la caja sigue igual ---
var botin = ["Botiquín", "Pistola", "Munición AR"]
var ya_abierto = false

func obtener_texto_interaccion():
	return "Presiona [E] para saquear"

func interactuar(hud):
	# Tu lógica de loot aquí
	hud.mostrar_inventario_loot(true, botin)

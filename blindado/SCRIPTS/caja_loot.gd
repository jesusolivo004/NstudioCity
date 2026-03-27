extends StaticBody3D

# Lista de items para Latido Crítico
var items = ["Rifle AK47", "Pistola 9mm", "Cuchillo Caza", "Botiquín", "Vendas", "Munición"]
var abierta = false

func abrir_caja():
	if abierta: return []
	abierta = true
	# Animación simple: podrías hacer que la tapa se mueva
	var loot = []
	for i in range(randi_range(2, 4)):
		loot.append(items.pick_random())
	return loot

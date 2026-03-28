#include "raylib.h"

struct Particulas{
	Vector2 posicion;
	Vector2 velocidad;
	float vida;
	float radio;
	bool activa;
};
	
int main(){
	InitWindow(640,480,"ParticleEngine");
	SetTargetFPS(60);
	
	const int MAX_PARTICULAS = 300;
	Particulas misParticulas[MAX_PARTICULAS];
	
	for(int i = 0; i < MAX_PARTICULAS;i++){
		misParticulas[i].activa = false;
	}
	
	while(!WindowShouldClose()) {
		if(IsMouseButtonDown(MOUSE_LEFT_BUTTON)) {
			int creadas = 0;
			for(int i = 0; i < MAX_PARTICULAS; i++ ){
				if(!misParticulas[i].activa && creadas < 1){
					misParticulas[i].activa = true;
					misParticulas[i].posicion = GetMousePosition();
					misParticulas[i].velocidad.x =  (float)GetRandomValue(-5,5);
					misParticulas[i].velocidad.y =  (float)GetRandomValue(-5,5);
					misParticulas[i].vida = 2.0f;
					misParticulas[i].radio = 7.0f;			
					creadas++;
				}
			}
		}
		for(int i = 0; i < MAX_PARTICULAS;i++){
			if(misParticulas[i].activa){
				misParticulas[i].posicion.x += misParticulas[i].velocidad.x;
				misParticulas[i].posicion.y += misParticulas[i].velocidad.y;
				misParticulas[i].velocidad.y -= 0.1f;
				if(misParticulas[i].vida <= 0) misParticulas[i].activa = false;
				misParticulas[i].radio -= 0.05f; 
				if (misParticulas[i].radio < 0) misParticulas[i].radio = 0;
			}
		}
		BeginDrawing();
			ClearBackground(DARKGRAY);
			for(int i = 0; i < MAX_PARTICULAS;i++){
				if(misParticulas[i].activa){
					Color colorParticula = (misParticulas[i].vida > 0.5f) ? BLUE : RED;
					DrawCircleV(misParticulas[i].posicion, misParticulas[i].radio, Fade(colorParticula, misParticulas[i].vida));
				}
			}
			DrawText("Empezando",20,10,20,YELLOW);
			DrawFPS(10,40);
		EndDrawing();
	}
	CloseWindow();
	return 0;
}
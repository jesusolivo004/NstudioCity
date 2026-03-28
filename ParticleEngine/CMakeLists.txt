cmake_minimum_required(VERSION 3.10)
project(ParticleEngine)

# Decimos dónde están los encabezados (.h)
include_directories(include)

# Decimos dónde está la librería (.a)
link_directories(raylib-5.5)

# Creamos el ejecutable con el código que está en src/
add_executable(ParticleEngine src/main.cpp)

# Enlazamos Raylib y las librerías necesarias de Windows
# (Importante: el orden importa)
target_link_libraries(ParticleEngine raylib opengl32 gdi32 winmm)
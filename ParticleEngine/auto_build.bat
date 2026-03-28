i@echo off
setlocal
:loop

:: --- CONFIGURACIÓN ---
:: Nombre del ejecutable que genera tu CMake (sin el .exe)
set EXE_NAME=ParticleEngine
:: Carpeta donde se guarda el ejecutable
set BIN_PATH=build\ParticleEngine.exe
:: ---------------------

cls
echo [MONITOR] Revisando estado del proyecto...

:: 1. Comprobar si el proceso ya está corriendo
tasklist /FI "IMAGENAME eq %EXE_NAME%.exe" 2>NUL | find /I /N "%EXE_NAME%.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo [INFO] El juego ya esta en ejecucion. Esperando 5 segundos...
    timeout /t 5 /nobreak >nul
    goto loop
)

:: 2. Si no esta corriendo, intentar compilar
echo [BUILD] El juego esta cerrado. Intentando compilar...
cd build
make
if "%ERRORLEVEL%"=="0" (
    echo [SUCCESS] Compilacion exitosa. Abriendo juego...
    start "" %EXE_NAME%.exe
    cd ..
) else (
    echo [ERROR] La compilacion fallo. Revisa tu codigo en main.cpp.
    cd ..
    echo [WAIT] Reintentando en 5 segundos...
    timeout /t 5 /nobreak >nul
)

goto loop
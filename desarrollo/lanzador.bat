@echo off
title Console64 - Gestor de Lanzamiento
color 0B

echo ==========================================
echo       CONSOLE64 - MOTOR DE ARRANQUE
echo ==========================================
echo.

:: Verificamos si se arrastro una ROM al script
if "%~1"=="" (
    echo [!] No se ha seleccionado ningun juego.
    echo [*] Arrastra un archivo .z64 aqui o configuralo en el sistema.
    goto menu
) else (
    goto cargar_juego
)

:cargar_juego
echo [+] ROM detectada:
echo     %~1
echo.
echo [+] Buscando nucleo del emulador en almacen...
:: Aqui es donde luego conectaremos la llamada al nucleo o emulador base
echo [OK] Preparando entorno para iniciar juego...
pause
exit

:menu
echo.
echo Opciones disponibles:
echo 1. Ver ROMs en almacen
echo 2. Salir
echo.
set /p opcion="Elige una opcion (1-2): "
if "%opcion%"=="1" (
    start explorer "%~dp0..\almacen\ROMs"
) else (
    exit
)
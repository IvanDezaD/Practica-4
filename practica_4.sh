#!/bin/bash

#funcion que simplemente muestra informacion
info() {
  echo -e "[#] $1"
}

#funcion que indica que algo ha ido bien
okay() {
  echo -e "[+] $1"
}

#Funcion que imprime por la salida de error
error() {
  echo -e "[-] $1" &>2
}

#Recibimos el nombre de un fichero y tenemos que devolver una lista de ips
leerFicheroMaquinas() {
  echo 
}

#Recibimos el nombre de un fichero y devolvemos 1 si existe y 0 si no existe
comprobarFichero() {
  echo 
}

#Barra de progreso
updateProgressBar() {
    local animation=( '>' '=' '=' '=' '=' '=' '=' '=' )
    local msg="$1"
    printf "\r\033[1;34m[%s%s%s%s%s%s%s%s]\033[0m %s" "${animation[index]}" "${animation[(index + 7) % 8]}" "${animation[(index + 6) % 8]}" "${animation[(index + 5) % 8]}" "${animation[(index + 4) % 8]}" "${animation[(index + 3) % 8]}" "${animation[(index + 2) % 8]}" "${animation[(index + 1) % 8]}" "$msg"
    ((index = (index + 1) % 8))
}

main() {
    index=0
    while true; do
        updateProgressBar "Añadiendo usuarios!"
        sleep 0.1 # Simula algo de trabajo
    done
}

main

#Tenemos 2 opciones, llamar al script de la practica 3 desde este, cambiando y simplificando cosas
main2() {
  leerFicheroMaquinas
  echo "Esto es la funcion main"
}


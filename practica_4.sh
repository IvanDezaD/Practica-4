#!/bin/bash

readonly time=4

function ctrl_c() {
    echo "Saliendo abruptamente!"
    exit 1
}

trap ctrl_c SIGINT

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
  exit 1
}

#Recibimos el nombre de un fichero y tenemos que devolver una lista de ips leidas (cadena separada por ";")
leerFicheroMaquinas() {
  local archivo="$1"
  local lista=()

  while IFS= read -r linea || [[ -n "$linea" ]]; do
    lista+=("$linea")
  done < "$archivo"

  printf '%s;' "${lista[@]}"
}

while getopts ":ash" opt; do
  case $opt in
  a)
    mode="Delete"
    info "Borrando los usuarios"
    ;;
  s)
    mode="Append"
    info "Añadiendo a los usuarios"
    ;;
  h)
    help
    exit 0
    ;;
  *)
    echo "Opcion no valida" >&2
    exit 1
    ;;
  esac
done

shift $((OPTIND -1))

#Recibimos el nombre de un fichero y devolvemos 1 si existe y 0 si no existe
comprobarFichero() {
  local file=$1
  if [[ -e "$file" ]]; then
    echo true
  else
    echo false
  fi
}

ipCheck(){
  local ip=$1
  local ip_regex='^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
  if [[ $ip =~ $ip_regex ]]; then
    echo "true"
  else
    echo "false"
  fi
}

#sube  por scp el script a la maquina de una ip dada
#recibimos ip, devolvemos true si ha salido bien y false si no
scpUpload() {
  local ip=$1
  local file=$2
  local user=$3
  scp -o ConnectTimeout=$time "$file" "$user"@"$ip":/tmp/"$file" &>/dev/null
  if [[ $? -eq 0 ]]; then
    echo "Fichero $file subido con exito a la maquina $ip" 
  else
    echo "$ip no fue accesible"
  fi
}

#Ejecutamos el script remotamente
remoteExecute() {
  local ip=$1
  local file=$2
  local user=$3
  local mode=$4
  ssh -o ConnectTimeout=$time "$user"@"$ip" "./practica_3.s -$mode $file"&>/dev/null
}

executeScript() {
  local cadena=$1
  local file=$2
  local user=$3
  local mode=$4
  OLD_IFS=$IFS
  IFS=';'
  for componente in $cadena; do
    local status=$(ipCheck $componente)
    if [[ $status == "true" ]]; then
      scpUpload "$componente" "$file" "$user"
      if [ $? -eq 1 ]; then
        remoteExecute "$componente" "$file" "$user" "$mode"
      fi
    else
      echo "La linea no tiene formato de ip: $componente"
    fi
  done
  IFS=$OLD_IFS
}

main() {
  local file=$1
  local machines=$2
  local status=$(comprobarFichero "$file")
  local status2=$(comprobarFichero "$machines")
  if [[ $status == "true" && $status2 == "true" ]]; then
    local ipList=$(leerFicheroMaquinas "$machines")
    if [[ $mode == "Append" ]]; then
      executeScript "$ipList" "$file" "as" "s"
    else
      executeScript "$ipList" "$file" "as" "a"
    fi
  else
    echo "Uno de los 2 ficheros no fue especificado o no existe!"
  fi
}

main "$1" "$2"

#!/bin/bash
#837603


ROJO="\e[0;31m"

#Si el verbose esta activado imprime [LOG] "<info>" donde info es el primer parametro
log(){  if [[ $LOG == 1 ]]; then
    echo -e "[\e[0;35m*\e[0m] $1" >&2
  fi
}

echoerr(){
  echo -e "$ROJO[-] $1!\e[0m" >&2
} 

#La funcion recibe como primer parametro el nombre del usuario a crear y comprueba si existe en el etc passwd.
#Devuelve true si esta disponible el username y false si esta ocupado
isUserAvailable(){
  log "Comprobando que el usuario $1 esta disponible"
  isAvailable="True"
  
  grep ^$1 /etc/passwd &>/dev/null #Ejecutamos el comando y si es exitoso, el codigo de estado sera 0 con lo cual si es diferente de 0 esto es que ha ido mal

  if [[ $? -eq 0 ]]; then
    local isAvailable="False" #Asi que devolveremos false (aqui cambiamos el valor de la variable de retorno)
  else
    log "El usuario $1 esta disponible para ser añadido"
  fi
  echo $isAvailable #Para aqui retornarla
}
banner() {
  echo -e "\033[0;34m _   _                ___  _     _ \033[0m"
  echo -e "\033[0;34m| | | |              / _ \| |   | |\033[0m"
  echo -e "\033[0;34m| | | |___  ___ _ __/ /_\ \ | __| |\033[0m"
  echo -e "\033[0;34m| | | / __|/ _ \ '__|  _  | |/ _\` |\033[0m"
  echo -e "\033[0;34m| |_| \__ \  __/ |  | | | | | (_| |\033[0m"
  echo -e "\033[0;34m \___/|___/\___|_|  \_| |_/_|\__,_|\033[0m"
  echo
  echo "By: Ivan Deza and David Hudrea"
  echo 
}

#Imprime el menu de ayuda del script
help() {
  echo -e "Menu de ayuda para la practica 3 de Administracion de sistemas: "
  echo -e "./practica3.sh [-a[v] | -s[v]] <fichero>  [-h]"
  echo -e "-a       Crea los usuarios de la lista."
  echo -e "-s       Borrar los usuarios de la lista <Danger>"
  echo -e "-v       Activa el modo verbose donde se pueden ver los logs de el programa"
  echo -e "-h       Imprime este menu de ayuda."
}

#Hacemos un backup, si aparece cualquier tipo de error lo mostramos por pantalla y no borraremos al usuario.
makeBackup(){
  local user=$1
  log "Iniciando backup del usuario $user"
  if [ ! -d /extra/backups ]; then
    mkdir -p /extra/backups #Si no existe el directorio lo creamos
  fi
  tar -cvzf "/extra/backups/$user.bak.gz" "/home/$user" &>/dev/null
  if [[ $? != 0 ]]; then 
    echoerr "Problema realizando el backup a $user, abortando!"
    echo "False"
  else
    log "Backup realizado: /home/$user, ahora en: /extra/backups/$user.bak.gz"
    echo "True"
  fi
}

#Recibimos el usuario a eliminar
delUser() {
  local user=$1
  local status=$(makeBackup "$user")
  if [[ $status == "False" ]]; then
    echoerr  "[-] Ha habido algun problema eliminando al usuario: $user"
  else
    userdel "$user"
    log "Usuario $user borrado"
    rm -rf "/home/$user"
    log "Directorio /home/$user eliminado."
  fi
}

#Recibimos 3 parametros, el nombre de usuario, el uid que se le asignara y la contrasÃ±a temporal
addUser() {
  local newUser=$1
  local pass=$3
  local fullName=$2

  log "Añadiendo al usuario $user"
  useradd -m -k /etc/skel -K UID_MIN=1815 -K PASS_MAX_DAYS=30 -c "$fullName" -U "$newUser" 2>/dev/null
   
  log "Usuario, $newUser, creado, "
}

#Recibimos la linea y el numero de linea, si es correcto devolvemos true, si es incorrecto, devolveremos false y mostraremos un error
checkLineHealth() {
  local firstParam=$1
  local nLinea=$2
  log "Comprobando que la linea $nLinea tiene el numero de parametros correcto"
  local success="True"
  numParams=$(echo $linea | awk -F "," '{print NF}')
  if [[ $numParams -ne 3 ]]; then
    echoerr "El numero de parametros es incorrecto en la linea $nLinea, no se añadira a este usuario"
    local success="False"
  else
    log "La linea $nLinea tiene el numero de parametros correcto."
  fi
  echo $success
}

while getopts ":vash" opt; do
  case $opt in
  v)
    LOG=1
    log "Verbose activado."
    ;;
  a)
    mode="Append"
    log "Anadiendo los usuarios"
    ;;
  s)
    mode="Delete"
    log "Borrando a los usuarios"
    ;;
  h)
    help
    exit 0
    ;;
  *)
    echoerr "Opcion no valida" >&2
    help
    exit 1
    ;;
  esac
done

shift $((OPTIND -1))

#Comprueba que se ha ejecutado el script con permisos de root
checkId () {
  local id=$(id -u)
  log "UID: $id"
  
  local isRoot="True"
  if [[ $id -ne 0 ]]; then
    echoerr "El script no tiene permisos de superusuario."
    echo -n "False"
  fi
  echo $isRoot
}

#Comprueba que el numero de parametros sea el correcto (2)
checkParams() {
  log "Comprobando el numero de parametros recibidos"
  log "Fichero recibido: $1"
  if [[ "$1" == "" ]]; then
    log "Numero de parametros incorrecto, recibidos: $#"
    echoerr "Parece que no has proporcionado fichero, proporciona uno!"
    help
    log "Saliendo"
    exit 1
  fi
}

#Comprueba que el script no va a fallar por temas de ficheros
checkHealth(){
  log "Comprobando el estado de los ficheros necesarios."
  local isHealthy="True"
  
  if [[ ! -f /etc/passwd ]]; then #Comprobamos que existe el etc passwd
    isHealthy="False"
    echoerr "El fichero /etc/passwd no existe, contacta con un administrador."
  fi

  if [[ -d /etc/skel ]]; then #Comprobamos que el directorio etc/skel exista
    isHealthy="False"
    echoerr "El directorio /etc/skel no existe contacta con un administrador."
  fi
  echo "$isHealthy"
}

main(){
  banner
  local file=$1
  log "El fichero es $file"
  checkParams "$file" #Comprobamos que el numero de parametros es correcto
  log "Añadiendo a los usuarios especificados en el fichero $file"
  local id=$(checkId) #Comprobamos que se ejecuta con permisos de superUsuario
  if [[ $id == "False" ]]; then
    echoerr "[-] El script necesita permisos de superusuario!!"
    exit 1
  fi
  
  local iter=0
   while IFS= read -r linea; do #Leemos el fichero linea a linea, ahora usando la primera linea deberemos comprobar que el archivo es sano.
    ((iter++))
    log "Numero de usuario a añadir: $iter"
    log "Linea leida del fichero: $linea"
    if [[ $mode == "Append" ]]; then
        local user=$(echo $linea | awk -F "," '{print$1}') #Nuestro usuario sera el primer parametro de la linea
        local passwd=$(echo $linea | awk -F "," '{print$2}') #La contraseÃ±a aponer sera sencillamente el tercer parametro
        local fullName=$(echo $linea | awk -F "," '{print$3}') #Nuestro pid sera el segundo parametro de la lista
        
        log "Usuario a añadir es $user, con la contraseña $passwd y con fullName $fullName"
        local status=$(checkLineHealth "$linea" $iter)
        
        if [[ $status == "True" ]]; then
          local status=$(isUserAvailable "$user")
          if [[ $status == "True" ]]; then
            addUser "$user" "$fullName" "$passwd" #Añadimos al usuario con los parametros correctos
          else
            echoerr "El usuario $user ya existe"
          fi
        fi
    else
      local user=$(echo $linea | awk -F "," '{print$1}') #Nuestro usuario sera el primer parametro de la linea 
      status=$(isUserAvailable "$user")
      if [[ $status == "False" ]]; then #&>/dev/null; then #Hacemos la misma comprobacion para ver que exista .
        log "El usuario a borrar es $user"
        delUser "$user"
        log "Elimininando al usuario $user"
      else
        echoerr "El usuario $user no existe."
      fi
    fi
  done < "$file"
}
main $1

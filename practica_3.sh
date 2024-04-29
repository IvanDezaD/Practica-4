#!/bin/bash

ROJO="\e[0;31m"

#Si el verbose esta activado imprime [LOG] "<info>" donde info es el primer parametro
log(){  if [[ $LOG == 1 ]]; then
    echo -e "[\e[0;35mLOG\e[0m] $1" >&2
  fi
}

echoerr(){
  echo -e "$ROJO$1!\e[0m" >&2
} 

#La funcion recibe como primer parametro el nombre del usuario a crear y comprueba si existe en el etc passwd.
#Devuelve true si esta disponible el username y false si esta ocupado
isUserAvailable(){
  log "Comprobando que el usuario $1 esta disponible"
  isAvailable="True"
  
  grep ^$1 /etc/passwd #Ejecutamos el comando y si es exitoso, el codigo de estado sera 0 con lo cual si es diferente de 0 esto es que ha ido mal

  if [[ $? -eq 0 ]]; then
    local isAvailable="False" #Asi que devolveremos false (aqui cambiamos el valor de la variable de retorno)
    echoerr "El usuario $1 ya existe"
  fi
  echo $isAvailable #Para aqui retornarla
}

#Imprime el menu de ayuda del script
help() {
  echo -e "Menu de ayuda para la practica 3 de Administracion de sistemas: "
  echo -e "./practica3.sh [-a | -s] <fichero> [-v] [-h]"
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
    mkdir -p /extra/backups
  fi
  tar -czvf "/extra/backups/$user.bak.gz" -C "/home/$user" -P
  if [[ $? != 0 ]]; then 
    log "Problema realizando el backup a $user, abortando!"
    echo "False"
  else
    log "Backup realizado: /home/$user, ahora en: /extra/backups/$user.bak.gz"
    echo "True"
  fi
}

#Recibimos el usuario a eliminar
delUser() {
  local user=$1
  local status=$(makeBackup $user)
  if [[ $status != 0 ]];
    echoerr  "[-] Ha habido algun problema eliminando al usuario: $user"
  else
    deluser "$user"
    log "Usuario $user borrado"
    rm -rf "/home/$user"
    log "Directorio /home/$user eliminado."
}

#Recibimos 3 parametros, el nombre de usuario, el uid que se le asignara y la contrasña temporal
addUser() {
  local newUser=$1
  local pass=$3
  local group=$2
  log "Añadiendo al usuario $user"
  useradd "$newUser" #Añadimos al nuevo usuario 
  log "Usuario, $newUser, creado"
  usermod -u 1815 "$newUser" #Cambiamos el uid a 1815
  log "Asignado el uid de: 1815, al usuario $newUser"
  usermod -aG "$group" "$newUser"
  mkdir /home/"$newUser"
  log "Creado el directorio /home/$newUser"
  cp -r /etc/skel/* /home/$newUser # Copiamos el directorio etc skel al directorio principal del usuario.
  log "Copiado el directorio /etc/skel/ a /home/$newUser"
}

#Recibimos la linea y el numero de linea, si es correcto devolvemos true, si es incorrecto, devolveremos false y mostraremos un error
checkLineHealth() {
  local linea=$1
  local nLinea=$2
  log "Comprobando que la linea $nLinea tiene el numero de caracteres correcto"
  local params=$(wc $linea -w | awk '{print$1}') #Esto es el numero de parametros en la linea del fichero.
  log "La linea $nLinea tiene: $params parametros."
  local success="False"
  if [[ $params -ne 3 ]]; then
    echoerr "El numero de parametros es incorrecto en la linea $nLinea"
    local success="False"
  fi
  log "La linea: $nLinea; tiene los parametros correctos."
  echo $success
}

while getopts ":vash" opt; do
  case $opt in
  v)
    LOG=1
    log "Verbose activado."
    ;;
  a)
    mode="Delete"
    log "Borrando los usuarios"
    ;;
  s)
    mode="Append"
    log "Añadiendo a los usuarios"
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

#Comprueba que se ha ejecutado el script con permisos de root
checkId () {
  local id=$(id -u)
  log "UID: $id"
  
  local isRoot="True"
  if [[ id -ne 0 ]]; then
    log "El script no tiene permisos de superusuario."
    echo -n "False"
  fi
  echo $isRoot
}

#Comprueba que el numero de parametros sea el correcto (2)
checkParams() {
  log "Comprobando el numero de parametros recibidos"
  log "Numero de parametros = $#"
  if [[ "$#" -ne 2]]; then
    echo "False"
    log "Numero de parametros incorrecto, recibidos: $#"
  else
    echo "True"
  fi
}

#Comprueba que el script no va a fallar por temas de ficheros
checkHealth(){
  log "Comprobando el estado de los ficheros necesarios."
  local isHealthy="True"
  
  if [[ ! -f /etc/passwd ]]; then #Comprobamos que existe el etc passwd
    isHealthy="False"
    log "El fichero /etc/passwd no existe, contacta con un administrador."
  fi

  if [[ -d /etc/skel ]]; then #Comprobamos que el directorio etc/skel exista
    isHealthy="False"
    log "El directorio /etc/skel no existe contacta con un administrador."
  fi
  echo "$isHealthy"
}

#Funcion main
main(){
  local file=$1
  log "El fichero es $1"
  local status=$(checkParams) #Comprobamos que el numero de parametros es correcto

  local id=$(checkId) #Comprobamos que se ejecuta con permisos de superUsuario
  if [[ $id == "False" ]]; then
    echoerr "[-] El script necesita permisos de superusuario!!"
    exit 1
  fi
  
  local iter=0
   while IFS= read -r linea; do #Leemos el fichero linea a linea, ahora usando la primera linea deberemos comprobar que el archivo es sano.
    iter=((iter++))
    if [[ $mode == "Append" ]]; then
      local status=$(checkLineHealth "$linea" $iter)
      if [[ status == "True" ]]; then
        local passwd=$(awk '{print$2}' linea) #La contraseña aponer sera sencillamente el tercer parametro
        local user=$(awk '{print$3}' linea) #Nuestro usuario sera el primer parametro de la linea
        local group=$(awk '{print$1}' linea) #Nuestro pid sera el segundo parametro de la lista
        
        if isUserAvailable "$user"; then #Comprobamos que el usuario existe y si es asi lo añadimos
          log "Usuario a añadir: $user; id del usuario: $id; contraseña temporal del usuario: $passwd"
          addUser "$user" "$group" "$passwd" #Añadimos al usuario con los parametros correctos
          log "Usuario: $user; añadido."
        else
          echoerr "[-] El usuario $user ya existe"
        fi
      else
        if ! isUserAvailable "$user"; then #Hacemos la misma comprobacion para ver que exista .
      
          delUser "$user"
          log "Elimininando al usuario $user"
        
        else
          echoerr "El usuario $user no existe."  
        fi
      fi
    fi
  done
}

main $2

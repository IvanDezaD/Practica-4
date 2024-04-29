# Practica 4 de Administracion de Sistemas

## Administracion de usuarios de manera remota en varias maquinas.

### Configuracion de Red

---

### Script

Este script es bastante sencillo en esencia pero hemos decidido incorporar un par de sencillas comprobaciones que nos ayuden a que sea mas seguro de usar y se vea de manera mas clara cuando esta fallando
Lo primero que hemos incorporado ha sido que cada vez que lee una ip del fichero de maquinas, comprueba que el formato de ip es valido, de esta manera si hay erratas en el fichero sera mas facil de ver y depurar
El segundo cambio que hemos introducido han sido tiempos de timeout personalizados. De esta manera podemos correr mas rapidamente el script si en algun momento la conexion es lenta. Luego es muy facil cambiar el tiempo de timeout ya que es una "constante global"
```bash
ipCheck(){
  local ip=$1
  local ip_regex='^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
  if [[ $ip =~ $ip_regex ]]; then
    echo "true"
  else
    echo "false"
  fi
}
```
Si el regex encaja, significa que es una ip, de esta manera si el fichero esta corrupto, o no se introdujo el fichero que se deberia se podra ver de manera clara.
Los tiempos de timeout estan definidos de la siguiente manera:
```bash
readonly time=4
scp -o ConnectTimeout=$time "$file" "$user"@"$ip":/tmp/"$file" &>/dev/null

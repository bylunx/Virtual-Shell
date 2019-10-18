#!/usr/bin/env bash

function verifyIP() {
  [[ $1 =~ ^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$ ]] && echo "l'ip est pas bonne" && exit 1
  [[ $2 =~ ^[5-6]|[0-9]\{1,4\}$ ]] && echo "le port n'est pas bon" && exit 1
}

# function verifyArchive() {
#oui
# }


ls (){
    if [[ ! $1 =~ ^(|\./?)$ ]]; then
      awk "/directory ${1//\//\\/}/{flag=1;next}/@/{flag=0}flag" archive  #Permet de parser toutes les lignes et d'affichier ce qui a entre 2 strings
    fi
}



function ParList() {
  verifyIP "$1" "$2"
  echo "Voici la liste des archives présentes sur le serveur : "
  netcat "$1" "$2"
}

function ParBrowse() {
  verifyIP "$1" "$2"
  netcat "$1" "$2" > archive
  path=""
  echo -n "vsh:>"
  # verifyArchive archive "$1" "$2"

  while true; do
    read cmd param

    case $cmd in
      "ls" ) ls $param
        ;;
    esac

    echo -n "vsh:>$path"
  done

}



case $1 in
  -l|--list) ParList "$2" "$3"
  ;;
  -b|--browse) ParBrowse "$2" "$3"
  ;;
  -e|--extract) ParExtract
  ;;
  *) echo "Aucun parametre" || exit 1
esac



function ParExtract() {
true
}

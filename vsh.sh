#!/usr/bin/env bash
nom_serveur=$2
port=$3
nom_archive=$4






function extract() {
  archive="$1"
  arch_start_file=$(egrep -o "[0-9]{1,}:[0-9]{1,}$" $archive | cut -d ":" -f2)
  chemin=""
  flag=0
  while read line; do

    if [[ $line =~ @ ]]; then
      flag=0
      chemin=""
    fi

    if [[ $line =~ ^directory ]]; then
      directory=$(echo $line | cut -d " " -f2)
      allrep=$(echo $directory | sed "s/\// /g")

      for rep in $allrep; do
        [ -z $chemin ] && chemin="$rep" || chemin="$chemin/$rep"
        [ -d $chemin ] || mkdir $chemin; echo "Création du répertoire $chemin"
      done

      flag=1

      elif [[ $flag -eq 1 ]]; then

        file=${chemin}/$(echo $line | cut -d " " -f1)
        droit=$(echo $line | cut -d " " -f2)
        declare -a tab_droit=("${droit:1:3}" "${droit:4:3}" "${droit:7:3}")

        if [[ ! $droit =~ ^d ]]; then
          [ -e $file ] || touch "$file"
          echo -e "->Création du fichier $file avec les droits suivant : $droit"
          if [[ ! $(echo $line | cut -d " " -f3) == 0 ]]; then
                let "start = $(echo $line | cut -d " " -f4) + arch_start_file - 1"
                let "nb_line_file = start + $(echo $line | cut -d " " -f5) - 1"
                cat "$archive" | sed -n "${start},${nb_line_file}p" > $file
          fi
          chmod u=${tab_droit[0]//-/},g=${tab_droit[1]//-/},o=${tab_droit[2]//-/} $file
        else
        [ -d $file ] || mkdir $file; echo "Création du répertoire $chemin"
        chmod -R u=${tab_droit[0]//-/},g=${tab_droit[1]//-/},o=${tab_droit[2]//-/} $file
        fi
    fi
  done < "$archive"
}


case $1 in
  -l|-list) cat <(echo "list") - | netcat -w 1 $nom_serveur $port
  ;;
  -b|-browse) cat <(echo "browse $nom_archive") - | netcat $nom_serveur $port
  ;;
  -e|-extract) archive="/tmp/archive_compresse"
  echo "Appuyer sur ENTRÉE pour extraire l'archive : "
  cat <(echo "extract $nom_archive") - | netcat -w 1 $nom_serveur $port > "/tmp/archive_compresse"
  extract "$archive"
  rm "/tmp/archive_compresse"
  ;;
  *) echo "Aucun parametre" || exit 1
esac

# rm "/tmp/archive_compresse"
# cat <(echo "extract $nom_archive") - | netcat $nom_serveur $port

#!/usr/bin/env bash

PORT=$1

#Variable qui permet dans quel archive on est en train de parcourir
archiveCourant=""
cheminArchiveCourant="archives/$archiveCourant"

#Repertoire courant
repertoireCourant=""
racine=""

FIFO="/tmp/$USER-fifo-$$"

function nettoyage() {
  rm -f "$FIFO"
}
trap nettoyage EXIT

[ -e "$FIFO" ] || mkfifo "$FIFO"

function lancer-boucle(){
    echo "Ecoute sur le port $PORT"
    interaction < "$FIFO" | netcat -k -l -p $PORT > $FIFO
}

function interaction(){
  local cmd args
  while true; do
    echo -n "vsh:$repertoireCourant> "
    read cmd args || exit -1
    fonction="cmd-$cmd"
    if [ "$(type -t $fonction)" = "function" ]; then
      $fonction $args
    else
      echo "Commande non reconnue"
    fi
  done
}

#COMMANDES UTILISATEURS

function cmd-list(){
  echo "-> Liste des archives présentes sur le serveur :"
  ls ./archives
  echo -e "\nTaper sur la touche ENTRÉE pour quitter"

}


function cmd-extract(){
  if [[ "$1" = "" ]]; then
    echo "Vous devez entrer une archive"
  elif [[ $(ls ./archives | egrep "^$1$") = "$1" ]]; then
  cat "archives/$1"
fi
}

function cmd-browse(){

  if [[ "$1" = "" ]]; then
    echo "Vous devez entrer une archive"
  elif [[ $(ls ./archives | egrep "^$1$") = "$1" ]]; then
    archiveCourant=$1
    cheminArchiveCourant="archives/$archiveCourant"
    echo "--> Archive courante : \"$archiveCourant\" <-- "

    if [[ $racine != $(getRacine) ]]; then
      racine=$(getRacine)
      cmd-cd $racine
    fi
  else
    echo "L'archive \"$1\" n'existe pas."
  fi
}

function cmd-cat() {
  arch_start_file=$(egrep "^[0-9]{1,}:[0-9]{1,}$" $cheminArchiveCourant | cut -d ":" -f2)

  file=$(fileExist "$1")
  echo $file
  if [[ -z "$file" ]]; then
    echo "cat: $1: Aucun fichier ou dossier de ce type"
  else
    let "start = $(echo $file | cut -d " " -f4) + arch_start_file - 1"
    let "nb_line_file = start + $(echo $file | cut -d " " -f5) - 1"
    if [[ ! $(echo $file | cut -d " " -f3) -eq 0 ]]; then
      sed -n "${start},${nb_line_file}p" < "archives/$archiveCourant"
    fi
  fi
}

function cmd-pwd(){
    echo $repertoireCourant
}

function cmd-ls(){
  getListeFichiers "$(echo "$(getCheminAbsolu $1)/")"
}

function cmd-cd(){
  local chemin=$1
  verification=$(verifierChemin $chemin)
  if [[ $verification == "ok" ]]; then
    repertoireCourant=$(getCheminAbsolu $chemin)
  else
    echo $verification
  fi
}

function cmd-rm(){
  local fichier=$1

  verification=$(fileExist $fichier)
  if [[ $verification = "" ]]; then
    echo "rm : '$fichier' : Aucun fichier ou dossier de ce type"
  else
    rmRecursive $1
  fi

}
#FIN COMMANDES UTILISATEURS

#FONCTIONS INTERNES POUR NOUS

function rmRecursive(){
  local fichier fichierHeader ligneHeader listeFichiers ligneFichierHeader reg

  fichier="$1"
  fichierHeader="$(fileExist $fichier)"

  regexIsDirectory="^.+ d.+$"


  if [[ $fichierHeader =~ $regexIsDirectory ]]; then #Si le fichier sur lequel on loop est un dossier ou pas
    listeFichiers=$(getFichiersRepertoire $fichier)
    ligneFichierHeader=$(fileExist $fichier -n)

    for f in $listeFichiers; do
      rmRecursive "$fichier/$f"
    done

    supprimerRepertoire $fichier $ligneFichierHeader

  else
    supprimerFichier $fichier
  fi
}

function supprimerRepertoire(){
  supprimerLigne $2
  setDebutBody -1 add

  #SUPPRIME LE directory et @
  reg=$(getCheminAbsolu $1 | sed 's/\//\\&/g')
  reg="^directory ${reg}$"
  sed -i "/$reg/ { N; d; }" $cheminArchiveCourant
  setDebutBody -2 add
}


function getFichiersRepertoire(){
  local repertoire regexChemin
  repertoire="$1"
  regexChemin="^directory $(getCheminAbsolu ${repertoire})(\/|)$"
  #Transforme les fichiers du repertoire sous forme de liste
  awk -v regexChemin="$regexChemin" '$0 ~ regexChemin {while($0 != "@"){ getline; if($0 != "@") printf "%s ", $1; }}' $cheminArchiveCourant 2>/dev/null
}

function supprimerFichier(){
  local fichier fichierHeader numeroLigne nbLigne debutBody ligneHeader

  fichier="$1"
  fichierHeader="$(fileExist $fichier)"
  ligneHeader="$(fileExist $fichier -n)"
  numeroLigne="$(echo $fichierHeader | awk '{printf $4}')" #4EME CHAMP = #LIGNE DANS LE BODY
  nbLigne="$(echo $fichierHeader | awk '{printf $5}')" #5EME CHAMP = NOMBRE LIGNES

  debutBody=$(getDebutBody)
  numeroLigneAbsolu=$(( $numeroLigne + $debutBody ))

  supprimerLigne $numeroLigneAbsolu $(($numeroLigneAbsolu+$nbLigne))
  supprimerLigne $ligneHeader

  #Retire le nombre de lignes supprimées
  setDebutBody "-1" add

  awk -i inplace -v finHeader="$debutBody" -v numeroLigne="$numeroLigne" -v nbLigne="$nbLigne" 'NR<finHeader && NF==5 && $4>numeroLigne {$4 = $4-nbLigne} {print}' $cheminArchiveCourant
}


#Supprime la ligne $1 de l'archive courante ou de la ligne $1 à la ligne $2
function supprimerLigne(){
  if [[ $# == 2 ]]; then
    sed -i "$1,$2 d" $cheminArchiveCourant
  else
    sed -i "$1 d" $cheminArchiveCourant
  fi

}

#Obtient la ligne de début du body
function getDebutBody(){
  echo "$(awk -F":" 'NR==1 {print $2}' $cheminArchiveCourant)"
}

#Modifie la ligne de début du body
function setDebutBody(){
  if [[ $2 == "add" ]]; then
    awk -i inplace -v r="$1" 'BEGIN{FS=OFS=":"} {if(NR==1) $2=$2+r} {print $0}' $cheminArchiveCourant
  else
    awk -i inplace -v debutBody="$1" 'BEGIN{FS=OFS=":"} {if(NR==1) $2=debutBody} {print $0}' $cheminArchiveCourant
  fi
}

# option $2: -n pour renvoyer le numéro de la ligne
function fileExist() {
  fichier="$1"

  chemin=$(getCheminAbsolu $fichier)

  rep=$(echo $chemin | egrep -o "^([a-zA-Z0-9]+\/){1,}" | sed "s/\/$//")
  fichier=$(echo $chemin | egrep -o "[a-zA-Z0-9]+$")
  rep="^directory ${rep}(\/|)$"

  if [[ $2 = "-n" ]]; then
    awk -v path="${rep}" -v fichier="${fichier}" '$0 ~ path {flag=1} $0 ~ "@" && flag {flag=0}
    {if ($1 == fichier && flag) printf NR;}' archives/$archiveCourant 2>/dev/null
  else
    awk -v path="${rep}" -v fichier="${fichier}" '$0 ~ path {flag=1} $0 ~ "@" && flag {flag=0}
    {if ($1 == fichier && flag) printf $0;}' archives/$archiveCourant 2>/dev/null
  fi
}

function getListeFichiers(){
  if [[ ! $1 =~ ^(|\./?)$  ]]; then
    rep=${1:0:${#1}-1}
    rep=${rep//\//\\/}
    awk -v path="^directory ${rep}(\/|)$" '$0 ~ path {flag=1} $0 ~ "@" && flag {exit 1}
        {if (substr($2, 0, 1) == "d" && flag) printf "%s\/ ",$1;
        else if (substr($2, 4, 1) == "x" && substr($2, 0, 1) == "-" && flag) printf "%s* ",$1;
        else if (substr($2, 0, 1) == "-" && flag) printf "%s ",$1; }
        END {printf "\n"}' archives/$archiveCourant 2>/dev/null  #Permet de parser toutes les lignes et d'affichier ce qui a entre 2 strings
  fi
}

function getRepertoirePrecedent(){
  if [[ $1 == "" ]]; then
    echo $repertoireCourant | sed "s/\(.*\)\/.*/\1/g"
  else
    echo $1 | sed "s/\(.*\)\/$/\1/g" | sed "s/\(.*\)\/.*/\1/g" #Retire le dernier champ
  fi
}

function getRepertoireSuivant() {
  if [[ $2 == "" ]]; then
    echo "$1"
  else
    echo "$1/$2"
  fi
}

function getCheminAbsolu(){
  local cheminAbsolu
  cheminRelatif=$(echo "$repertoireCourant/$1")
  cheminListe=$(echo $cheminRelatif | sed 's/\([^/]*\)\//\1 /g') #Retire les /

  cheminAbsolu=""
  for repertoire in $cheminListe; do
    if [[ $repertoire = ".." ]]; then
      cheminAbsolu=$(getRepertoirePrecedent $cheminAbsolu)
    elif [[ ! $repertoire = "." ]]; then
      cheminAbsolu=$(getRepertoireSuivant $cheminAbsolu $repertoire)
    fi
  done

  echo $cheminAbsolu
}

function verifierChemin(){
  local chemin
  chemin=$1
  listeFichiers=$(cmd-ls $chemin)

  if [[ $listeFichiers == "" ]]; then
    echo "'$chemin' : Aucun fichier ou dossier de ce type"
  else
    echo "ok"
  fi
}

function getRacine(){
  local debutHeader
  debutHeader=$(head -1 $cheminArchiveCourant | cut -d: -f1)

  echo "$(awk -v ligne="$debutHeader" 'NR==ligne {print $2 ; exit}' archives/archive1)"
}

lancer-boucle

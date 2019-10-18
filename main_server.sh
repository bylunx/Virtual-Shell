#!/usr/bin/env bash
#POUR TESTER SI UN PORT EST DISPO
# nc -vn 192.168.233.208 5000

#Pour l'option list
# echo "$(ls "./archives")" | nc -l 4444

#Pour l'option browse
netcat -l 4444 < "./archives/archive1"

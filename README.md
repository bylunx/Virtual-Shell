# Virtual-Shell

Virtual-Shell is a archive server tool (bash). The server must contains some archives (the format is a home made one).
What you can do :

+ Get the archive list on the server
+ Extract the archives from the server
+ Browse and modify the archive content like a classic shell (pwd, cd, ls, rm, cat). 

The archive structure :

```bash
<numéro de la première ligne du header>:<numéro de la première ligne du body>

directory <chemin de la racine>
<nom repertoire> d<droits d`accès> <taille du repertoire>
<nom fichier> <droits d`accès> <taille du fichier> <début du fichier> <nb lignes>
@
directory <chemin du repertoire 2>
<nom du repertoire 2> d<droits d`accès> <taille du repertoire 2>
<nom fichier2> <droits d`accès> <taille du fichier2> <début du fichier2> <nb lignes>
<nom fichier3> <droits d`accès> <taille du fichier3> <début du fichier3> <nb lignes>
@
[autres directory]

<contenu de fichier1>
...
<fin du contenu de fichier1>
<contenu de fichier2>
...
<fin du contenu de fichier2>
<contenu de fichier3>
...
<fin du contenu de fichier3>
```

The vsh command works like this :
```bash
vsh <OPTION> <ADRESSE DU SERVEUR> <PORT> [NOM DE L'ARCHIVE]
```

How to start the server :
```bash
lancer_serveur_vsh.sh <PORT>
```

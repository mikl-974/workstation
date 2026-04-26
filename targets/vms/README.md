# targets/vms/

Definitions de VM portables.

## Pourquoi ce dossier existe

Une VM n'est pas un host physique.
Elle peut etre :

- deployee sur plusieurs machines
- recreee sur des hyperviseurs differents
- promue ou migree sans changer son identite logique

La ranger dans `targets/hosts/` melangeait deux niveaux :

- la definition portable de la VM
- le support physique qui l'heberge

## Regle

Une entree `targets/vms/<name>/` doit decrire :

- ce qu'est la VM
- comment elle se bootstrape
- quelles capacites elle embarque
- quelles variables elle attend

Elle ne doit pas decrire :

- le serveur physique qui l'heberge
- son placement courant
- un hostname de machine bare metal

## Etat actuel

Aucune VM portable versionnee active pour le moment.

Le dossier existe pour fixer clairement le modele avant de reintroduire des VMs.

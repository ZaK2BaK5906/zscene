# ZScene - Script de Placement de Peds Cinématiques

Script FiveM pour placer des peds cinématiques avec un système de freecam avancé.

## Caractéristiques

### Placement
- Spawn automatique 0.8m devant le joueur au sol (parfait pour MLO)
- Détection automatique du sol avec retry (GetGroundZFor_3dCoord)
- Mode placement automatique après spawn
- Freecam avec contrôles complets :
  - **ZQSD** : Déplacer la caméra
  - **Souris** : Regarder autour
  - **Espace/Ctrl** : Monter/Descendre
- Le ped suit le raycast de la caméra en temps réel
- **Touche X** : Rotation du ped (+15° par appui)
- Affichage de la rotation actuelle en temps réel
- **Clic gauche** : Valider le placement
- **Clic droit** : Annuler le placement

### Interface
- Instructions affichées en haut à droite avec DrawText natif GTA
- Affichage de la rotation actuelle du ped
- Commande `/cinelist` pour afficher la liste complète dans F8
- 38 peds cinématiques avec scenarios configurés

### Fonctionnalités
- Alpha 200 (transparent) pendant le placement
- Freeze et scenario automatiques après validation
- Print vector4 dans la console F8 après validation
- Support de 38 peds avec scenarios variés

## Commandes

- `/cinelist` : Ouvre le menu de sélection des peds
- `/cinespawn [ID]` : Spawne un ped par son ID (1-38)
- `/cineplace [ID]` : Alias de cinespawn
- `/cineclear` : Supprime tous les peds spawnés

## Installation

1. Placez le dossier dans votre répertoire `resources`
2. Ajoutez `ensure [nom_du_dossier]` dans votre `server.cfg`
3. Redémarrez votre serveur

## Dépendances

Aucune ! Le script fonctionne sans dépendance externe.

## Exemple d'utilisation

1. Tapez `/cinelist` dans F8 pour voir tous les peds disponibles
2. Utilisez `/cinespawn [ID]` pour spawner un ped (ex: `/cinespawn 1`)
3. Le ped apparaît juste devant vous (0.8m) et le mode placement s'active automatiquement
4. Déplacez la caméra avec ZQSD et regardez avec la souris
5. Le ped suit votre visée (raycast) en temps réel
6. Appuyez sur X pour faire pivoter le ped de 15° (rotation affichée à l'écran)
7. Clic gauche pour valider ou clic droit pour annuler
8. Les coordonnées vector4 s'affichent dans la console F8 après validation

## Liste des Peds

Le script inclut 38 peds configurés avec leurs scenarios :
- Gardes de sécurité
- Policiers et militaires
- Personnel médical
- Hommes/femmes d'affaires
- Ouvriers et techniciens
- Personnages civils variés
- Et bien plus...

Consultez `config.lua` pour la liste complète.

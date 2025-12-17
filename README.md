# ZScene - Script de Placement de Peds Cinématiques

Script FiveM pour placer des peds cinématiques avec un système de freecam avancé.

## Caractéristiques

### Placement
- Spawn automatique 2m devant le joueur au sol
- Détection automatique du sol avec retry (GetGroundZFor_3dCoord)
- Mode placement automatique après spawn
- Freecam avec contrôles complets :
  - **ZQSD** : Déplacer la caméra
  - **Souris** : Regarder autour
  - **Espace/Ctrl** : Monter/Descendre
- Le ped suit le raycast de la caméra en temps réel
- **Touche X** : Rotation du ped (+15° par appui)
- **Clic gauche** : Valider le placement
- **Clic droit** : Annuler le placement

### Interface
- Instructions affichées en haut à droite avec DrawText natif GTA
- Menu ox_lib avec `/cinelist` pour sélectionner les peds
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

1. Placez le dossier `zscene` dans votre répertoire `resources`
2. Assurez-vous d'avoir `ox_lib` installé et démarré
3. Ajoutez `ensure zscene` dans votre `server.cfg`
4. Redémarrez votre serveur

## Dépendances

- ox_lib

## Exemple d'utilisation

1. Tapez `/cinelist` pour ouvrir le menu
2. Sélectionnez un ped dans la liste
3. Le ped apparaît devant vous et le mode placement s'active automatiquement
4. Déplacez la caméra avec ZQSD et regardez avec la souris
5. Le ped suit votre visée (raycast)
6. Appuyez sur X pour faire pivoter le ped
7. Clic gauche pour valider ou clic droit pour annuler
8. Les coordonnées vector4 s'affichent dans la console F8

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

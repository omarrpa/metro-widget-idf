---
tags: [projet, flutter, idfm, todo]
created: 2026-11-09 08:10
auteur: Omar Pérez
---

# Metro Widget IDF - TODO

## À vérifier au premier lancement
- [ ] `flutter analyze` sans erreur (code non compilé dans l'environnement de génération)
- [ ] Premier run GitHub Actions vert + APK installé sur le téléphone
- [ ] Vérifier les noms techniques des champs ODS (`zdaxepsg2154`, `colourweb_hexa`). Si la requête avec `select` échoue, le code télécharge le CSV complet.
- [ ] Vérifier que `data.iledefrance-mobilites.fr` sert toujours les exports. Sinon, modifier `AppConfig.odsBase` (miroir : data.iledefrance.fr).
- [ ] Vérifier les constantes de l'API workmanager 0.10 (`NetworkType.connected`)

## Améliorations
- [ ] Filtre de modes (masquer les bus) et lignes favorites épinglées
- [ ] Choix manuel de la station (liste des zones proches)
- [ ] iOS : bouton d'actualisation interactif (AppIntent, iOS 17)
- [ ] Afficher les messages de perturbation (API « Messages affichés sur les écrans »)
- [ ] Pastilles arrondies sur Android 12+ (`setColorStateList` backgroundTint)
- [ ] Remplacer le CSV des zones par un fichier Parquet/SQLite embarqué pour un démarrage hors ligne

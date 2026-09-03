# 🏰 Godot Dungeon

Un petit jeu de **donjon 2D** natif **Android**, écrit en **GDScript** avec le
moteur **Godot 4**. Tu incarnes un héros qui explore un donjon généré
aléatoirement, ramasse toutes les pièces d'un niveau pour passer au suivant,
tout en évitant des ennemis qui te poursuivent.

> 100 % code, **aucun asset binaire** : tous les graphismes sont dessinés par
> programme (`_draw`). Le projet est donc léger et parfait pour git.

---

## 🎮 Le jeu

- Déplace le héros et **ramasse toutes les pièces** du niveau.
- Chaque niveau franchi ajoute des ennemis plus rapides et plus de murs.
- Toucher un ennemi retire **1 point de vie** (bref temps d'invincibilité).
- À 0 point de vie → **Game Over**, puis bouton **Rejouer**.

### Contrôles
- **Android / tactile** : joystick flottant — pose ton doigt n'importe où et
  glisse pour te diriger.
- **PC (test dans l'éditeur)** : **ZQSD / WASD** ou les **flèches**.

---

## 🚀 Ouvrir le projet

1. Installe **Godot 4.3+** (version standard, pas la version .NET) :
   https://godotengine.org/download
2. Lance Godot → **Import** → sélectionne le fichier `project.godot` de ce
   dossier → **Open**.
3. Appuie sur **F5** (ou le bouton ▶ en haut à droite) pour jouer sur PC.

---

## 📱 Lancer / exporter sur Android

### A. Tester rapidement sur un téléphone branché en USB
1. Sur le téléphone : active les **Options développeur** puis le **Débogage USB**.
2. Branche le téléphone en USB, autorise la connexion.
3. Dans Godot, un **petit icône Android** apparaît en haut à droite : clique
   dessus pour installer et lancer le jeu directement (« One-click deploy »).

### B. Générer un APK
1. Installe le **JDK 17** et le **SDK Android** (le plus simple : installer
   **Android Studio** une fois, il fournit le SDK).
2. Dans Godot : **Editor → Editor Settings → Export → Android** et renseigne les
   chemins du SDK et de l'`adb`.
3. **Project → Install Android Build Template…** (nécessaire pour un build
   complet).
4. **Project → Export…** : le préréglage **Android** est déjà présent
   (`export_presets.cfg`). Clique **Export Project** pour produire un `.apk`
   dans `build/`.
5. Pour un APK **signé en release**, crée un keystore et renseigne-le dans le
   préréglage (voir la doc Godot ci-dessous). Le keystore ne doit **jamais**
   être commité (déjà exclu dans `.gitignore`).

📖 Doc officielle : https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html

---

## 🗂️ Structure du projet

```
godot-dungeon/
├── project.godot            # Configuration (résolution portrait, rendu mobile…)
├── icon.svg                 # Icône du projet
├── export_presets.cfg       # Préréglage d'export Android
├── scenes/
│   └── Main.tscn            # Scène principale (un seul nœud → Game.gd)
└── scripts/
    ├── Game.gd             # Boucle de jeu : donjon, niveaux, HUD, game over
    ├── Player.gd           # Le héros (déplacement clavier + joystick)
    ├── Enemy.gd            # Ennemi qui poursuit le joueur
    ├── Coin.gd             # Pièce à ramasser
    └── VirtualJoystick.gd  # Joystick tactile flottant
```

L'ensemble du monde (murs, héros, ennemis, pièces, caméra, interface) est
construit **par code** au lancement, à partir de la scène minimale `Main.tscn`.

---

## 🔧 Idées d'évolution

- Sortie / porte au lieu de « ramasser toutes les pièces » pour finir un niveau.
- Attaque du héros (bouton tactile) et points de vie sur les ennemis.
- Bonus (soin, vitesse), pièges, coffres.
- Sons et musique (Godot gère l'audio nativement).
- Sprites dessinés à la place des formes géométriques.
- Sauvegarde du meilleur score.

---

## 📦 Moteur

- **Godot 4.3+** — GDScript — rendu **Mobile**, orientation **portrait**.

# 🌑 Gloomrunner

Un jeu de **donjon d'esquive** natif **Android**, écrit en **GDScript** avec le
moteur **Godot 4**. Tu incarnes une lueur qui explore un donjon généré
aléatoirement, ramasse tout l'or d'un niveau pour ouvrir la sortie, tout en
esquivant des monstres qui te traquent — sans jamais attaquer.

> 100 % code, **aucun asset binaire** : tous les graphismes sont dessinés par
> programme (`_draw`). Le projet est donc léger et parfait pour git.

---

## 🎮 Le jeu

- **Écran-titre** animé (braises flottantes, musique d'ambiance).
- Donjon **plongé dans le noir** avec **éclairage dynamique** : halo autour du
  héros, **torches vacillantes** et braises, vignettage cinématographique.
- **Jeu d'esquive** : pas d'attaque directe — **déplace-toi, esquive les
  ennemis, ramasse tout l'or**, puis rejoins le **portail de sortie** qui
  s'ouvre pour passer au niveau suivant.
- **Ennemis variés** (poursuiveur, rapide, costaud, **fantôme** qui traverse
  les murs, **zigzag** imprévisible, **slime** qui se divise) qui te traquent en
  **contournant les murs** (navigation A\*). Aucun n'est plus rapide que toi :
  tu peux toujours les semer.
- **Boutique** : l'or gagné est mis en banque en fin de partie et se dépense en
  **améliorations permanentes** (cœur max, bouclier de départ, plus de coffres).
- **Pièges à pics** télégraphiés : évite-les… ou **attire les ennemis dedans**
  pour les éliminer (seul moyen offensif, + bonus de score).
- **Bonus** à ramasser : ❤️ cœur (soin) et ⚡ éclair (vitesse temporaire).
- **Grande arène** avec caméra qui suit le héros et **mini-carte** en coin
  d'écran.
- **Boss** tous les 5 niveaux : gros, coriace, charge périodiquement, barre de
  vie (élimine-le via les pièges pour un gros bonus).
- **Coffres** à ouvrir : récompense aléatoire parmi or, soin, vitesse,
  **aimant à pièces**, **gel des ennemis** ou **bouclier**.
- **Objets à usage unique** ramassés au sol, déclenchés par un bouton :
  💣 bombe (élimine les ennemis proches), ❄️ gel, 🧪 potion (soin complet),
  ⚡ saut (téléportation courte).
- **8 biomes / thèmes** : Néon, Lave, Glacier, Forêt, Rétro, Désert, Améthyste,
  Abysse — ou mode Auto.
- **Bouton pause** (menu Reprendre / Recommencer / Quitter).
- **Succès** à débloquer (panneau sur l'écran-titre) avec progression et
  notifications.
- **Défi du jour** : un objectif quotidien (même pour tous) qui rapporte de l'or.
- **8 thèmes / biomes** au choix sur l'écran-titre — ou mode **Auto (biomes)**
  qui fait évoluer l'ambiance au fil des niveaux. Choix sauvegardé.
- **Vibrations** (mobile) activables/désactivables depuis l'écran-titre.
- **Vie en cœurs**, invincibilité brève après un coup reçu.
- **Meilleur score sauvegardé** entre les parties.
- **Sons + musique** générés par synthèse (aucun fichier audio).
- À 0 point de vie → **Game Over**, puis bouton **Rejouer**.

### Contrôles
- **Android / tactile** : joystick flottant — pose le doigt **n'importe où** et
  glisse pour te diriger (jeu à un pouce).
- **PC (test dans l'éditeur)** : **ZQSD / WASD** ou **flèches**.

---

## ⬇️ Récupérer l'APK sans PC (depuis mobile)

Un **workflow GitHub Actions** (`.github/workflows/android.yml`) compile l'APK
automatiquement à chaque push sur `main`. Pour l'installer sur ton téléphone :

1. Ouvre l'onglet **Releases** du dépôt → release **« latest »**.
2. Télécharge `gloomrunner.apk`.
3. Autorise l'installation depuis cette source, puis ouvre le fichier.

> Tu peux aussi lancer le build à la main : onglet **Actions** →
> *Build Android APK* → **Run workflow**. L'APK est aussi disponible en
> **artefact** du run.
>
> ⚠️ C'est un APK **de debug** (non signé pour le Play Store) : parfait pour
> jouer et tester, pas pour une publication officielle.

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

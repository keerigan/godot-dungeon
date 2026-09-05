extends Node

## Wrapper TOLÉRANT pour les succès Google Play (Play Games Services).
##
## Tant que le plugin Android natif n'est PAS installé (sur PC, dans l'APK de
## debug, ou si le joueur n'est pas connecté), tout est un no-op silencieux :
## le jeu fonctionne exactement comme avant. Les succès « en jeu » (hors-ligne)
## restent la source de vérité ; Play Games ne fait que les refléter dans le
## compte Google du joueur.
##
## ─────────────────────────────────────────────────────────────────────────
## POUR ACTIVER LES SUCCÈS PLAY (quand le compte Play Console sera prêt) :
##
## 1. Créer l'app + activer « Play Games Services » sur la Google Play Console,
##    obtenir l'App ID numérique et créer un OAuth client (avec le SHA-1 de la
##    clé de release).
## 2. Déclarer chaque succès dans la Console -> récupérer son identifiant
##    (de la forme « CgkI... ») et le reporter dans ACHIEVEMENT_IDS ci-dessous.
## 3. Ajouter un plugin Android Godot de Play Games Services (.aar + .gdap) dans
##    android/plugins/, et l'activer dans le préréglage d'export Android. Le
##    build Gradle (déjà configuré pour l'AAB release) est requis.
## 4. Ajuster si besoin le nom du singleton et des méthodes/signaux ci-dessous
##    selon le plugin retenu (ils varient d'un plugin à l'autre) — tout est
##    encapsulé ici, rien d'autre à toucher dans le jeu.
## ─────────────────────────────────────────────────────────────────────────

# Correspondance : id du succès en jeu -> id du succès Play Games.
# Laisser vide ("") tant que ce n'est pas déclaré dans la Console : les succès
# sans id sont simplement ignorés côté Play (mais restent gagnés en jeu).
const ACHIEVEMENT_IDS := {
	"kill1": "",
	"kill50": "",
	"coins500": "",
	"lvl5": "",
	"lvl10": "",
	"boss1": "",
	"chest10": "",
	"nodmg": "",
}

# Noms de singleton possibles selon le plugin (on prend le premier trouvé).
const SINGLETON_NAMES := [
	"GodotPlayGameServices", "PlayGamesServices", "GodotGooglePlayGameServices",
]

var _client: Object = null
var _available := false
var signed_in := false


func _ready() -> void:
	for n in SINGLETON_NAMES:
		if Engine.has_singleton(n):
			_client = Engine.get_singleton(n)
			_available = true
			break
	if _available:
		_connect_signals()
		sign_in()


## Le plugin natif est-il présent ? (faux sur PC / APK sans plugin)
func is_available() -> bool:
	return _available


func sign_in() -> void:
	if not _available:
		return
	_call_any(["signIn", "sign_in", "authenticate"])


## Débloque un succès Play à partir de l'id du succès en jeu.
func unlock(game_id: String) -> void:
	if not _available or not signed_in:
		return
	var pid: String = ACHIEVEMENT_IDS.get(game_id, "")
	if pid == "":
		return
	_call_any(["unlockAchievement", "unlock_achievement", "unlock"], [pid])


## Ouvre l'overlay natif des succès Google Play.
func show_achievements() -> void:
	if not _available or not signed_in:
		return
	_call_any(["showAchievements", "show_achievements"])


func _connect_signals() -> void:
	for sig in ["sign_in_success", "signInSuccess", "userAuthenticated", "authenticated"]:
		if _client.has_signal(sig):
			_client.connect(sig, _on_signed_in)
	for sig in ["sign_in_failed", "signInFailed", "authenticationFailed"]:
		if _client.has_signal(sig):
			_client.connect(sig, _on_sign_in_failed)


func _on_signed_in(_a = null) -> void:
	signed_in = true


func _on_sign_in_failed(_a = null) -> void:
	signed_in = false


## Appelle la première méthode existante parmi `names`, avec `args`.
func _call_any(names: Array, args: Array = []) -> void:
	if _client == null:
		return
	for m in names:
		if _client.has_method(m):
			_client.callv(m, args)
			return

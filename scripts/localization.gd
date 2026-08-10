extends Node
## Localization autoload — the single source of truth for every user-facing
## term in the game. Each language table is complete (no partial keys), so the
## EN game shows English everywhere and the SL game shows Slovenian everywhere.
##
## Usage:  L.t("key")  returns the current language's string for `key`.
##         L.set_language("en" | "sl")  switches the whole game's language.
##         L.get_lang()  current language ("en" | "sl").
##
## This is the seam the game's localisation runs through. Any literal that the
## player can read must come from here (or from `main.gd`'s narrator dictionary
## built on the same keys), never hard-coded in a scene.

signal language_changed

const DEFAULT_LANG := "en"

var _lang: String = DEFAULT_LANG

# English — the language the game is developed in. Every key present.
const EN := {
	# --- Section headers ---
	"section_immanence": "— IMMANENCE —",
	"section_story": "— STORY —",
	"section_absolute": "— ABSOLUTE —",
	"section_powers": "— POWERS —",
	"section_mithjos": "— MITHJOS (Z·J·E·N) —",
	"section_genome": "— GENOME (the plane's code) —",
	"section_world": "— WORLD —",

	# --- Buttons / static UI ---
	"back_to_soul": "‹ back to your soul",
	"drawn": "drawn",
	"polar_white": "WHITE / CREATION",
	"polar_black": "BLACK / DESTRUCTION",

	# --- Abilities (the phenotype) ---
	"STR": "strength",
	"STA": "stamina",
	"INT": "intelligence",
	"WIS": "wisdom",
	"CHA": "charisma",
	"DEX": "dexterity",
	"LUK": "luck",

	# --- Powers (the Box) ---
	"pow_fizicna": "physical",
	"pow_psiholoska": "psychological",
	"pow_custvena": "emotional",
	"pow_duhovna": "spiritual",
	"pow_dusevna": "soul",
	"pow_inteligenca": "intelligence",
	"pow_gibljivost": "mobility",
	"pow_stamina": "stamina",

	# --- Pools ---
	"pool_capacity": "capacity",
	"pool_reflex": "reflex",
	"pool_aura": "aura",

	# --- World rows ---
	"world_dust": "⚙ dust",
	"world_balance": "⚖ balance",
	"world_vault": "◉ vault",

	# --- Mithjos ---
	"mith_Z": "consciousness",
	"mith_J": "ego-relation",
	"mith_E": "ethical process",
	"mith_N": "paradox / No",

	# --- Skulls / mods / story ---
	"skulls": "SKULLS",
	"skulls_lower": "skulls",
	"mods": "mods",
	"story_empty": "(no story yet — the soul is new)",
	"upgrade_points": "UPGRADE POINTS",

	# --- Balance descriptor ---
	"balance_neutral": "neutral",
	"balance_white": "white-leaning",
	"balance_black": "black-leaning",

	# --- Main menu ---
	"menu_title": "SOUL  EVOLUTION",
	"menu_sub": "matter vs antimatter",
	"menu_play": "PLAY",
	"menu_settings": "SETTINGS",
	"menu_quit": "QUIT",
	"menu_choose_polarity": "CHOOSE YOUR POLARITY",
	"menu_choose_sub": "white = matter (electron) | black = antimatter (positron)",
	"menu_white": "WHITE — Matter / Electron",
	"menu_black": "BLACK — Antimatter / Positron",
	"menu_back": "Back",
	"menu_paused": "PAUSED",
	"menu_resume": "RESUME",
	"menu_return": "RETURN TO MAIN MENU",
	"menu_army": "Army size per side: %d",
	"menu_how_to": "how to play",
	"menu_gallery": "GALLERY",
	"gallery_title": "ASSET GALLERY",
	"gallery_empty": "no generated assets found in res://assets/",

	# --- HUD ---
	"hud_soul_white": "SOUL: WHITE — CREATION / LIGHT",
	"hud_soul_black": "SOUL: BLACK — DESTRUCTION / VOID",
	"hud_controls_white": "WASD: Move   |   SPACE: Light Beam   |   TAB: Genome",
	"hud_controls_black": "WASD: Move   |   SPACE: Force Field   |   TAB: Genome",
	"hud_dust": "⚙ dust",

	# --- Narrator (Time's voice) ---
	"narr_first_encounter": "matter meets antimatter. the first encounter.",
	"narr_first_blast": "a crude blast — but it's a start. everything here is still black and white.",
	"narr_incarnate": "incarnation complete. new body, same existential dread.",
	"narr_died": "you died. the universe didn't notice. moving on.",
	"narr_annihilation": "matter and antimatter meet. the world gains color.",
	"narr_box_opens": "the box opens. color enters the world.",
	"narr_council": "the weight of the lost locks the plane. the last of each side must meet.",
	"narr_rebirth": "the plane breathes again. color returns, amplified.",
	"narr_no_coin": "no coin. the machine wants a treasure first.",
	"narr_machine_empty": "the machine is empty.",
	"narr_light_void": "light enters the void. the first narrative begins.",
	"narr_void_child": "the void accepts its child. everything begins from nothing.",
	"narr_hourglass_poured": "you pour %d sand. Time reads your echo=%.2f and gives %d color back.",
	"narr_hourglass_empty": "the hourglass is empty. there is nothing to give.",

	# --- Grand Council ---
	"council_title": "THE GRAND COUNCIL",
	"council_sub": "movement has stopped. the last of each side must choose.",
	"council_domination": "DOMINATION",
	"council_split": "SPLIT",

	# --- Oracle of the Many Windows ---
	"oracle_title": "ORACLE OF THE MANY WINDOWS",
	"oracle_status": "Tier %d · consulted %d · dust spent %d",
	"oracle_consult": "CONSULT  (⚙ %d dust)",
	"oracle_upgrade": "UPGRADE SIGHT  (⚙ %d dust)",
	"oracle_maxed": "SIGHT IS MAXED",
	"oracle_reading": "the oracle reads:  %s  %s  ·  register %s",
	"oracle_no_dust": "no dust. the oracle wants sand.",
	"oracle_upgraded": "the oracle's sight deepens.",
}

# Slovenian — the full translation of the same key set.
const SL := {
	"section_immanence": "— IMENENČNO —",
	"section_story": "— ZGODBA —",
	"section_absolute": "— ABSOLUTNO —",
	"section_powers": "— MOČI —",
	"section_mithjos": "— MITHJOS (Z·J·E·N) —",
	"section_genome": "— GENOM (koda ravnine) —",
	"section_world": "— SVET —",

	"back_to_soul": "‹ nazaj k tvoji duši",
	"drawn": "potegnjeno",
	"polar_white": "BELO / USTVARJANJE",
	"polar_black": "ČRNO / UNIČENJE",

	"STR": "moč",
	"STA": "vzdržljivost",
	"INT": "inteligenca",
	"WIS": "modrost",
	"CHA": "karizma",
	"DEX": "spretnost",
	"LUK": "sreča",

	"pow_fizicna": "telesna",
	"pow_psiholoska": "psihološka",
	"pow_custvena": "čustvena",
	"pow_duhovna": "duhovna",
	"pow_dusevna": "duševna",
	"pow_inteligenca": "inteligenca",
	"pow_gibljivost": "gibljivost",
	"pow_stamina": "vzdržljivost",

	"pool_capacity": "zaloga",
	"pool_reflex": "refleks",
	"pool_aura": "avra",

	"world_dust": "⚙ prah",
	"world_balance": "⚖ ravnovesje",
	"world_vault": "◉ arhiv",

	"mith_Z": "zavest",
	"mith_J": "ego-relacija",
	"mith_E": "etični proces",
	"mith_N": "paradoks / Ne",

	"skulls": "LOBANJE",
	"skulls_lower": "lobanje",
	"mods": "spremembe",
	"story_empty": "(ni zgodbe še — duša je nova)",
	"upgrade_points": "TOČKE NADGRADNJE",

	"balance_neutral": "nevtralno",
	"balance_white": "nagiba k belem",
	"balance_black": "nagiba k črnemu",

	# --- Main menu ---
	"menu_title": "EVOLUCIJA  DUŠE",
	"menu_sub": "snov proti antisnovi",
	"menu_play": "IGRAJ",
	"menu_settings": "NASTAVITVE",
	"menu_quit": "KONEC",
	"menu_choose_polarity": "IZBERI POLARNOST",
	"menu_choose_sub": "bela = snov (elektron) | črna = antisnov (pozitron)",
	"menu_white": "BELA — Snov / Elektron",
	"menu_black": "ČRNA — Antisnov / Pozitron",
	"menu_back": "Nazaj",
	"menu_paused": "PREKINJENO",
	"menu_resume": "NADALJUJ",
	"menu_return": "NAZAJ V GLAVNI MENI",
	"menu_army": "Velikost vojske na stran: %d",
	"menu_how_to": "kako igrati",
	"menu_gallery": "GALERIJA",
	"gallery_title": "GALERIJA SREDSTEV",
	"gallery_empty": "v res://assets/ ni najdenih ustvarjenih sredstev",

	# --- HUD ---
	"hud_soul_white": "DUŠA: BELA — USTVARJANJE / SVETLOBA",
	"hud_soul_black": "DUŠA: ČRNA — UNIČENJE / PRAZNINA",
	"hud_controls_white": "WASD: Premik   |   SPACE: Svetlobni žarek   |   TAB: Genom",
	"hud_controls_black": "WASD: Premik   |   SPACE: Silno polje   |   TAB: Genom",
	"hud_dust": "⚙ prah",

	# --- Narrator (Časov glas) ---
	"narr_first_encounter": "snov sreča antisnov. prvo srečanje.",
	"narr_first_blast": "surov izbruh — a to je začetek. vse tukaj je še črno-belo.",
	"narr_incarnate": "inkarnacija končana. novo telo, isti eksistencialni strah.",
	"narr_died": "umrl si. vesolje ni opazilo. gremo naprej.",
	"narr_annihilation": "snov in antisnov se srečata. svet dobi barvo.",
	"narr_box_opens": "škatla se odpre. barva vstopi v svet.",
	"narr_council": "teža izgubljenih zaklene ravnino. zadnja strani se morata srečati.",
	"narr_rebirth": "ravnina spet zadiha. barva se vrne, okrepljena.",
	"narr_no_coin": "ni kovanca. stroj najprej hoče zaklad.",
	"narr_machine_empty": "stroj je prazen.",
	"narr_light_void": "svetloba vstopi v praznino. prva pripoved se začne.",
	"narr_void_child": "praznina sprejme svojega otroka. vse se začne iz nič.",
	"narr_hourglass_poured": "izliješ %d peska. Čas prebere tvoj odmev=%.2f in vrne %d barve.",
	"narr_hourglass_empty": "peščena ura je prazna. ni česa dati.",

	# --- Grand Council (Veliki svet) ---
	"council_title": "VELIKI SVET",
	"council_sub": "gibanje se je ustavilo. zadnji strani se morata odločiti.",
	"council_domination": "PREVLADA",
	"council_split": "RAZDELITEV",

	# --- Oracle (Prerok) ---
	"oracle_title": "PREROK MNOGIH OKEN",
	"oracle_status": "Stopnja %d · posvetovanj %d · porabljen prah %d",
	"oracle_consult": "POSVET  (⚙ %d prahu)",
	"oracle_upgrade": "POGLOBI VID  (⚙ %d prahu)",
	"oracle_maxed": "VID JE MAKSIMALEN",
	"oracle_reading": "prerok bere:  %s  %s  ·  register %s",
	"oracle_no_dust": "ni prahu. prerok hoče pesek.",
	"oracle_upgraded": "prerokov vid se poglobi.",
}


func _ready() -> void:
	# Read the persisted language if present, else default to English.
	var file := FileAccess.open("user://lang.txt", FileAccess.READ)
	if file:
		var saved := file.get_line().strip_edges()
		file.close()
		if saved == "en" or saved == "sl":
			_lang = saved


func set_language(lang: String) -> void:
	if lang != "en" and lang != "sl":
		return
	if lang == _lang:
		return
	_lang = lang
	var file := FileAccess.open("user://lang.txt", FileAccess.WRITE)
	if file:
		file.store_line(lang)
		file.close()
	language_changed.emit()


func get_lang() -> String:
	return _lang


## The core lookup. Falls back to the key itself if it's missing from the
## current table (so a missing translation never blanks the UI — it shows the
## key, which is a loud signal to finish the table).
func t(key: String) -> String:
	var table := SL if _lang == "sl" else EN
	if table.has(key):
		return table[key]
	return key
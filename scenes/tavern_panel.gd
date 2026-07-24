extends Control

@export var generators: Array[Generator] = []
@export var stat_upgrades: Array[StatUpgrade] = []

@onready var _coin_label: Label = $CoinLabel
@onready var _gen_list: VBoxContainer = $ShopContainer/GeneratorList
@onready var _stat_list: VBoxContainer = $ShopContainer/UpgradeList
@onready var _serve_button: Button = $ServeButton

# Since coin is earned per second but _process runs per frame, the fraction carries for a while until a whole int can be passed
var _coin_accum := 0.0

var _gen_rows: Array = []
var _stat_rows: Array = []

func _ready() -> void:
	# Make new copies of generators so the base .tres files are never dirtied
	for i in generators.size():
		generators[i] = generators[i].duplicate()
	for i in stat_upgrades.size():
		stat_upgrades[i] = stat_upgrades[i].duplicate()
	_build_gen_rows()
	_build_stat_rows()
	GameState.coin_changed.connect(_on_coin_changed)
	GameState.stat_changed.connect(_on_stat_changed)
	_serve_button.pressed.connect(_on_serve_pressed)
	_on_coin_changed(GameState.coin)
	
func _process(delta: float) -> void:
	if generators.is_empty():
		return
	var total := 0.0
	for g in generators:
		total += g.income_per_sec() * delta
	_coin_accum += total
	var whole := int(_coin_accum)
	if whole > 0:
		_coin_accum -= whole
		GameState.add_coin(whole)
		
# Generators
func _build_gen_rows() -> void:
	for g in generators:
		var row := HBoxContainer.new()
		var info := Label.new()
		info.custom_minimum_size = Vector2(760, 0)
		info.add_theme_font_size_override("font_size", 20)
		var buy := Button.new()
		buy.pressed.connect(_on_buy_pressed.bind(g))
		row.add_child(info)
		row.add_child(buy)
		_gen_list.add_child(row)
		_gen_rows.append({ "gen": g, "info": info, "buy": buy })
	_refresh_gen_rows()

func _on_buy_pressed(g: Generator) -> void:
	if GameState.spend_coin(g.buy_cost()):
		g.owned += 1
		_refresh_gen_rows()
		
func _on_upgrade_pressed(g: Generator) -> void:
	if GameState.spend_coin(g.upgrade_cost()):
		g.level =+ 1
		_refresh_gen_rows()
		
func _refresh_gen_rows() -> void:
	for r in _gen_rows:
		var g: Generator = r["gen"]
		r["info"].text = "%s - Owned %d - %.1f Coin/sec\n%s" % [
			g.name, g.owned, g.income_per_sec(), g.flavor]
		r["buy"].text = "Buy (%d)" % g.buy_cost()
		r["buy"].disabled = GameState.coin < g.buy_cost()
		
# Stat upgrades
func _build_stat_rows() -> void:
	for u in stat_upgrades:
		var row := HBoxContainer.new()
		var info := Label.new()
		info.custom_minimum_size = Vector2(320, 0)
		info.add_theme_font_size_override("font_size", 20)
		var buy := Button.new()
		buy.pressed.connect(_on_stat_buy_pressed.bind(u))
		row.add_child(info)
		row.add_child(buy)
		_stat_list.add_child(row)
		_stat_rows.append({ "upg": u, "info": info, "buy": buy })
	_refresh_stat_rows()
	
func _on_stat_buy_pressed(u: StatUpgrade) -> void:
	if GameState.spend_coin(u.cost()):
		GameState.bump_stat(u.stat, u.amount)
		u.bought += 1
		_refresh_stat_rows()
		
func _refresh_stat_rows() -> void:
	for r in _stat_rows:
		var u: StatUpgrade = r["upg"]
		r["info"].text = "%s  (Now %d)" % [u.stat.capitalize(), int(GameState.stats[u.stat])]
		r["buy"].text = "+%d  (%d)" % [u.amount, u.cost()]
		r["buy"].disabled = GameState.coin < u.cost()
		
# Shared
		
func _on_coin_changed(new_coin: int) -> void:
	_coin_label.text = "Coin: %d" % new_coin
	for r in _gen_rows:
		var g: Generator = r["gen"]
		r["buy"].disabled = new_coin < g.buy_cost()
		
func _on_stat_changed(_stat, _value) -> void:
	_refresh_stat_rows()
		
func _on_serve_pressed() -> void:
	GameState.add_coin(1)

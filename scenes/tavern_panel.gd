extends Control

@export var generators: Array[Generator] = []

@onready var _coin_label: Label = $CoinLabel
@onready var _list: VBoxContainer = $GeneratorList
@onready var _serve_button: Button = $ServeButton

# Since coin is earned per second but _process runs per frame, the fraction carries for a while until a whole int can be passed
var _coin_accum := 0.0

var _rows: Array = []

func _ready() -> void:
	# Make new copies of generators so the base .tres files are never dirtied
	for i in generators.size():
		generators[i] = generators[i].duplicate()
	_build_rows()
	GameState.coin_changed.connect(_on_coin_changed)
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
		
func _build_rows() -> void:
	for g in generators:
		var row := HBoxContainer.new()
		var info := Label.new()
		info.custom_minimum_size = Vector2(760, 0)
		info.add_theme_font_size_override("font_size", 20)
		var buy := Button.new()
		buy.pressed.connect(_on_buy_pressed.bind(g))
		row.add_child(info)
		row.add_child(buy)
		_list.add_child(row)
		_rows.append({ "gen": g, "info": info, "buy": buy })
	_refresh_rows()

func _on_buy_pressed(g: Generator) -> void:
	if GameState.spend_coin(g.buy_cost()):
		g.owned += 1
		_refresh_rows()
		
func _on_serve_pressed() -> void:
	GameState.add_coin(1)

func _refresh_rows() -> void:
	for r in _rows:
		var g: Generator = r["gen"]
		r["info"].text = "%s - owned %d - %.1f coin/s\n%s" % [
			g.name, g.owned, g.income_per_sec(), g.flavor]
		r["buy"].text = "Buy (%d)" % g.buy_cost()
		r["buy"].disabled = GameState.coin < g.buy_cost()
		
func _on_coin_changed(new_coin: int) -> void:
	_coin_label.text = "Coin: %d" % new_coin
	for r in _rows:
		var g: Generator = r["gen"]
		r["buy"].disabled = new_coin < g.buy_cost()

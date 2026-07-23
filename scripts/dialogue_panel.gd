## DialoguePanel - Phase 2 dialogue shell and manager
## A tiny state machine that plays one hardcoded section: shows Ryat's blocks
## one at a time, reveals the tiered options on the last block, and each option
## just called GameState.add_time(). Actual stat checks, odds, and a .tres-based
## DialogueSection arrive in Phase 3. This file's shape will match that one's
extends Control

signal section_started
signal section_finished

# The various states
enum { IDLE, SHOWING_BLOCKS, AWAITING_CHOICE, SHOWING_RESULT }

@onready var _ryat_text: Label = $VBox/RyatText
@onready var _responses: VBoxContainer = $VBox/ResponseVBox
@onready var _continue: Button = $VBox/Continue

# Hardcoded Phase 2 section (Will become a full DialogueSection.tres in Phase 3)
# Responses are authored in the order of easiest at the top, hardest at the
# bottom. For now, they all succeed always. time_reward values are based on the
# outlines in BALANCE.md
#var _section := {
	#"ryat_blocks": [
		#"Good evening. It has taken me a great deal of time to reach you, my friend.",
		#"You may not think you know me, but everyone does. You will come to understand that soon.",
		#"For now, I would like a drink. It has been... some time, since I have indulged in a drink."
	#],
	#"responses": [
		#{ "text": "\"First one's on the house. Always is.\"",
		#"time_reward": 15.0,
		#"result": "The individual cracks a gentle smile. \"A generous gesture. A delay of the inevitable will be accepted today.\"" },
		#{ "text": "\"If you'd like a drink, I can give you one. But I have stories to offer too, stranger.\"",
		#"time_reward": 60.0,
		#"result": "\"... Maybe a story would be enjoyable. Go ahead.\"" },
		#{ "text": "\"You look like you haven't sat down in years, friend. Stay a while, rest yourself.\"",
		#"time_reward": 150.0,
		#"result": "The individual goes quiet for a moment. \"... It has been a long time. Longer than you would believe.\"" }
	#]
#}

var _state := IDLE
var _section: DialogueSection
var _block_i := 0

var _result_blocks: Array[String] = []
var _result_i := 0

func _ready() -> void:
	_continue.pressed.connect(on_advance)
	_reset_ui()
	
func start_section(section: DialogueSection) -> void:
	_section = section
	_block_i = 0
	_clear_responses()
	section_started.emit()
	_show_current_block()
	
func _show_current_block() -> void:
	var blocks := _section.ryat_blocks
	_ryat_text.text = blocks[_block_i]
	if _block_i == blocks.size() -1:
		_reveal_responses()
		_continue.hide()
		_state = AWAITING_CHOICE
	else:
		_hide_responses()
		_continue.text = "Continue >"
		_continue.show()
		_state = SHOWING_BLOCKS
		
func on_advance() -> void:
	match _state:
		SHOWING_BLOCKS:
			_block_i += 1
			_show_current_block()
		SHOWING_RESULT:
			_finish_section()

func _reveal_responses() -> void:
	_clear_responses()
	for res in _section.responses:
		var b := Button.new()
		b.text = _response_label(res)
		b.pressed.connect(_on_response_chosen.bind(res))
		_responses.add_child(b)
	_responses.show()
	
func _response_label(res: DialogueResponse) -> String:
	if res.stat == "":
		return "%s    (Safe | +%ds)" % [res.text, int(res.time_reward)]
	var pct := int(round(success_chance(res) * 100.0))
	return "%s    (%d%% | +%ds)" % [res.text, pct, int(res.time_reward)]
	
func _on_response_chosen(res: DialogueResponse) -> void:
	if _state != AWAITING_CHOICE:
		return
	_hide_responses()
	var success := _roll_check(res)
	if success:
		GameState.add_time(res.time_reward)
		if res.regret_delta != 0.0:
			GameState.bump_stat("regret", res.regret_delta)
	_ryat_text.text = res.success_blocks if success else res.fail_blocks
	_result_i = 0
	_state = SHOWING_RESULT
	_show_result_block()
	
func _show_result_block() -> void:
	if _result_blocks.is_empty():
		_finish_section()
		return
	_ryat_text.text = _result_blocks[_result_i]
	_continue.text = ">" if _result_i < _result_blocks.size() - 1 else "Finish"
	_continue.show()
	
# Math for ability checks
func _roll_check(res: DialogueResponse) -> float:
	if res.stat == "":
		return true
	var roll := randi_range(1, 20) + int(GameState.stats[res.stat])
	return roll >= res.difficulty
	
# For properly writing the UI percentage - clamp(0.05, 0.95) so it never reads a fake 0/100
func success_chance(res: DialogueResponse) -> float:
	if res.stat == "":
		return 1.0
	var need := res.difficulty - int(GameState.stats[res.stat])
	return clamp(float(21 - need) / 20.0, 0.05, 0.95)
	
func _finish_section() -> void:
	_state = IDLE
	_reset_ui()
	section_finished.emit()
	
# UI Helpers
func _reset_ui() -> void:
	_ryat_text.text = "Ryat sits with a drink. The tavern hums, paying them no mind."
	_hide_responses()
	_continue.hide()
	
func _clear_responses() -> void:
	for c in _responses.get_children():
		c.queue_free()
		
func _hide_responses() -> void:
	_responses.hide()

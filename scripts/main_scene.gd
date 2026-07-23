## Main scene controller (Phase 1)
## Hears GameState.game_over, computes the regret bucket, and swaps in the
## ending screen. Also hosts debug keys for triggering endings manually
extends Node2D

const EndingScreen := preload("res://scenes/ending_screen.tscn")
const REGRET_LOW_CUTOFF := 6

const VIEWPORT_W := 1920.0
const TURN_TIME := 0.4
const SECTION_CADENCE := 12.0

@onready var _world: Control = $World
@onready var _dialogue := $World/DialoguePanel
@onready var _nudge: Label = $HUD/NudgeLabel
@onready var _section_timer: Timer = $SectionTimer

var _facing := "dialogue"
var _turn_tween: Tween
var _ending_shown := false

func _ready() -> void:
	GameState.game_over.connect(_on_game_over)
	_dialogue.section_finished.connect(_on_section_finished)
	_section_timer.timeout.connect(_fire_section)
	
	$World/DialoguePanel/ToTavern.pressed.connect(face.bind("tavern"))
	$World/TavernPanel/ToDialogue.pressed.connect(face.bind("dialogue"))
	
	_nudge.hide()
	face("dialogue", true)
	print("Main scene and script have loaded")
	_section_timer.start(1.0)
	
func face(side: String, instant := false) -> void:
	_facing = side
	var target_x := 0.0 if side == "dialogue" else -VIEWPORT_W
	if _turn_tween and _turn_tween.is_running():
		_turn_tween.kill()
	if instant:
		_world.position.x = target_x
	else:
		_turn_tween = create_tween()
		_turn_tween.tween_property(_world, "position:x", target_x, TURN_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if side == "dialogue":
		_nudge.hide()
		
func _fire_section() -> void:
	_dialogue.start_section()
	if _facing != "dialogue":
		_nudge.show()
	
func _on_section_finished() -> void:
	_section_timer.start(SECTION_CADENCE)
	
func _on_game_over(reason: String) -> void:
	if _ending_shown:
		return
	_ending_shown = true
	var bucket := "low" if GameState.stats["regret"] <= REGRET_LOW_CUTOFF else "high"
	var ending := EndingScreen.instantiate()
	add_child(ending)
	ending.play(reason, bucket)
	
#	Debug Helpers (only runs in editor)
#	Q : Face Ryat 			E : Face the tavern
#	T : bank +5:00			(Spam past the win_threshold -> Reprieve)
#	K : drain the clock		(Force a timeout -> Last call)
#	1 : regret to LOW		(Sets regret to 5, earns you peace)
#	2 : regret to HIGH		(Sets regret to 20, die without peace)
func _unhandled_input(event: InputEvent) -> void:
	if not OS.has_feature("editor"):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q: face("dialogue")
			KEY_E: face("tavern")
			KEY_T: GameState.add_time(300.0)
			KEY_K: GameState.add_time(-GameState.time_remaining - 1.0)
			KEY_1:
				GameState.stats["regret"] = 5
				print("[debug] regret = 5 (low bucket)")
			KEY_2:
				GameState.stats["regret"] = 20
				print("[debug] regret = 20 (high bucket)")

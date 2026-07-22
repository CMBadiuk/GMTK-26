## Main scene controller (Phase 1)
## Hears GameState.game_over, computes the regret bucket, and swaps in the
## ending screen. Also hosts debug keys for triggering endings manually
extends Node2D

const EndingScreen := preload("res://scenes/ending_screen.tscn")

const REGRET_LOW_CUTOFF := 6

var _ending_shown := false

func _ready() -> void:
	GameState.game_over.connect(_on_game_over)
	print("Main scene and script have loaded")
	
func _on_game_over(reason: String) -> void:
	if _ending_shown:
		return
	_ending_shown = true
	var bucket := "low" if GameState.stats["regret"] <= REGRET_LOW_CUTOFF else "high"
	var ending := EndingScreen.instantiate()
	add_child(ending)
	ending.play(reason, bucket)
	
#	Debug Helpers (only runs in editor)
#	T : bank +5:00			(Spam past the win_threshold -> Reprieve)
#	K : drain the clock		(Force a timeout -> Last call)
#	1 : regret to LOW		(Sets regret to 5, earns you peace)
#	2 : regret to HIGH		(Sets regret to 20, die without peace)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_T:
				GameState.add_time(300.0)
			KEY_K:
				GameState.add_time(-GameState.time_remaining - 1.0)
			KEY_1:
				GameState.stats["regret"] = 5
				print("[debug] regret = 5 (low bucket)")
			KEY_2:
				GameState.stats["regret"] = 20
				print("[debug] regret = 20 (high bucket)")

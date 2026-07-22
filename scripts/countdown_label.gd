extends Label

func _ready() -> void:
	GameState.time_changed.connect(_on_time_changed)
	_on_time_changed(GameState.time_remaining)

func _on_time_changed(new_time: float) -> void:
	text = "TIME REMAINING: %s" % _format_time(new_time)
	
func _format_time(seconds: float) -> String:
	var s := int(max(seconds, 0.0)) 			# Clamp time so we never show a negative clock
	var minutes := s / 60						# Integer division
	var secs := s % 60
	return "%d:%02d" % [minutes, secs]

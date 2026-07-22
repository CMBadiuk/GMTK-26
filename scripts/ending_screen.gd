## Fuul-screen ending card (Some Phase 1 placeholder stuff)
## The ending text is chosen based on the reason for the ending, and a regret 
## bucket, resulting in four total endings (two reasons x two buckets)
## Writing is placeholder for now, real writing is in Phase 6
extends CanvasLayer

@onready var _fade: Control = $Fade
@onready var _title: Label = $Fade/Center/VBox/Title
@onready var _line: Label = $Fade/Center/VBox/Line

# Get a reason -> determine bucket -> [title, line]
const ENDINGS := {
	"time_won": {
		"low": ["REPRIEVE", "You said the hard things while you still could. Ryat gives you a smile, and lets you keep the morning."],
		"high": ["REPRIEVE", "You bought all the time you could. Ryat sighs and leaves you to your life, for now. However, you are no better for it."],
	},
	"timeout": {
		"low": ["LAST CALL", "You set your rag down. Through speaking with the God of Death, you realize that you've done all you need to with your life. You take Ryat's hand and go into The Realm Beyond with them."],
		"high": ["LAST CALL", "In the middle of a crass joke, the clock runs out. Ryat tells you it's time to go, and they pull you along into The Realm Beyond with all your regrets in tow."]
	}
}

## Called by the Main Scene controller right after this scene is instantiated
func play(reason: String, bucket: String) -> void:
	var data: Array = ENDINGS.get(reason, {}).get(bucket, ["THE END", "..."])
	_title.text = data[0]
	_line.text = data[1]
	_fade.modulate.a = 0.0
	create_tween().tween_property(_fade, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)

class_name DialogueResponse
extends Resource

@export var text: String					# The actual text written on the button, e.g. "[Heart] Tell the truth"
@export var stat: String = ""				# Either "" | "charm" | "wit" | "heart"
@export var difficulty: int = 0				# Think of it as DC in D&D
@export var time_reward: float = 15.0
@export var regret_delta: float = 0.0		# Should be negative, which is a regret confronted (Hard = -4)
@export var backstory_id: String = ""		# Optional hook for Phase 6 end-cards
@export var success_blocks: Array[String]	# Ryat's reaction and any other lines drawn on success (multi-line beat)
@export var fail_blocks: Array[String]		# Ryat's reaction and any other lines drawn on failure

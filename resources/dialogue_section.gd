## One dialogue encounter: Ryat's lead-in blocks, then a tiered set of options
class_name DialogueSection
extends Resource

@export var ryat_blocks: Array[String]			## Shown one at a time. Responses reveal on the last
@export var responses: Array[DialogueResponse]	## Authored easiest -> hardest (Safe/No stat, Charm, Wit, Heart

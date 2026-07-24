## StatUpgrade - buys a permanent boost to a visible stat (Charm, Wit, Heart)
## Authored as .tres; 'bought' mutates at runtime. Cost climbs on a steeper
## 1.6^bought curve than generators' 1.15^owned on purpose. Stats are power, so
## they compete with reinvesting income. 'Regret' should never have upgrades -
## That one's hidden and story-only
class_name StatUpgrade
extends Resource

@export var stat: String # i.e. charm, wit, or heart. Name must match from GameState
@export var amount: int = 1
@export var base_cost: int = 25
@export var bought: int = 0

func cost() -> int:
	return int(base_cost * pow(1.6, bought))

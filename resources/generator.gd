## Generator - a tavern job that generates coin passively
## Authoried as .tres files, owned/level mutate at runtime. Income scales
## linearly in units owned x level Buy cost climbs on the classic 1.15^owned
## idle curve so "buy more of this vs. save for the next tier" stay a live call
class_name Generator
extends Resource

@export var name: String					# Pour drinks, Cook food, etc
@export var flavor: String					# Theme-flavoured one-liner about the job
@export var base_cost: int					# Cost of the first unit, multiplied later
@export var base_income: float				# Coin per second per unit owned
@export var owned: int = 0
@export var level: int = 1					# Own upgrade track (for Phase 5)

func buy_cost() -> int:
	return int(base_cost * pow(1.15, owned))
	
func income_per_sec() -> float:
	return base_income * owned * level

func upgrade_cost() -> int:
	return int(base_cost * 5 * pow(1.5, level -1))

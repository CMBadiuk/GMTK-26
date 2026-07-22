## Game State - where all the core functions live, where the countdown goes
extends Node

signal time_changed(new_time)
signal time_added(amount)
signal coin_changed(new_coin)
signal stat_changed(stat, value)
signal game_over(reason)
# signal game_won() # Keeping just in case, but I might want to do branches for different game over conditions instead

var time_remaining := 300.0 # Time in seconds before Death takes you
var is_running := true
var win_threshold := 3000.0 # Time in seconds required to get Death off your back. Needs to be tuned

var coin := 0
var stats := { "charisma": 1, "wit": 1, "heart": 1, "regret": 20}

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_running:
		return
	time_remaining -= delta
	time_changed.emit(time_remaining)
	if time_remaining <= 0.0:
		is_running = false
		game_over.emit("timeout")
		# In whatever runs after this, add branches for different exposition based on the player's regret stat
	elif time_remaining >= win_threshold:
		is_running = false
		game_over.emit("time_won")
		
func add_time(amount):
	time_remaining += amount
	time_added.emit(amount) # The UI plays a sweet, satisfying effect
	time_changed.emit(time_remaining)
	
func add_coin(amount):
	coin += amount
	coin_changed.emit(coin)
	
func spend_coin(amount) -> bool:
	if coin < amount: return false
	coin += amount
	coin_changed.emit(coin)
	return true
	
func bump_stat(stat, amount):
	stats[stat] += amount
	stat_changed.emit(stat, stats[stat])

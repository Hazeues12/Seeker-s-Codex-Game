
extends Node

signal tola_changed(new_amount: int)
signal rank_changed(new_rank: String)

const RANKS = [
    "Stray", "Iron", "Bronze",
    "Silver", "Gold", "Grand", "Sage"
]

var player_name: String = "New Seeker"
var seeker_rank: String = "Stray"
var tola: int = 100

func earn_tola(amount: int) -> void:
    if amount <= 0:
        return
    tola += amount
    tola_changed.emit(tola)

func spend_tola(amount: int) -> bool:
    if amount < 0 or amount > tola:
        return false
    tola -= amount
    tola_changed.emit(tola)
    return true

func set_rank(new_rank: String) -> bool:
    if not new_rank in RANKS:
        return false
    seeker_rank = new_rank
    rank_changed.emit(seeker_rank)
    return true

class_name HotelEconomy
extends RefCounted

signal changed

const STARTING_CASH: int = 12000
const LEDGER_LIMIT: int = 200
var cash: int = STARTING_CASH
var revenue: int = 0
var expenses: int = 0
var capital_spent: int = 0
var ledger: Array[Dictionary] = []

func transact(amount: int, reason: String, time: float, capital: bool = false) -> void:
	cash += amount
	if amount > 0:
		revenue += amount
	elif capital:
		capital_spent -= amount
	else:
		expenses -= amount
	ledger.append({"amount": amount, "reason": reason, "time": time})
	if ledger.size() > LEDGER_LIMIT:
		ledger.pop_front()
	changed.emit()

func purchase(cost: int, reason: String, time: float) -> bool:
	if cost < 0 or cash < cost:
		return false
	transact(-cost, reason, time, true)
	return true

func profit() -> int:
	return revenue - expenses

func refund_capital(amount: int, reason: String, time: float) -> bool:
	if amount < 0 or amount > capital_spent:
		return false
	cash += amount
	capital_spent -= amount
	ledger.append({"amount": amount, "reason": reason, "time": time})
	if ledger.size() > LEDGER_LIMIT:
		ledger.pop_front()
	changed.emit()
	return true

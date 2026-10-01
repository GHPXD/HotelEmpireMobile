class_name PlayerWorkRules
extends Resource
## One data source for short manual actions and early pacing hypotheses.

@export var checkin_seconds: float = 1.5
@export var cleaning_seconds: float = 3.0
@export var preparation_seconds: float = 2.0
@export var delivery_seconds: float = 1.0
@export var repair_seconds: float = 3.0
@export var repair_cost: int = 5
@export var walk_speed: float = 2.4
@export var order_hunger: float = 55.0
@export var order_lifetime: float = 30.0
@export var pending_limit: int = 24
@export var room_wear_per_stay: int = 8
@export var service_wear: int = 3
@export var reception_wear: int = 2
@export var maximum_slowdown: float = 0.2
@export var mobile_starting_cash: int = 2400

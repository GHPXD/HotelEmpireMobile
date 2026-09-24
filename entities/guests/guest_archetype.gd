class_name GuestArchetype
extends Resource

@export var id: StringName
@export var display_name: String
@export var description: String
@export var budget: int = 320
@export var price_weight: float = 0.15
## Satisfaction points per percentage point away from the standard lodging tariff.
@export var lodging_value_weight: float = 0.3
@export var duration_weight: float = 0.0
@export var entertainment_weight: float = 1.0
@export var entertainment_rate: float = 0.1
@export var patience_multiplier: float = 1.0
@export var stay_multiplier: float = 1.0
@export var color: Color = Color("e6a84d")

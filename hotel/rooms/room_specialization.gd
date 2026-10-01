class_name RoomSpecialization
extends Resource
## Authored positioning of a room. Runtime stores only its stable ID.

@export var id: StringName
@export var cost: int = 500
@export var construction_seconds: int = 300
@export var minimum_level: int = 3
@export var required_objective: StringName = &"first_stays"
@export var price_delta: int = 0
@export var maintenance_delta: int = 0
@export var satisfaction_delta: float = 0.0
@export var stay_multiplier: float = 1.0
@export var profile_preference: Dictionary[StringName, float] = {}
@export var admission_satisfaction: Dictionary[StringName, float] = {}
@export var expected_condition: int = 0
@export var expectation_penalty: float = 0.0

func preference(profile: GuestArchetype) -> float:
	return profile_preference.get(profile.id, 0.0)

func arrival_bonus(profile: GuestArchetype, condition: int) -> float:
	return admission_satisfaction.get(profile.id, 0.0) - (expectation_penalty if condition < expected_condition else 0.0)

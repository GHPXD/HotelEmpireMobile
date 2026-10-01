class_name MockRemoteConfigProvider
extends RemoteConfigProvider

var response: Dictionary = {}

func fetch() -> Dictionary:
	return response.duplicate(true)

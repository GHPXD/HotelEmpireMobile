class_name MockAnalyticsProvider
extends AnalyticsProvider

var available: bool = true
var received: Array[Dictionary] = []

func send(event: Dictionary) -> bool:
	if not available:
		return false
	received.append(event.duplicate(true))
	return true

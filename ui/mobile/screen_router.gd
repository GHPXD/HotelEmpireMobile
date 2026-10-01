class_name ScreenRouter
extends RefCounted
## One screen, at most one contextual sheet. No nested desktop windows.

signal changed
const SCREENS: Array[StringName] = [&"hotel", &"build", &"missions", &"staff", &"store", &"settings"]
var screen: StringName = &"hotel"
var sheet: StringName = &""
var context_id: int = -1

func navigate(destination: StringName) -> void:
	if destination not in SCREENS:
		return
	if screen == destination and sheet.is_empty():
		return
	screen = destination
	sheet = &""
	context_id = -1
	changed.emit()

func open_sheet(kind: StringName, id: int = -1) -> void:
	if sheet == kind and context_id == id:
		return
	sheet = kind
	context_id = id
	changed.emit()

func close_sheet() -> void:
	if sheet.is_empty():
		return
	sheet = &""
	context_id = -1
	changed.emit()

func back() -> bool:
	if not sheet.is_empty():
		close_sheet()
		return true
	if screen != &"hotel":
		navigate(&"hotel")
		return true
	return false

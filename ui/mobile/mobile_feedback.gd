class_name MobileFeedback
extends RefCounted
## Translate legacy command results at the presentation boundary during migration.

const LEGACY_ERRORS: Dictionary = {
	"Selecione uma construção.": "error.select_build",
	"Construa o andar primeiro.": "error.floor_first",
	"Fora do terreno.": "error.outside",
	"A recepção precisa ficar no térreo.": "error.ground_reception",
	"O poço precisa estar livre em todos os andares.": "error.shaft",
	"Espaço ocupado.": "error.occupied",
	"Caixa insuficiente.": "error.cash",
	"Caixa insuficiente para contratar.": "error.cash",
	"Caixa insuficiente para o andar.": "error.cash",
	"Caixa insuficiente para melhorar.": "error.cash",
	"Limite de 40 andares atingido.": "error.floor_limit",
	"Sala em uso. Aguarde a liberação.": "error.room_busy",
}

static func key(error: String) -> String:
	if error.begins_with("save.error."):
		return error
	if error.begins_with("Conclua o objetivo:") or error == "Conteúdo indisponível.":
		return "error.locked"
	return LEGACY_ERRORS.get(error, "error.command")

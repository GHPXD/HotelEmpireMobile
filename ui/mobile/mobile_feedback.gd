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
	"Caixa insuficiente para a melhoria.": "error.cash",
	"Limite de 40 andares atingido.": "error.floor_limit",
	"Sala em uso. Aguarde a liberação.": "error.room_busy",
	"Um funcionário está a caminho. Aguarde sua chegada.": "error.room_busy",
	"Há alguém usando ou indo para esta sala.": "error.room_busy",
	"Aguarde todos descerem antes de remover o elevador.": "error.lift_busy",
	"Esta recepção já possui um recepcionista.": "error.reception_assigned",
	"Andar inexistente ou sem acesso por elevador.": "error.floor_access",
}

static func key(error: String) -> String:
	if error.begins_with("specialization.error."):
		return error
	if error.begins_with("construction.error."):
		return error
	if error.begins_with("speedup.error."):
		return error
	if error.begins_with("save.error.") or error.begins_with("error.") or error.begins_with("work.error.") or error.begins_with("staff.error."):
		return error
	if error.begins_with("Conclua o objetivo:") or error == "Conteúdo indisponível.":
		return "error.locked"
	return LEGACY_ERRORS.get(error, "error.command")

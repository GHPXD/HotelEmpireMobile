class_name UILabels
extends RefCounted

const STATES: Dictionary = {&"arriving": "Chegando", &"walking": "Caminhando", &"lift_queue": "Esperando elevador", &"riding": "No elevador", &"checkin": "Na recepção", &"deciding": "Escolhendo atividade", &"service_queue": "Esperando serviço", &"using": "Em atendimento", &"exit": "Saindo", &"idle": "Disponível", &"working": "Atendendo", &"cleaning": "Limpando"}
const ROLES: Dictionary = {&"guest": "Hóspede", &"receptionist": "Recepcionista", &"cleaner": "Camareiro(a)"}

static func state(value: StringName) -> String:
	return STATES.get(value, "Estado desconhecido")

static func role(value: StringName) -> String:
	return ROLES.get(value, "Equipe")

static func room_reference(hotel: HotelModel, id: int) -> String:
	var room := hotel.by_id(id)
	if room == null:
		return "Sem sala definida"
	return "%s #%d • %s" % [room.definition().display_name, room.id, "térreo" if room.floor_index == 0 else "andar %d" % room.floor_index]

static func actor_goal(actor: ActorState, hotel: HotelModel) -> String:
	var destination: StringName = actor.destination_state if actor.in_transit() else actor.state
	match destination:
		&"exit":
			return "Sair do hotel • saída no térreo"
		&"arriving", &"checkin":
			return "Fazer check-in • " + room_reference(hotel, actor.target_room)
		&"service_queue", &"using":
			var room := hotel.by_id(actor.target_room)
			var activity := "Descansar" if room != null and room.definition().category == &"lodging" else "Usar serviço"
			return activity + " • " + room_reference(hotel, actor.target_room)
		&"cleaning":
			return "Limpar • " + room_reference(hotel, actor.assignment)
		&"working":
			return "Atender • " + room_reference(hotel, actor.assignment)
		&"deciding":
			return "Escolher a próxima atividade"
	return "Aguardar tarefa"

static func actor_wait(actor: ActorState) -> String:
	match actor.state:
		&"checkin":
			return "Tempo nesta recepção: %.1fs" % actor.waiting
		&"service_queue":
			return "Espera nesta fila de serviço: %.1fs" % actor.waiting
		&"lift_queue":
			return "Espera nesta fila de elevador: %.1fs" % actor.waiting
	return ""

const CHECKIN: Dictionary = {
	"empty": "Sem fila de check-in.",
	"head_travelling": "O primeiro hóspede está chegando à recepção.\nAguarde sua chegada para iniciar o atendimento.",
	"unstaffed": "Recepção sem funcionário atendendo.\nConfira a contratação e a atribuição de um recepcionista em Equipe.",
	"processing": "Atendimento em andamento.\nAguarde ou melhore a recepção para reduzir o tempo de check-in.",
	"ready": "Há um quarto disponível para o primeiro hóspede.\nO próximo atendimento pode concluir a reserva.",
	"cleaning": "Aguardando quarto limpo.\nConfira a equipe de limpeza e o acesso dos camareiros aos quartos.",
	"occupied": "Os quartos disponíveis para este hóspede estão ocupados.\nAguarde uma saída ou amplie a hospedagem.",
	"unaffordable": "Quartos fora do orçamento do primeiro hóspede.\nConfira as tarifas; quartos sem melhorias oferecem preço menor.",
	"no_accessible_bedroom": "Nenhum quarto com acesso para o primeiro hóspede.\nConstrua quartos e conecte os andares superiores por elevador.",
}

static func checkin(reason: String) -> String:
	return CHECKIN.get(reason, "Não foi possível avaliar esta fila.")

static func elevator(metrics: Dictionary) -> String:
	var history: String = "Sem embarques registrados."
	if metrics.boarded > 0:
		history = "Espera até embarcar: média %.1fs • máxima %.1fs" % [metrics.average_wait, metrics.max_wait]
	return "Cabine: %d/%d • Na fila: %d • Maior espera atual: %.1fs\n%s\nHistórico: %d embarques • %d viagens de passageiros concluídas" % [metrics.passengers, metrics.capacity, metrics.queue, metrics.current_max, history, metrics.boarded, metrics.delivered]

static func search_key(value: String) -> String:
	var result := value.strip_edges().to_lower()
	for replacement in [["á", "a"], ["à", "a"], ["â", "a"], ["ã", "a"], ["é", "e"], ["ê", "e"], ["í", "i"], ["ó", "o"], ["ô", "o"], ["õ", "o"], ["ú", "u"], ["ç", "c"]]:
		result = result.replace(replacement[0], replacement[1])
	return result

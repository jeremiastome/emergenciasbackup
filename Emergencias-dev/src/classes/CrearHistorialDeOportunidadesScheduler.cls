global class CrearHistorialDeOportunidadesScheduler implements Schedulable {
	global void execute(SchedulableContext SC) {
		CrearHistorialDeOportunidadesBatch batch = new CrearHistorialDeOportunidadesBatch('=YESTERDAY');
		Database.executeBatch(batch, 30);
	}
}
global class ActivarContratosScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		if(Casos_activan_contrato_a_futuro__c.getAll().size() != 0) {
			Database.executeBatch( new ActivarContratosBatch() , 1 );
		}
	}
}
global class CrearHistorialDeCasosScheduler implements Schedulable {
	global void execute(SchedulableContext SC) {
		CrearHistorialDeCasosBatch pedidoDeBajaBatch = new CrearHistorialDeCasosBatch('=YESTERDAY', 'Pedido_de_Baja');
		Database.executeBatch(pedidoDeBajaBatch, 30);
        
        CrearHistorialDeCasosBatch gestionDeMoraBatch = new CrearHistorialDeCasosBatch('=YESTERDAY', 'Gestion_de_Mora');
		Database.executeBatch(gestionDeMoraBatch, 30);
	}
}
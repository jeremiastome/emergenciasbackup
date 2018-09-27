global class BatchAddresssAmntToRelation implements Database.Batchable<SObject> {
	
	global BatchAddresssAmntToRelation() {
		
	}
	
	/**
	 * @description gets invoked when the batch job starts
	 * @param context contains the job ID
	 * @returns the record set as a QueryLocator object that will be batched for execution
	 */
	global Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator(
			'SELECT Id, Cantidad_domicilio__c, Cantidad_domicilio_en_transito__c, '
				+ 'Beneficiario__r.Cantidad_de_Personas_Fijas__c, '
				+ 'Beneficiario__r.Cantidad_de_personas_en_transito__c '
			+ 'FROM Cobertura_de_Beneficiario__c '
			+ 'WHERE Beneficiario__r.RecordType.DeveloperName = \'Domicilio\' '
				+ 'AND Cantidad_domicilio__c = null '
				+ 'AND Cantidad_domicilio_en_transito__c = null'
		);
	}
	
	/**
	 * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
	 * @param context contains the job ID
	 * @param scope contains the batch of records to process.
	 */
	global void execute(Database.BatchableContext context, List<Cobertura_de_Beneficiario__c> scope) {
		List<Cantidad_de_producto_de_beneficiaro__c> amountDetails =
			new List<Cantidad_de_producto_de_beneficiaro__c>();
		for(Cobertura_de_Beneficiario__c rel : scope) {
			Cantidad_de_producto_de_beneficiaro__c det = new Cantidad_de_producto_de_beneficiaro__c(
				Activo__c = true,
				Cantidad__c = rel.Beneficiario__r.Cantidad_de_Personas_Fijas__c,
				Cantidad_en_transito__c = rel.Beneficiario__r.Cantidad_de_personas_en_transito__c,
				Cobertura_de_Beneficiario__c = rel.Id
			);
			
			amountDetails.add(det);
		}
		
		insert amountDetails;
	}
	
	/**
	 * @description gets invoked when the batch job finishes. Place any clean up code in this method.
	 * @param context contains the job ID
	 */
	global void finish(Database.BatchableContext context) {
		
	}
}
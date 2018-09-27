global class SendContractToSAPBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
	global Database.QueryLocator start(Database.BatchableContext bc){
		String query = 'SELECT Id FROM Contrato__c';
		TipoOperacionEnvioSAP__c opContr = TipoOperacionEnvioSAP__c.getValues('Contratos');
		if(opContr != null && opContr.Where_clause__c != null) {
			query += ' WHERE ' + opContr.Where_clause__c;
		}
		
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, list<Contrato__c> scope){
		TipoOperacionEnvioSAP__c opContr = TipoOperacionEnvioSAP__c.getValues('Contratos');
		String operation = 'A';
		if(opContr != null && opContr.Operacion__c != null) {
			operation = opContr.Operacion__c;
		}
		
		for(Contrato__c con : scope) {
			con.Saltear_envio__c = 2;
			con.Esperando_envio__c = true;
			if(operation == 'B') {
				con.Estado__c = 'Baja';
			}
			else if(operation == 'A') {
				con.Estado__c = 'Activo';
			}
			
			ContractSenderQueable csq = new ContractSenderQueable(con.Id, operation);
			System.enqueueJob(csq);
		}
		
		update scope;
	}
	
	global void finish(Database.BatchableContext BC){
		TipoOperacionEnvioSAP__c opContr = TipoOperacionEnvioSAP__c.getValues('Contratos');
		if(!Test.isRunningTest() && String.isNotBlank(opContr.Email_al_finalizar__c)) {
			//Tests and mail do not play well together
			Utils.enviarCorreoLog(
				'Batch Enviar Contratos terminado',
				new List<String> {'El batch con Id "' + BC.getJobId() + '" ha terminado.'},
				new List<String> {opContr.Email_al_finalizar__c}
			);
		}
	}
}
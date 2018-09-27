global class SendAccountToSAPBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{
	global Database.QueryLocator start(Database.BatchableContext bc){
		String query =  'SELECT Id FROM Account';
		
		TipoOperacionEnvioSAP__c opContr = TipoOperacionEnvioSAP__c.getValues('Cuentas');
		if(opContr != null && opContr.Where_clause__c != null) {
			query += ' WHERE ' + opContr.Where_clause__c;
		}
		
		return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext BC, list<Account> scope){
		TipoOperacionEnvioSAP__c opContr = TipoOperacionEnvioSAP__c.getValues('Cuentas');
		String operation = 'A';
		if(opContr != null && opContr.Operacion__c != null) {
			operation = opContr.Operacion__c;
		}
		for(Account acc : scope){
			AccountSenderQueueable asq = new AccountSenderQueueable(acc.Id, operation);
			System.enqueueJob(asq);
		}
	}
	
	global void finish(Database.BatchableContext BC){
		TipoOperacionEnvioSAP__c opContr = TipoOperacionEnvioSAP__c.getValues('Cuentas');
		if(!Test.isRunningTest() && String.isNotBlank(opContr.Email_al_finalizar__c)) {
			//Tests and mail do not play well together
			Utils.enviarCorreoLog(
				'Batch enviar cuentas terminado',
				new List<String> {'El batch con Id "' + BC.getJobId() + '" ha terminado.'},
				new List<String> {opContr.Email_al_finalizar__c}
			);
		}
	}
}
global class BatchCloneSendContracts implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
	private Set<Id> failedContracts;
	private Set<Id> waitingContracts;
	private Set<Id> createdContracts;
	String csvStr;
	
	global Database.QueryLocator start(Database.BatchableContext context) {
		String query = 'SELECT Id, Esperando_envio__c, Estado_de_Envio_a_SAP__c, Estado__c FROM Contrato__c';
		TipoOperacionEnvioSAP__c opContr = TipoOperacionEnvioSAP__c.getValues('Contratos');
		if(opContr != null && opContr.Where_clause__c != null) {
			query += ' WHERE ' + opContr.Where_clause__c;
		}
		
		failedContracts = new Set<Id>();
		waitingContracts = new Set<Id>();
		createdContracts = new Set<Id>();
		csvStr = 'Original_Contract_Id,Cloned_Contract_Id,Send_Status\n';
		
		return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext BC, List<Contrato__c> scope) {
		Set<Id> contractIds = new Set<Id>();
		for(Contrato__c con : scope) {
			if(!con.Esperando_envio__c) {
				if(con.Estado_de_Envio_a_SAP__c == 'Ok' && con.Estado__c == 'Baja') {
					contractIds.add(con.Id);
				}
				else {
					csvStr += con.Id + ',NULL,Fallo\n';
					failedContracts.add(con.Id);
				}
			}
			else {
				csvStr += con.Id + ',NULL,Esperando envio\n';
				waitingContracts.add(con.Id);
			}
		}
		
		Map<Id, Contrato__c> clonedContracts;
		try {
			clonedContracts = ClonarContrato.clonar(contractIds);
		}
		catch(Exception e) {
			for(Id conId : contractIds) {
				csvStr += conId + ',NULL,Error de clonacion: "' + e.getMessage().replace('\n', ' ').replace(',', ';') + '"\n';
			}
		}
		
		if(clonedContracts != null) {
			for(Id originalId : clonedContracts.keySet()) {
				Contrato__c con = clonedContracts.get(originalId);
				con.Estado__c = 'Activo';
				con.Saltear_envio__c = 2;
				con.Esperando_envio__c = true;
				
				ContractSenderQueable csq = new ContractSenderQueable(con.Id, 'A');
				System.enqueueJob(csq);
				createdContracts.add(con.Id);
				csvStr += originalId + ',' + con.Id + ',Ok\n';
			}
			
			update clonedContracts.values();
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		System.debug('==================================================');
		System.debug('Failed Contracts');
		System.debug(failedContracts.size());
		System.debug('==================================================');
		System.debug('Waiting Contracts');
		System.debug(waitingContracts.size());
		System.debug('==================================================');
		System.debug('Created Contracts');
		System.debug(createdContracts.size());
		System.debug('==================================================');
		saveCSV();
		
		TipoOperacionEnvioSAP__c opContr = TipoOperacionEnvioSAP__c.getValues('Contratos');
		if(!Test.isRunningTest() && String.isNotBlank(opContr.Email_al_finalizar__c)) {
			//Tests and mail do not play well together
			Utils.enviarCorreoLog(
				'Batch clonar contratos terminado',
				new List<String> {'El batch con Id "' + BC.getJobId() + '" ha terminado.'},
				new List<String> {opContr.Email_al_finalizar__c}
			);
		}
	}
	
	private void saveCSV() {
		ContentVersion cv = new ContentVersion(
			Title = 'BatchCloneResult-' + System.now().format('YYYY-MM-dd-HH-mm-ss') + '.csv',
			VersionData = blob.valueOf(csvStr),
			PathOnClient = '/noPath/'
		);
		
		insert cv;
	}
}
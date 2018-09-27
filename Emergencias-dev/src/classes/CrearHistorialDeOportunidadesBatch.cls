global class CrearHistorialDeOportunidadesBatch implements Database.Batchable<sObject>, Database.Stateful { 

    private List<Id> opps;
    private integer counterQueryOpps;
   	global final String queryy;
	global final String datee;
    global String plusQuery;

   	global CrearHistorialDeOportunidadesBatch(String datee){
        plusQuery='';
        counterQueryOpps=0;
		this.datee = datee;
        opps = new List<id>();
        String relationQuery='';
        if(!Test.isRunningTest()) {   /// HISTORYS CANT BE TESTED 
            relationQuery=                
                'AND Id in ('+
                'SELECT OpportunityId '+
                'FROM OpportunityHistory '+
                'WHERE StageName=\'Ganada\' ' +
                'AND CreatedDate'+datee+') '; 
        }
        
		queryy = 'SELECT Id, Contrato__c, '+
					'(SELECT Id FROM Historiales_de_productos__r)'+
				'FROM Opportunity '+
 				'WHERE  IsWon=true '+
            		relationQuery+
            		plusQuery;
	}	

	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(queryy);
	}
    
	global void execute(Database.BatchableContext BC, List<Opportunity> scope){
		counterQueryOpps+=scope.size();
        
		List<Id> oppIds = new List<Id>();
		for (integer i=0; i<scope.size(); i++) { 
			if(scope[i].Historiales_de_productos__r.size()==0) {
				oppIds.add(scope[i].id);
			} else {
				scope.remove(i);
			}
		}
		opps.addAll(oppIds);
		List<Cobertura_de_beneficiario__c> recipientCoverages = [SELECT Id,
																Cobertura__c,
																Creado_en_Oportunidad__c,
																(SELECT Id FROM Aplicantes__r)
																FROM Cobertura_de_Beneficiario__c
																WHERE Creado_en_Oportunidad__c IN :oppIds];

		List<Cobertura__c> coverageWithDiscounts = [SELECT Id,
													Contrato__c,
													(SELECT Id FROM Descuentos_Recargos_Aplicados__r)
													FROM Cobertura__c
													WHERE Creado_en_opp__c IN :oppIds];
		
		
		Map<Id, List<Descuento_Recargo_Aplicado__c>> discountsByCoverage = new Map<Id, List<Descuento_Recargo_Aplicado__c>>();

		for(Cobertura__c coverage : coverageWithDiscounts) {
			discountsByCoverage.put(coverage.id, coverage.Descuentos_Recargos_Aplicados__r);
		}

		Map<Id, List<Cobertura_de_beneficiario__c>> coveragesByOpp = new Map<Id, List<Cobertura_de_beneficiario__c>>();

		for (Opportunity opp : scope) {
			List<Cobertura_de_beneficiario__c> coverages = new List<Cobertura_de_Beneficiario__c>();

			for(Cobertura_de_Beneficiario__c coverage : recipientCoverages) {
				if(coverage.Creado_en_Oportunidad__c==opp.id) {
					coverages.add(coverage);
				}
			}
			coveragesByOpp.put(opp.Id, coverages);

		}
		
		Map<Id, Historial_de_Producto__c> historys = new Map<Id, Historial_de_Producto__c>();
		for (Opportunity opp : scope) {
			List<Cobertura_de_Beneficiario__c> coverages = coveragesByOpp.get(opp.id);
			Set<Id> contractProducts = new Set<Id>();

			for(Cobertura_de_beneficiario__c coverage : coverages) {
				if(!contractProducts.contains(coverage.cobertura__c)) {
					contractProducts.add(coverage.cobertura__c);
				}
			}

			for(Id contractProduct : contractProducts) {
				Historial_de_Producto__c history = new Historial_de_Producto__c();
                history.Producto_de_contrato__c= contractProduct;
				integer recipientCount=0;
				integer applicants=0;
				for(Cobertura_de_beneficiario__c coverage : coverages) {
					if(coverage.Cobertura__c==contractProduct) {
						recipientCount++;
						applicants+=coverage.Aplicantes__r.size();

					}
				}
				history.Cantidad_de_beneficiarios__c=recipientCount;
				history.Cantidad_de_bonificados__c=applicants;
				history.Oportunidad__c=opp.Id; 
				historys.put(contractProduct, history);
			}
		}

        if(!historys.values().isEmpty()) {
			insert historys.values();
        }

		List<Descuento_Recargo_Aplicado__c> discounts = new List<Descuento_Recargo_Aplicado__c>();
		for(Cobertura__c coverage : coverageWithDiscounts) {
			if(historys.containsKey(coverage.Id)) {
				Historial_de_Producto__c history = historys.get(coverage.Id);
				for (Descuento_Recargo_Aplicado__c discount : discountsByCoverage.get(coverage.id)) {
					discount.Historial_de_Producto__c= history.Id;
					discounts.add(discount);
				}
			}
		}

        if(!discounts.isEmpty()){
        	update discounts;
        }		
	}
    
	global void finish(Database.BatchableContext BC){
    	String csvStr = 'Id; Num de Historiales \n';
        System.debug(opps);
        List<Opportunity> OppsQuery = [SELECT Id, Name, 
                                      (SELECT Id FROM Historiales_de_productos__r)
                                      FROM Opportunity
                                      WHERE Id IN :this.opps];
        
        for (Opportunity opp : OppsQuery) {
            csvStr+=opp.id +';'+ opp.Historiales_de_productos__r.size() +'\n';
        }
        
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
        mail.setToAddresses(new String[] {'salesforce.alerts@xappia.com'});
        mail.setReplyTo('noreply@privatebudget.com');
        mail.setSenderDisplayName('Emergencias ');
        mail.setSubject('Historial de oportunidades ' + Date.today());
        mail.setBccSender(false);
        mail.setUseSignature(false);
        
        mail.setPlainTextBody('Terminado el proceso de CrearHistorialDeOportunidadesBatch del dia '+Date.today() + '. \n'+
                              'Encontradas: '+counterQueryOpps+'. \n' +
                              'Procesadas: '+opps.size()+'. \n'+
                              'En Query: '+OppsQuery.size()+'. \n\n'+
                              'Id del proceso: '+BC.getJobId()+'.\n'+
                              'Id del documento: '+saveCSV(csvStr)+'.');
        if(!test.isRunningTest()) {
        	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
        }
	}

	private id saveCSV(String csvStr) {
		ContentVersion cv = new ContentVersion(
			Title = 'BatchCrearHistorialDeOportunidad-' + System.now().format('YYYY-MM-dd-HH-mm-ss') + '.csv',
			VersionData = blob.valueOf(csvStr),
			PathOnClient = '/noPath/'
		);
		
		insert cv;
        return cv.id;
	}
}
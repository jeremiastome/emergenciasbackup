trigger Cobertura on Cobertura__c (before delete)  {
    
    List<Cobertura_de_beneficiario__c> recipients = [SELECT Id, 
                                        		Cobertura__c,
                                                (SELECT Id FROM Aplicantes__r)                                        
                                                FROM Cobertura_de_beneficiario__c
                                                WHERE Cobertura__c IN :Trigger.oldMap.keySet()
                                                ];
    
	List<Aplicante__c> aplicantsToBeRemoved = new List<Aplicante__c>();

    for (Cobertura_de_Beneficiario__c recipientCoverage : recipients) {
        if (recipientCoverage.aplicantes__r.size()!=0) {
            aplicantsToBeRemoved.addAll(recipientCoverage.aplicantes__r);
        }
    }
    if(aplicantsToBeRemoved.size()!=0) {
    	delete aplicantsToBeRemoved;
    }
	
	List<Cobertura__c> coverages =  [SELECT Id, 
									(SELECT Id FROM Beneficiarios__r)
									 FROM Cobertura__c
									 WHERE Id IN :Trigger.oldMap.keySet() ];

	List<Cobertura_de_Beneficiario__c> recipientCoverages = new List<Cobertura_de_Beneficiario__c>();
	for (Cobertura__c coverage : coverages) {
        if(coverage.Beneficiarios__r.size()>=200) {
			recipientCoverages.addAll( coverage.Beneficiarios__r );
        }
	}
   	if(recipientCoverages.size()!=0) {
    	delete recipientCoverages;
    }
    
 }
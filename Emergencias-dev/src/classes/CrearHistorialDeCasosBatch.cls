global class CrearHistorialDeCasosBatch implements Database.Batchable<sObject>{  

   	global final String queryy;
	global final Map<String, id> recordTypes;

   	global CrearHistorialDeCasosBatch (String dat, String recordTypeDev){
 
		queryy = 'SELECT Id,  Motivo_de_baja__c, '+
				'RecordType.DeveloperName, Contrato__c,'+
				'(SELECT Id FROM Historiales_de_productos__r),'+
            	'(SELECT Id, Beneficiario__c, Titular__c FROM Bajas_parciales__r)'+
				'FROM Case '+
 				'WHERE IsClosed=true '+
                'AND ClosedDate'+dat+' '+
            	'AND RecordType.DeveloperName=\''+recordTypeDev+'\'';
	}	

	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(queryy);
	}
    
	global void execute(Database.BatchableContext BC, List<Case> scope){
		System.debug(scope);
	    List<Case> desactiveRecipientCases = new List<Case>();
		List<Case> bonusCases = new List<Case>();
		List<Case> activeRecipientCases = new List<Case>();
		List<Case> coverageChangeCases = new List<Case>();
       	List<Id> caseIds = new List<Id>();
		
		for (integer i=0; i<scope.size(); i++) { 
			if(scope[i].Historiales_de_productos__r.size()==0) {
				caseIds.add(scope[i].id);
				if(scope[i].RecordType.DeveloperName=='Pedido_de_baja' || scope[i].RecordType.DeveloperName=='Gestion_de_Mora') {
					desactiveRecipientCases.add(scope[i]);
				}
				if(scope[i].RecordType.DeveloperName=='Bonificacion') {
					bonusCases.add(scope[i]);
				}
				if(scope[i].RecordType.DeveloperName=='Alta_de_Beneficiario') {
					activeRecipientCases.add(scope[i]);
				}
				if(scope[i].RecordType.DeveloperName=='Cambio_de_cobertura') {
					coverageChangeCases.add(scope[i]);
				}
			} else {
				scope.remove(i);
				i--;
			}
		}
		
        Map<Id, Historial_de_Producto__c> historys = new Map<Id, Historial_de_Producto__c>();

		if(!desactiveRecipientCases.isEmpty()) {
			historys.putAll(createForDeactivateRecipientCases(desactiveRecipientCases));
		}
		if(!bonusCases.isEmpty()) {

		}
		if(!activeRecipientCases.isEmpty()) {
			historys.putAll(createForActivateRecipientCases(activeRecipientCases, caseIds));
		}
		if(!coverageChangeCases.isEmpty()) {

		}
        
        List<Descuento_Recargo_Aplicado__c> discounts = new List<Descuento_Recargo_Aplicado__c>();
        
        List<Cobertura__c> coverageWithDiscounts = [SELECT Id,
													Contrato__c,
													(SELECT Id FROM Descuentos_Recargos_Aplicados__r)
													FROM Cobertura__c
													WHERE Creado_en_Caso__c IN :caseIds];
		
		
		Map<Id, List<Descuento_Recargo_Aplicado__c>> discountsByCoverage = new Map<Id, List<Descuento_Recargo_Aplicado__c>>();

		for(Cobertura__c coverage : coverageWithDiscounts) {
			discountsByCoverage.put(coverage.id, coverage.Descuentos_Recargos_Aplicados__r);
		}
        
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
           
	}
    
    private Map<Id, Historial_de_producto__c> createForDeactivateRecipientCases (List<Case> cases) {
		Map<Id, Historial_de_producto__c> historys  = new Map<Id, Historial_de_producto__c>();
		List<id> contractIds = new List<Id>();
        
        for(Case c : cases) {
            contractIds.add(c.Contrato__c);
        }
        
        List<Cobertura__c> coverages = [SELECT Id,
										Contrato__c,
										(SELECT Id FROM Descuentos_Recargos_Aplicados__r),
                                        (SELECT Id, Beneficiario__c FROM Beneficiarios__r)
										FROM Cobertura__c	
										WHERE Contrato__c IN :contractIds];
        
        List<Titular__c> holders = [SELECT Id,
            						(SELECT Id FROM Beneficiarios__r)
                                    FROM Titular__c
                                    WHERE Contrato__c IN :contractIds];
        
        Map<Id, Titular__c> holdersById = new Map<Id, Titular__c>();
        for (Titular__c holder : holders) {
            holdersById.put(holder.id, holder);
        }
        
		System.debug(coverages);
        
        for(Case c : cases) {
            if(c.Bajas_parciales__r.size()==0) {
                for (Cobertura__c coverage : coverages) {
                    if(coverage.Contrato__c==c.Contrato__c) {
                        Historial_de_producto__c history = new Historial_de_producto__c();
                        history.Caso__c=c.id;
                        history.Cantidad_de_bajas__c=coverage.beneficiarios__r.size();
                        history.Producto_de_Contrato__c=coverage.id;
                        historys.put(coverage.id, history);
                    }
                }
            } else {
                for (Cobertura__c coverage : coverages) {

                    if(coverage.Contrato__c==c.Contrato__c) {
                        Set<Id> countedRecipient = new Set<Id>();
                        Historial_de_producto__c history = new Historial_de_producto__c();
                        history.Caso__c=c.id;
                        history.Producto_de_Contrato__c=coverage.id;
                        history.Cantidad_de_bajas__c=0;
                		for (Baja_parcial__c partialLosse : c.Bajas_parciales__r) {
                            if(partialLosse.beneficiario__c!=null) {
                                for(Cobertura_de_beneficiario__c recipientCoverage : coverage.Beneficiarios__r) {
                                    if(partialLosse.Beneficiario__c==recipientCoverage.Beneficiario__c & 
                                      !countedRecipient.contains(partialLosse.Beneficiario__c)){
                                        history.Cantidad_de_bajas__c++;
                                        countedRecipient.add(partialLosse.Beneficiario__c);
                                    }
                                }
                            }
                            if(partialLosse.Titular__c!=null) { // avoiding bugs
                                if(holdersById.containsKey(partialLosse.Titular__c)) {
                                    Titular__c holder = holdersById.get(partialLosse.Titular__c);
                               		for(Cobertura_de_beneficiario__c recipientCoverage : coverage.Beneficiarios__r) {
                                        for (Beneficiario__c recipient : holder.Beneficiarios__r) {
                                            if(recipient.id==recipientCoverage.Beneficiario__c & 
                                              !countedRecipient.contains(recipient.id)){
                                                history.Cantidad_de_bajas__c++;
                                                countedRecipient.add(recipient.id);
											}
                                        }
                                    }
                                }
                            }
						}
                        if(history.Cantidad_de_bajas__c!=0) {
                        	historys.put(coverage.id, history);
                        }
                    }
                }
            }
        }
        if(!historys.values().isEmpty()) {
			insert historys.values();
        }
        return historys;
    }
    
    private Map<Id, Historial_de_Producto__c> createForActivateRecipientCases (List<Case> scope, List<Id> caseIds) {
        
        List<Cobertura_de_beneficiario__c> recipientCoverages = [SELECT Id,
																Cobertura__c,
																Creado_en_Caso__c,
																(SELECT Id FROM Aplicantes__r)
																FROM Cobertura_de_Beneficiario__c
																WHERE Creado_en_Caso__c IN :caseIds];


		Map<Id, List<Cobertura_de_beneficiario__c>> coveragesByCase = new Map<Id, List<Cobertura_de_beneficiario__c>>();

		for (Case c : scope) {
			List<Cobertura_de_beneficiario__c> coverages = new List<Cobertura_de_Beneficiario__c>();

			for(Cobertura_de_Beneficiario__c coverage : recipientCoverages) {
				if(coverage.Creado_en_Caso__c==c.id) {
					coverages.add(coverage);
				}
			}
			coveragesByCase.put(c.Id, coverages);

		}
		
		Map<Id, Historial_de_Producto__c> historys = new Map<Id, Historial_de_Producto__c>();
		for (Case c : scope) {
			List<Cobertura_de_Beneficiario__c> coverages = coveragesByCase.get(c.id);
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
				history.Caso__c=c.Id; 
				historys.put(contractProduct, history);
			}
		}

        if(!historys.values().isEmpty()) {
			insert historys.values();
        }
		return historys;
	
    }

}
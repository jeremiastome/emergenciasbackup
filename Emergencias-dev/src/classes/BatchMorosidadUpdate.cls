global class BatchMorosidadUpdate implements Database.Batchable<SObject> {
	
	private Map<String, String> defaultByContractNumber;
	private Set<String> accountNumbers;
    private Map<String, id> OwnerIds;
    private Map<String, id> RecordTypeIds;	
	private Map<String, Case> contractCasesMap;
    Set<String> contractUniqueNumbers;
    Map<String, String> blockByContractNumber;
    
	global BatchMorosidadUpdate(Map<String, String> defaultByContractNumber, Set<String> accountNumbers, Map<String, String> blockByContractNumber) {
		this.defaultByContractNumber = defaultByContractNumber;
		this.accountNumbers = accountNumbers;
        this.blockByContractNumber = blockByContractNumber;
        
        List<RecordType> RecordTypes = [SELECT id, DeveloperName  FROM RecordType];
        this.RecordTypeIds = new Map<String, id> ();
        for (RecordType record : RecordTypes) { 
        	this.RecordTypeIds.put(record.DeveloperName , record.id);
        }
            
        List<Group> Groups = [SELECT id, DeveloperName  FROM Group];
        this.OwnerIds = new Map<String, id> ();
        for (Group grup : Groups) { 
        	this.OwnerIds.put(grup.DeveloperName , grup.id);
        }
        
        this.contractUniqueNumbers = defaultByContractNumber.keySet();

        List<Case> contractCases = [SELECT Id, Contrato__r.Numero_Unico_de_Contrato_Con_Sufijo__c, 
                                    Reason, Status, Contrato__c, Motivo_de_Finalizacion__c	
                                    FROM Case
                                    WHERE 
                                    RecordType.DeveloperName='Gestion_de_mora' AND
                                   	(Contrato__r.Numero_Unico_de_Contrato_Con_Sufijo__c IN :contractUniqueNumbers OR Contrato__r.Morosidad_SAP__c != null) AND
                                    Status!='Cerrado'];
        
        contractCasesMap = new Map<String, Case>();
        for(Case ca : contractCases)  {
            this.contractCasesMap.put(ca.Contrato__r.Numero_Unico_de_Contrato_Con_Sufijo__c, ca);
        }
        
	}
	
	/**
	 * @description gets invoked when the batch job starts
	 * @param context contains the job ID
	 * @returns the record set as a QueryLocator object that will be batched for execution
	 */
	global Database.QueryLocator start(Database.BatchableContext context) {
        
		return Database.getQueryLocator(
			'SELECT Id, Morosidad_SAP__c, N_mero_nico_de_Cliente__c,  ('
				+ 'SELECT Id, Numero_Unico_de_Contrato_Con_Sufijo__c, Morosidad_SAP__c, Estado__c '
				+ 'FROM Contratos__r '
				+ 'WHERE Morosidad_SAP__c != null '
					+ 'OR Numero_Unico_de_Contrato_Con_Sufijo__c IN :contractUniqueNumbers'
				+ ')'
			+ 'FROM Account '
			+ 'WHERE N_mero_nico_de_Cliente__c IN :accountNumbers '
				+ 'OR Morosidad_SAP__c != null'
		);
	}

	/**
	 * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
	 * @param context contains the job ID
	 * @param scope contains the batch of records to process.
	 */
   	global void execute(Database.BatchableContext context, List<Account> scope) {
        List<Case> contractCases = new List<Case>();
		List<Contrato__c> contracts = new List<Contrato__c>();

		for(Account acc : scope) {
			integer def = 0;
			acc.Saltear_envio__c = 2;
			for(Contrato__c con : acc.Contratos__r) {
				con.Saltear_envio__c = 2;//it will skip the sending once in the after trigger, but will be decremented twice in the before
				if(defaultByContractNumber.containsKey(con.Numero_Unico_de_Contrato_Con_Sufijo__c)) {
					con.Morosidad_SAP__c = defaultByContractNumber.get(con.Numero_Unico_de_Contrato_Con_Sufijo__c);
          
                    String Owner;
                    if(con.Morosidad_SAP__c=='30') {
                        Owner='Cobranzas';
                   	} else if (con.Morosidad_SAP__c=='60') {
                    	Owner='CAC_MAP';
                    } else if (con.Morosidad_SAP__c=='90') {
                      	Owner='CAC_Contencion';
                        
                        con.Estado__c='En gestion';
                        /// BLOCK
                        String block = defaultByContractNumber.get(con.Numero_Unico_de_Contrato_Con_Sufijo__c);
                    	con.Bloqueo_Factura__c= (!String.isBlank(block) ? block : null );
                        }
                    
                    
                    if( contractCasesMap.containsKey(con.Numero_Unico_de_Contrato_Con_Sufijo__c) ) {
                        Case caso = contractCasesMap.get(con.Numero_Unico_de_Contrato_Con_Sufijo__c);
                        if(caso.Reason!='Mora de '+con.Morosidad_SAP__c+' dias')  {
							caso.Reason='Mora de '+con.Morosidad_SAP__c+' dias';
                            contractCases.add(caso);
                        }
                        
                    } else {
                       contractCases.add (new Case(
                            AccountId= con.Cliente__c,
                            Contrato__c=con.id,
                            Origin='Interfaz SAP',
                            Reason='Mora de '+con.Morosidad_SAP__c+' dias',
                            Status='Nuevo',
                            RecordTypeId=this.RecordTypeIds.get('Gestion_de_Mora'),
                            OwnerId=this.OwnerIds.get(Owner)
                        ));
                        
                    }
                    
                    system.debug(con.Morosidad_SAP__c);              

					integer conDef = integer.valueOf(con.Morosidad_SAP__c);
					if(def < conDef) {
						def = conDef;
					}
                                        
				}
                
				else {
					con.Morosidad_SAP__c = null; 
                    
                    if (con.Estado__c=='En gestion') {
                    	con.Estado__c='Activo';
					}
                        
                    if( contractCasesMap.containsKey(con.Numero_Unico_de_Contrato_Con_Sufijo__c) ) {
                        Case caso = contractCasesMap.get(con.Numero_Unico_de_Contrato_Con_Sufijo__c);
                        if(caso.Motivo_de_Finalizacion__c!='Baja') {
                       		con.Bloqueo_Factura__c= null;
                        	caso.Motivo_de_Finalizacion__c='Procesado';
                            }
                        caso.Status='Cerrado';
                        if(!listContains(contractCases, caso)) {
                        	contractCases.add(caso);
						}
                        System.debug(caso);
                    }
                    
				}
				
				contracts.add(con);
			}
			if(def == 0) {
				acc.Morosidad_SAP__c = null;
                
                
			}
			else {
				acc.Morosidad_SAP__c = String.valueOf(def);
			}
		}
        
        system.debug(contracts);
		update contracts;
        system.debug(scope);
		update scope;
        
		upsert contractCases;
        
            
	}
	
	/**
	 * @description gets invoked when the batch job finishes. Place any clean up code in this method.
	 * @param context contains the job ID
	 */
	global void finish(Database.BatchableContext context) {
		
	}
    
    Boolean listContains(Object[] source, Object target) {
    	return (new Set<Object>(source)).contains(target);
	}
}
global class BatchRechazoDebitos implements Database.Batchable<WSRechazoDebitos.RechazoDebito>{
	private List<Contrato__c> contratos;
    private List<Account> clientes;
    private List<String> codClientes;
    private List<String> codContratos;
	private RecordType rt;
    private List<WSRechazoDebitos.RechazoDebito> rechazosTotales;
    private AssignmentRule AR;

   global BatchRechazoDebitos(List<String> codClientes, List<String> codContratos, List<WSRechazoDebitos.RechazoDebito> rechazosTotales){
        this.contratos = [SELECT Id, Numero_Unico_de_Contrato_Con_Sufijo__c FROM Contrato__c WHERE Numero_Unico_de_Contrato_Con_Sufijo__c IN :codContratos];
        this.clientes = [SELECT Id, CUIL_CUIT_SAP__c FROM Account WHERE CUIL_CUIT_SAP__c IN :codClientes]; 
        this.rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Rechazo_de_Debito_Automatico' LIMIT 1];
        this.codClientes = codClientes;
        this.codContratos = codContratos;
        this.rechazosTotales = rechazosTotales;
        this.AR = [SELECT ID FROM AssignmentRule WHERE SObjectType='Case' and Active = true limit 1];

   }

    global Iterable<WSRechazoDebitos.RechazoDebito> start(Database.BatchableContext BC){

		return rechazosTotales;
   }

    
   global void execute(Database.BatchableContext BC, List<WSRechazoDebitos.RechazoDebito> rechazos){
			
        List<Case> newCases = new List<Case>();
        List<Contrato__c> contratosAActualizar = new List<contrato__c>();
       
        Database.DMLOptions dmlOpt = new  Database.DMLOptions();
        dmlOpt.AssignmentRuleHeader.assignmentRuleId = AR.id;
            
        for(WSRechazoDebitos.RechazoDebito rec : rechazos){
			Contrato__c cont;
        	for(Contrato__c c : this.contratos){
       			if(c.Numero_Unico_de_Contrato_Con_Sufijo__c == rec.contrato){
                	cont = c;
                 	break;
                    }
                }
            
        	Account cli;
            for(Account c : clientes){
            	if(c.CUIL_CUIT_SAP__c == rec.cliente){
                	cli = c;
                	break;
                    }
                }
                
            if(cont != null && cli != null){
                 Case newCase = new Case();
                 newCase.RecordTypeId = rt.Id;
                 newCase.AccountId = cli.Id;
                 newCase.Contrato__c = cont.Id;
                 newCase.Codigo_de_Rechazo__c = rec.codigo_rechazo;
                 newCase.Codigo_de_Tarjeta__c = rec.codigo_tarjeta;
                 newCase.Descripcion_de_Rechazo__c = rec.descripcion_rechazo;
                 newCase.Descripcion_de_Tarjeta__c = rec.descripcion_tarjeta;
                 newCase.Origin='Interfaz SAP';
                 newCase.setOptions(dmlOpt);
                 newCases.add(newCase);
                }    
                
            if(cont!=null) {
                 cont.Forma_de_Pago__c='N';
                 contratosAActualizar.add(cont);
                 }
           }
       
        insert newCases;
        if(!contratosAActualizar.isEmpty()) {
       		update contratosAActualizar; 
        }
   }

   global void finish(Database.BatchableContext BC){
       
   }

}
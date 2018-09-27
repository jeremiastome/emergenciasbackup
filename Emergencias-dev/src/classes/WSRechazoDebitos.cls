global class WSRechazoDebitos {
    
    webService static Response cargarRechazosDebito(List<RechazoDebito> rechazos) {
        Response res = new Response();
        try {
 			List<Contrato__c> contratos = new List<Contrato__c>();
            List<Account> clientes = new List<Account>();
            List<String> codClientes = new List<String>();
            List<String> codContratos = new List<String>();
            
            for(RechazoDebito rec : rechazos){
                codClientes.add(rec.cliente);
                codContratos.add(rec.contrato);
            }
            
            BatchRechazoDebitos batchRechazos = new BatchRechazoDebitos(codClientes, codContratos, rechazos);
            ID batchprocessid = Database.executeBatch(batchRechazos, 1);
			System.debug('Returned batch process ID: ' + batchprocessid);

           // Busco todos los clientes y todos los contratos de los debitos rechazados
            /*
            /*            ESTO LO CONVERTIMOS EN UN BATCH PORQUE SE ROMPIA
             * 
             * 
             * 
            contratos = [SELECT Id, Numero_Unico_de_Contrato_Con_Sufijo__c FROM Contrato__c WHERE Numero_Unico_de_Contrato_Con_Sufijo__c IN :codContratos];
            clientes = [SELECT Id, CUIL_CUIT_SAP__c FROM Account WHERE CUIL_CUIT_SAP__c IN :codClientes];
            
            RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Rechazo_de_Debito_Automatico' LIMIT 1];
            List<Case> newCases = new List<Case>();
            
            AssignmentRule AR = new AssignmentRule();
            AR = [SELECT ID FROM AssignmentRule WHERE SObjectType='Case' and Active = true limit 1];
            
            Database.DMLOptions dmlOpt = new  Database.DMLOptions();
            dmlOpt.AssignmentRuleHeader.assignmentRuleId = AR.id;
            
            for(RechazoDebito rec : rechazos){
                Contrato__c cont;
                for(Contrato__c c : contratos){
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
                    newCase.Origin='Creacion automatica';
                    newCase.setOptions(dmlOpt);
                    newCases.add(newCase);
                	}    
                
                if(cont!=null) {
                    cont.Forma_de_Pago__c='K';
                    cont.Tipo_de_Cobrador__c='CobComun';
                    }
            	}

            insert newCases;
            update contratos;
            */
    
            res.statusMsg = 'Ok';
        } 
        catch (Exception e) {
            res.errorCode = e.getLineNumber();            
            res.statusMsg = e.getMessage();
        }        
        return res;
    }
    
    
    global class Response {
        webService Integer errorCode {get;set;}
        webService String statusMsg {get;set;}
    }
    
    global class RechazoDebito {
        webService String cliente {get;set;}
        webService String contrato {get;set;}
        webService String codigo_tarjeta {get;set;}
        webService String descripcion_tarjeta {get;set;}
        webService String codigo_rechazo {get;set;}
        webService String descripcion_rechazo {get;set;}
    }
}
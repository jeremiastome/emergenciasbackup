public class EverythingSenderQueueable implements Queueable, Database.AllowsCallouts {
    Id accountId;
    Id contractId;
    String operationType; //DEPRECATED NOT IN USE!!!
    
    public EverythingSenderQueueable(Id aId, Id cId, String ot){
        accountId = aId;
        contractId = cId;
        operationType = ot;
    }
    
    public void execute(QueueableContext context) {
        Account client = [SELECT Estado__c, Sociedad__c, Organizacion_de_Ventas__c, Saltear_envio__c FROM Account WHERE Id = :accountId];
        System.debug('[14] Cliente '+client);
        if(client.Estado__c != 'Activo'){
        	WSAccountToSAP.sendAccountToSAP(accountId, 'A');
            System.debug('Cuenta enviada como alta');
        }
		else{
			Contrato__c cont = [SELECT Id, Sociedad__c, Organizacion_de_Ventas__c FROM Contrato__c WHERE Id = :contractId];
			if(cont.Sociedad__c != client.Sociedad__c || cont.Organizacion_de_Ventas__c != client.Organizacion_de_Ventas__c){
				client.Sociedad__c = cont.Sociedad__c;
				client.Organizacion_de_Ventas__c = cont.Organizacion_de_Ventas__c;
				// Seteo el saltear envio en 2 porque no quiero que lo envie el trigger porque lo envia de forma asincrona
				// quiero enviarlo a mano para poder controlar el orden con respecto al contrato
				client.Saltear_envio__c = 2;
				update client;
				WSAccountToSAP.sendAccountToSAP(accountId, 'M');
                System.debug('Cuenta enviada como modificacion');
			}
		}
        
        client = [SELECT Id, Estado__c, Status_Envio__c FROM Account WHERE Id = :accountId];
        System.debug('Cliente:   ' + client);
        
        
        if(client.Status_Envio__c != '-1'){
            System.debug('Status_envio__C != -1');
            
            ContractSenderQueable csq = new ContractSenderQueable(contractId, operationtype);
            System.debug('Puesto en cola de envio, contractId: '+contractId);
            System.enqueueJob(csq);
            
        }
    }
}
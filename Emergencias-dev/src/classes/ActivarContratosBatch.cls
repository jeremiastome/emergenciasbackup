global class ActivarContratosBatch implements Database.Batchable<SObject>,  Database.AllowsCallouts{

    public String query;

    global ActivarContratosBatch() {

    }

    global Database.QueryLocator start(Database.BatchableContext context) {

        return Database.getQueryLocator(
            'SELECT Id, Contrato__c, Contrato_clonado__c '
            + 'FROM Case '
            + 'WHERE Fecha_de_impacto__c = YESTERDAY '
                + 'AND Status = \'Cerrado\' '
                + 'AND (' + generateWhereClause() + ')'
        );
    }

    private String generateWhereClause() {
        List<Casos_activan_contrato_a_futuro__c> settings = Casos_activan_contrato_a_futuro__c.getAll().values();
		System.debug('settings: ' + settings);
        String result = '';
        for(Casos_activan_contrato_a_futuro__c s : settings) {
            result += '(RecordType.DeveloperName = \'' + s.Tipo_de_caso__c + '\' AND (';

            for(String reason : s.Valores_de_activacion__c.split(';')) {
                result += 'Motivo_de_Finalizacion__c = \'' + reason + '\' OR ';
            }
            result = result.left(result.length() - 4);//remove trailing ' OR '
            result += ')) OR ';
        }
        result = result.left(result.length() - 4);//remove trailing ' OR '
		System.debug('query: ' + result);
        return result;
    }
	// ADVERTENCIA:
	// Esta clase se tiene que redefinir a futuro, la clase se la tuvo que poner
	// parches un poco anti standard a lo que deberia ser pero se hizo por temas de tiempo
	// y porque esta clase cuando se creo se penso que podia trabajar con mas de un caso a la vez
	// En este momento por lote esta clase solo trabaja de a un solo contrato

    global void execute(Database.BatchableContext context, List<Case> scope) {
        Case c = scope[0];
        System.debug('caso en batch: ' + c);
        Contrato__c clonContract = [
            SELECT Id,
            	(SELECT Id, Estado__c
                 FROM Beneficiarios__r)
            FROM Contrato__c
            WHERE Id = :c.Contrato_clonado__c
        ];

        ContratosPedidos_EnviarSAP.sendContract(c.Contrato__c, 'B');

        Contrato__c contract = [
            SELECT Id, Estado_de_Envio_a_SAP__c,
            	(SELECT Id, Estado__c
                 FROM Beneficiarios__r)
            FROM Contrato__c
            WHERE Id = :c.Contrato__c
        ];

        if(contract.Estado_de_Envio_a_SAP__c=='Ok')  {
			System.debug('Se dio de baja el contrato');
            List<Contrato__c> contractToUpdate = new List<Contrato__c>();
            List<beneficiario__c> recipients = new List<Beneficiario__c>();

        	contract.Estado__c= 'Baja';
            for (Beneficiario__c recipient : contract.Beneficiarios__r) {
                recipient.Estado__c = 'Baja';
                recipients.add(recipient);
            }

            clonContract.Estado__c='Activo';
            for (Beneficiario__c recipient : contract.Beneficiarios__r) {
                if (recipient.Estado__c=='En Proceso de Venta') {
                	recipient.Estado__c = 'Activo';
                	recipients.add(recipient);
                }
            }
            contractToUpdate.add(contract);
            contractToUpdate.add(clonContract);
            update contractToUpdate;

            ContractSenderQueable sender = new ContractSenderQueable(c.Contrato_clonado__c, 'A');
            Id job = System.enqueueJob(sender);
        }
        else {
			System.debug('Se obtuvo una respuesta de SAP: '+contract.Estado_de_Envio_a_SAP__c);
        	c.Status = 'Abierto';
            c.Motivo_de_Finalizacion__c=null;
            update c;
       	}
    }

    global void finish(Database.BatchableContext context) {

    }
}
global class BajaContratosBatch implements Database.Batchable<sObject>, Database.Stateful {
    private String csvStr;
    private integer casosEncontrados;
    private integer casosProcesados;
    public string fecha {get;set;}

    public BajaContratosBatch() {

    }
    public BajaContratosBatch(String fecha) {
        this.fecha = fecha;
    }

    /// NO USAR ESTE BATCH PARA MAS DE CASO SI NO GENERARA ERRORES POR ENCOLADOS //
    //  ESTA DISEÑADO SOLO PARA TRABAJR DE UN CASO POR LOTE //
	//  UN BATCH SOLO SOPORTA UNA CALLOUT POR LOTE //
	global Database.QueryLocator start(Database.BatchableContext bc) {
     	Usuario_no_envia_a_SAP__C user = Usuario_no_envia_a_SAP__C.getValues(UserInfo.getUserName());
        if (!user.No_envia__c) {
            user.No_envia__c=true;
            update user;
        }
		String fecha = ( this.fecha==null ? 'YESTERDAY' : this.fecha );

    	csvStr = 'Identificador  ; Tipo de baja  \n';
        casosEncontrados=0;
        casosProcesados=0;

        String query = 'SELECT Id, Contrato__c, Contrato__r.Estado__c, Fecha_Impacto_de_Baja__c, '+
            			'Motivo_de_Baja__c,Detalle_motivo_de_baja__c, AccountId  '+
            			'FROM Case WHERE Contrato__c != null AND Fecha_Impacto_de_Baja__c = '+fecha+' ' +
            		   'AND (RecordType.DeveloperName = \'Pedido_de_Baja\' OR RecordType.DeveloperName = \'Gestion_de_Mora\') '+
            		   'AND Dar_de_baja__c = TRUE';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<Case> scope){
        Map<Id, Contrato__c> conts = new Map<Id, Contrato__c>();
        Map<Id, Beneficiario__c> benefs = new Map<Id, Beneficiario__c>();
		Map<Id, Titular__c> titulares = new Map<Id, Titular__c>();
        casosEncontrados+=scope.size();

        for(Case c : scope){
            String tipoDeEnvio;
            csvStr+=c.Id+';';
            List<Baja_Parcial__c> bajas = [SELECT Id, Titular__c, Beneficiario__c
											FROM Baja_Parcial__c WHERE Caso__c = :c.Id];
            if(bajas.size() == 0){
                csvStr+='Total \n';
                Contrato__c cont = new Contrato__c();
                cont.Id = c.Contrato__c;
				cont.Estado__c = 'Baja';
				cont.Fecha_Baja__c = c.Fecha_impacto_de_baja__c;
				cont.Motivo_de_Baja__c = c.Motivo_de_Baja__c;
				cont.Detalle_de_Motivo_de_Baja__c = c.Detalle_motivo_de_baja__c;
                try {
                    update cont;
					casosProcesados+=1;
                    tipoDeEnvio='B';
        		}catch (exception ex) {
        			csvStr+=c.id+';Error \n';
            	}
            }
            else {
                csvStr+='Parcial \n';
                Set<Id> titularesIds = new Set<Id>();
                for(Baja_Parcial__c baja : bajas){
                    if(baja.Titular__c != null){
                        titularesIds.add(baja.Titular__c);
                    }
                    if(baja.Beneficiario__c != null){
                        Beneficiario__c ben = new Beneficiario__c();
                        ben.Id = baja.Beneficiario__c;
                        ben.Estado__c = 'Baja';
						ben.Fecha_de_Baja__c = c.Fecha_impacto_de_baja__c;
						ben.Detalle_motivo_de_baja__c = c.Detalle_motivo_de_baja__c;
						ben.Motivo_de_Baja__c = c.Motivo_de_Baja__c;
                        benefs.put(ben.Id, ben);
                    }
                }

                If(titularesIds.size()!=0) {

					List<Titular__c> listTitulares = [SELECT Id, Estado__c, Fecha_de_Baja__c, Detalle_motivo_de_baja__c, Motivo_de_Baja__c,
                                                     (SELECT Id, Estado__c, Fecha_de_Baja__c,
                                                      Detalle_motivo_de_baja__c, Motivo_de_Baja__c
                                                      FROM Beneficiarios__r)
                                                      FROM Titular__c
													  WHERE Id IN :titularesIds
                                                      AND Contrato__c = :c.Contrato__c ];

					for(Titular__c titular : listTitulares) {

						titular.Estado__c = 'Baja';
						titular.Fecha_de_Baja__c = c.Fecha_impacto_de_baja__c;
						titular.Motivo_de_Baja__c = c.Motivo_de_Baja__c;
						titular.Detalle_motivo_de_baja__c = c.Detalle_motivo_de_baja__c;
						titulares.put(titular.Id, titular);

                        for(Beneficiario__c ben : titular.beneficiarios__r){
                            ben.Estado__c = 'Baja';
                            ben.Fecha_de_Baja__c = c.Fecha_impacto_de_baja__c;
                            ben.Detalle_motivo_de_baja__c = c.Detalle_motivo_de_baja__c;
                            ben.Motivo_de_Baja__c = c.Motivo_de_Baja__c;
                            benefs.put(ben.Id, ben);
                        }
					}
				}

                try {
                	update benefs.values();
					update titulares.values();
                    casosProcesados+=1;
                    tipoDeEnvio='M';
                }catch (exception ex) {
                    csvStr+=c.id+';Error \n';
                }
			}

            Account acc = [SELECT Id, (SELECT Id, Estado__c FROM Contratos__r)
                           FROM Account
                           WHERE id=:c.AccountId];

            boolean contratoActivo=false;
            for(Contrato__c con : acc.Contratos__r) {
                if (con.Estado__c=='Activo') {
                    contratoActivo=true;
                    break;
                }
            }
            if (!contratoActivo) {
				WSAccountToSAP.sendAccountToSAP(acc.id, 'B');
            }
            ContratoTriggerHelper.sendContractToSAP(c.Contrato__c, tipoDeEnvio);
        }
    }

	global void finish(Database.BatchableContext BC){

        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
        mail.setToAddresses(new String[] {'salesforce.alerts@xappia.com'});
        mail.setReplyTo('noRespondas@noRespondas.com');
        mail.setSenderDisplayName('Emergencias ');
        mail.setSubject('Bajas de contratos: ' + Date.today());
        mail.setBccSender(false);
        mail.setUseSignature(false);

        mail.setPlainTextBody('Terminado el proceso de BajaContratosBatch del dia '+Date.today() + '. \n'+
                              'Encontradas: '+casosEncontrados+'. \n' +
                              'Procesadas: '+casosProcesados+'. \n\n'+
                              'Id del proceso: '+BC.getJobId()+'.\n'+
                              'Id del documento: '+saveCSV(csvStr)+'.');
        if(!test.isRunningTest()) {
        	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
	}

	private id saveCSV(String csvStr) {
		ContentVersion cv = new ContentVersion(
			Title = 'BajaContratosBatch-' + System.now().format('YYYY-MM-dd-HH-mm-ss') + '.csv',
			VersionData = blob.valueOf(csvStr),
			PathOnClient = '/noPath/'
		);

		insert cv;
        return cv.id;
	}
}
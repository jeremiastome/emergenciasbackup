@IsTest public class CrearHistorialBatchTest {
    //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////
    private static testMethod void ifAnOpportunityIsWon_TheHistoryIsCreated() {
        
        Test.startTest();
        aOpportunity.StageName='Ganada';
        update aOpportunity;
        
        CrearHistorialDeOportunidadesBatch batch = new CrearHistorialDeOportunidadesBatch('=TODAY');
        Database.executeBatch(batch);
        Test.stopTest();
        
        
        List<Historial_de_producto__c> historys = [SELECT Id,
                                                   Producto_de_Contrato__c,
                                                   Cantidad_de_bonificados__c,
                                                   cantidad_de_beneficiarios__c,
                                                   (SELECT Id FROM Descuentos_Recargos_aplicados__r)
                                                   FROM Historial_de_producto__c
                                                   WHERE Oportunidad__c=:aOpportunity.id];
        
        System.assertEquals(3, historys.size());
        for (Historial_de_producto__c history : historys) {
            System.assertEquals(1, history.Descuentos_recargos_aplicados__r.size());
            System.assertNotEquals(null, history.Producto_de_Contrato__c);
            System.assertEquals(9, history.Cantidad_de_bonificados__c);
            System.assertEquals(9, history.cantidad_de_beneficiarios__c);
        }
        
	}
   
    //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////
    /* TODAVIA NO SE USA ESTA FUNCIONALIDAD
    private static testMethod void IfADischargedRecipientCaseIsClosedAndProcessed_TheHistoryIsCreated() {
        aCase.RecordTypeId=recordtypes.get('Alta_de_Beneficiario');
        aCase.Status='Cerrado';
        aCase.Motivo_de_finalizacion__c='Procesado';
        
		update aCase;

        Test.startTest();
		CrearHistorialDeCasosBatch batch = new CrearHistorialDeCasosBatch('=TODAY', 'Alta_de_Beneficiario');
		Database.executeBatch(batch);
        Test.stopTest();
        
        
        List<Historial_de_producto__c> historys = [SELECT Id,
                                                   Producto_de_Contrato__c,
                                                   Cantidad_de_bonificados__c,
                                                   cantidad_de_beneficiarios__c,
                                                   (SELECT Id FROM Descuentos_Recargos_aplicados__r)
                                                   FROM Historial_de_producto__c
                                                   WHERE Caso__c=:aCase.id];
        
        System.assertEquals(3, historys.size());
        for (Historial_de_producto__c history : historys) {
            System.assertEquals(1, history.Descuentos_recargos_aplicados__r.size());
            System.assertNotEquals(null, history.Producto_de_Contrato__c);
            System.assertEquals(9, history.Cantidad_de_bonificados__c);
            System.assertEquals(9, history.cantidad_de_beneficiarios__c);
        }
        
    }*/
   
    //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////
    private static testMethod void IfAPartialRemoveOrderRecipientCaseIsClosedWithARecipientToBeRemove_TheHistoryIsCreatedWithHisPartialLosses()  {
        aCase.RecordTypeId=recordtypes.get('Pedido_de_Baja');
        aCase.Status='Cerrado';
        aCase.Motivo_de_Baja__c='Comercial';
        aCase.Motivo_de_finalizacion__c='Baja';
        
		update aCase;
        
        Baja_parcial__c partialRemove = new Baja_parcial__c();
        partialRemove.Beneficiario__c =recipients[0].id;
        partialRemove.Caso__c = aCase.id;
        insert partialRemove;
        

        Test.startTest();
		CrearHistorialDeCasosBatch batch = new CrearHistorialDeCasosBatch('=TODAY', 'Pedido_de_baja');
		Database.executeBatch(batch);
        Test.stopTest();
        
        
        List<Historial_de_producto__c> historys = [SELECT Id,
                                                   Producto_de_Contrato__c,
                                                   Cantidad_de_bajas__c,
                                                   (SELECT Id FROM Descuentos_Recargos_aplicados__r)
                                                   FROM Historial_de_producto__c
                                                   WHERE Caso__c=:aCase.id];
        
        System.assertEquals(3, historys.size());
        for (Historial_de_producto__c history : historys) {
            System.assertEquals(1, history.Descuentos_recargos_aplicados__r.size());
            System.assertNotEquals(null, history.Producto_de_Contrato__c);
            System.assertEquals(1, history.Cantidad_de_bajas__c);
        }
        
    }
    
   
    //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////
    private static testMethod void IfAPartialRemoveOrderRecipientCaseIsClosedWithAHolderToBeRemove_TheHistoryIsCreatedWithHisPartialLosses()  {
        aCase.RecordTypeId=recordtypes.get('Pedido_de_Baja');
        aCase.Status='Cerrado';
        aCase.Motivo_de_Baja__c='Comercial';
        aCase.Motivo_de_finalizacion__c='Baja';
        
		update aCase;
        
        Baja_parcial__c partialRemove = new Baja_parcial__c();
        partialRemove.Titular__c =aHolder.id;
        partialRemove.Caso__c = aCase.id;
        insert partialRemove;
        

        Test.startTest();
		CrearHistorialDeCasosBatch batch = new CrearHistorialDeCasosBatch('=TODAY', 'Pedido_de_baja');
		Database.executeBatch(batch);
        Test.stopTest();
        
        
        List<Historial_de_producto__c> historys = [SELECT Id,
                                                   Producto_de_Contrato__c,
                                                   Cantidad_de_bajas__c,
                                                   (SELECT Id FROM Descuentos_Recargos_aplicados__r)
                                                   FROM Historial_de_producto__c
                                                   WHERE Caso__c=:aCase.id];
        
        System.assertEquals(3, historys.size());
        for (Historial_de_producto__c history : historys) {
            System.assertEquals(1, history.Descuentos_recargos_aplicados__r.size());
            System.assertNotEquals(null, history.Producto_de_Contrato__c);
            System.assertEquals(9, history.Cantidad_de_bajas__c);
        }
        
    }
    
    //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////
    private static testMethod void IfARemoveOrderRecipientCaseIsClosed_TheHistoryIsCreated() {
        aCase.RecordTypeId=recordtypes.get('Pedido_de_Baja');
        aCase.Status='Cerrado';
        aCase.Motivo_de_Baja__c='Comercial';
        aCase.Motivo_de_finalizacion__c='Baja';
        
		update aCase;

        Test.startTest();
		CrearHistorialDeCasosBatch batch = new CrearHistorialDeCasosBatch('=TODAY', 'Pedido_de_baja');
		Database.executeBatch(batch);
        Test.stopTest();
        
        
        List<Historial_de_producto__c> historys = [SELECT Id,
                                                   Producto_de_Contrato__c,
                                                   Cantidad_de_bajas__c,
                                                   (SELECT Id FROM Descuentos_Recargos_aplicados__r)
                                                   FROM Historial_de_producto__c
                                                   WHERE Caso__c=:aCase.id];
        
        System.assertEquals(3, historys.size());
        for (Historial_de_producto__c history : historys) {
            System.assertEquals(1, history.Descuentos_recargos_aplicados__r.size());
            System.assertNotEquals(null, history.Producto_de_Contrato__c);
            System.assertEquals(9, history.Cantidad_de_bajas__c);
        }
    }
    //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////
    
    private static testMethod void ifAnOpportunityIsLoose_TheHistoryIsntCreated() {
        aOpportunity.StageName='Perdida';
        aOpportunity.Motivo_de_p_rdida__c='Servicio';

        update aOpportunity;

        Test.startTest();
		CrearHistorialDeOportunidadesBatch batch = new CrearHistorialDeOportunidadesBatch('=TODAY');
		Database.executeBatch(batch);
        Test.stopTest();

        
        List<Historial_de_producto__c> historys = [SELECT Id,
                                                   (SELECT Id FROM Descuentos_Recargos_aplicados__r)
                                                   FROM Historial_de_producto__c
                                                   WHERE Oportunidad__c=:aOpportunity.id];
        
        System.assertEquals(0, historys.size());        
    }
    
	
    private static testMethod void canScheduleTheCreationOfOpportunityHistorys() {
		String CRON_EXP = '0 0 0 3 9 ? 2022';

		Test.startTest();
		
		String jobId = System.schedule('OpportunityScheduler', CRON_EXP, 
		new CrearHistorialDeOportunidadesScheduler());

		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
							NextFireTime
							FROM CronTrigger WHERE id = :jobId];

		System.assertEquals(CRON_EXP, ct.CronExpression);
		System.assertEquals(0, ct.TimesTriggered);

		System.assertEquals('2022-09-03 00:00:00', String.valueOf(ct.NextFireTime));

		Test.stopTest();
	}
    //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////

    private static testMethod void canScheduleTheCreationOfCasesHistorys() {
		String CRON_EXP = '0 0 0 3 9 ? 2022';

		Test.startTest();
		
		String jobId = System.schedule('CaseScheduler', CRON_EXP, 
		new CrearHistorialDeCasosScheduler());

		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
							NextFireTime
							FROM CronTrigger WHERE id = :jobId];

		System.assertEquals(CRON_EXP, ct.CronExpression);
		System.assertEquals(0, ct.TimesTriggered);

		System.assertEquals('2022-09-03 00:00:00', String.valueOf(ct.NextFireTime));

		Test.stopTest();
	}	
    
	//==========================================================================
    static Opportunity aOpportunity;
    static Case aCase;
    static Account aAccount;
    static Titular__c aHolder;
    static List<Cobertura__c> coverages;
    static List<Beneficiario__c> recipients;
    static List<Cobertura_de_Beneficiario__c> recipientCoverages;
    static List<Descuento_Recargo__c> discounts;
    static List<Descuento_Recargo_Aplicado__c> apliedDiscounts;
    static List<Aplicante__c> applicants;
    static Map<String, Id> recordtypes;
    
    static {
        
        RecordType consumidorFinal = [SELECT ID
                                      FROM RecordType
                                      WHERE DeveloperName='Venta_consumidor_final'
                                      LIMIT 1];
        
        
        List<RecordType> recordTypeCases = [SELECT ID, DeveloperName
                                     	FROM RecordType
                                      	WHERE DeveloperName='Pedido_de_baja' 
                                        OR DeveloperName='Bonificacion'
                                        OR DeveloperName='Cambio_de_cobertura'
                                        OR DeveloperName='Alta_administrativa'
                                        OR DeveloperName='Alta_de_beneficiario'
                                           ];
        
        recordtypes = new Map<String, id>();
        for (RecordType record : recordTypeCases) {
            recordtypes.put(record.DeveloperName, record.id);
        }

        
        aAccount = build.anAccount().build();
        aAccount.Comprobar_cierre_primera_oportunidad__c=true;
        insert aAccount;
        
        aOpportunity = build.anOpportunity()
            			.withRecordTypeId(consumidorFinal.id)
            			.forAccount(aAccount)
            			.withDischargeType('Nueva')
            			.build();
        
        insert aOpportunity;
        
        
        aOpportunity = [SELECT Id, Contrato__c
                        FROM Opportunity
                        WHERE Id=:aOpportunity.id];
        
        
        Contrato__c aContract = new Contrato__c();
        aContract.id = aOpportunity.Contrato__c;
        aContract.Numero_Unico_de_Contrato_Con_Sufijo__c='D12345600';
        update aContract;
        
        
        aCase = build.aCase()
            		.forContract(aContract)
            		.forAccount(aAccount)
            		.build();
        
        insert aCase;
        
        List<Product2> products = new List<Product2>();
        for (integer i=0; i<3; i++) {
            Product2 product = build.aProduct().withName('Test '+i).build();
            product.isActive=true;
            products.add( product );
        }
        insert products;
        
        coverages = new List<Cobertura__c>();
        for (integer i=0; i<3; i++) {
			Cobertura__c coverage = build.aCoverage().withName('Coverage '+i)
									.createdInOpp(aOpportunity).createdInCase(aCase)
                					.forProduct(products[i]).forContract(aContract).build();
            coverages.add( coverage );
        }
        insert coverages;
        System.debug(coverages);
        
        aHolder = [//Created by a process
			SELECT Id, Numero_de_Titular__c, Ult_Numero_de_beneficiario__c
			FROM Titular__c
			WHERE Contrato__c = :aContract.Id
		];

        recipients = new List<Beneficiario__c>();
        for (integer i=0; i<9; i++) {
        	Beneficiario__c recipient = build.aRecipient()
                							.forContract(aContract)
                							.forHolder(aHolder)
                							.build();
            recipients.add(recipient);
        }
        insert recipients;
        
        
        recipientCoverages = new List<Cobertura_de_Beneficiario__c>();

        for (integer i=0; i<9; i++) {
            
            recipientCoverages.add( build.aCoverageRecipientRelation()
                					.forRecipient(recipients[i])
                					.forCoverage(coverages[0])
                                    .createdInOpp(aOpportunity)
                                    .CreatedInCase(aCase)
                                    .build() );
            
            recipientCoverages.add( build.aCoverageRecipientRelation()
                					.forRecipient(recipients[i])
                					.forCoverage(coverages[1])
                                    .createdInOpp(aOpportunity)
                                    .CreatedInCase(aCase)
                                    .build() );
            
            recipientCoverages.add( build.aCoverageRecipientRelation()
                					.forRecipient(recipients[i])
                					.forCoverage(coverages[2])
                                    .createdInOpp(aOpportunity)
                                    .CreatedInCase(aCase)
                                    .build() );
            
            
        }
        insert recipientCoverages;
        
        discounts = new List<Descuento_recargo__c>();
        for (integer i=0; i<3;i++) {
            Descuento_Recargo__c discount = build.aDiscount().build();
            discounts.add(discount);
        }
        insert discounts;
        
        apliedDiscounts = new List<Descuento_recargo_aplicado__c>();
        for (integer i=0; i<3; i++) {
            apliedDiscounts.add ( 
            	build.anAppliedDiscount()
                	.forCoverage(coverages[i])
                	.forDiscount(discounts[i])
                	.build()
            );
        }
        insert apliedDiscounts;
        
        applicants = new List<Aplicante__c>();
        
        
        
        for (Cobertura_de_beneficiario__c coverage : recipientCoverages) {
            applicants.add(
                build.anApplicant()
                	.forAppliedDiscount(apliedDiscounts[0])
                	.forRecipientCoverage(coverage)
                	.build()
            );
        }
        
        insert applicants;
        
        Usuario_no_envia_a_SAP__c user = new Usuario_no_envia_a_SAP__c();
        user.Name=userInfo.getUserName();
        user.No_envia__c=true;
        insert user;
        
    }

}
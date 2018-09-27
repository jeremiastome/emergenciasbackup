@isTest
public class BajaContratosTest {
    static testMethod void losCasosDeBajaCerradosConFechaDeBajaDeAyerDanDeBajaElContratoAsociado(){
        String cuit = '20123456780';
        Account client = Build.anAccount().withCUILCUIT(cuit).build();
        insert client;
        
        String contractNumber = '112233';
        Contrato__c contract = Build.aContract().withUniqueNumberWithSufix(contractNumber).forAccount(client).build();
        contract.Estado__c='Activo';
        insert contract;
        
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Pedido_de_Baja' LIMIT 1];
        Case theCase = Build.aCase().forContract(contract).withRecordType(rt).withReason('Pedido de Baja')
            			    .WithCloseReason('Baja').isClosed().build();
        theCase.Fecha_Impacto_de_baja__c = Date.today().addDays(-1);
        theCase.Dar_de_baja__c = true;
        theCase.Motivo_de_Baja__c ='Economico';
		theCase.Detalle_motivo_de_baja__c = 'Incobrable';
        theCase.Submotivo__c = 'Economicos';
        System.debug(theCase.Fecha_Impacto_de_baja__c);
        theCase.AccountId = client.Id;
        
        system.debug(theCase.Reason);
        system.debug(theCase.AccountId);
        system.debug(theCase.Contrato__c);
        system.debug(theCase.Submotivo__c);
        
        insert theCase;
        
                
        theCase = [SELECT ID, Dar_de_baja__c,
					Detalle_motivo_de_baja__c,
					Motivo_de_Baja__c
                    FROM Case
                    WHERE Id=:theCase.id];
        
        System.debug(theCase);
        
        system.assertNotEquals('Baja', contract.Estado__c);
        
        Test.startTest();
        BajaContratosScheduler scheduler = new BajaContratosScheduler();
        scheduler.execute(null);
        Test.stopTest();
        
        contract = [SELECT Estado__c, Motivo_de_Baja__c, Detalle_de_Motivo_de_Baja__c FROM Contrato__c WHERE Id = :contract.Id];
        
        system.assertEquals('Baja', contract.Estado__c);
		System.assertEquals(theCase.Motivo_de_Baja__c,contract.Motivo_de_Baja__c);
		System.assertEquals(theCase.Detalle_motivo_de_baja__c, contract.Detalle_de_Motivo_de_Baja__c);
    }

    static testMethod void losCasosDeGestionDeMoraCerradosConFechaDeBajaDeAyerDanDeBajaElContratoAsociado(){
        String cuit = '20123456780';
        Account client = Build.anAccount().withCUILCUIT(cuit).build();
        insert client;
        
        String contractNumber = '112233';
        Contrato__c contract = Build.aContract().withUniqueNumberWithSufix(contractNumber).forAccount(client).build();
        contract.Estado__c='Activo';
        insert contract;
        
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Gestion_de_mora' LIMIT 1];
        Case theCase = Build.aCase().forContract(contract).withRecordType(rt).withReason('Pedido de Baja')
            			    .WithCloseReason('Baja').isClosed().build();
        theCase.Fecha_Impacto_de_baja__c = Date.today().addDays(-1);
        theCase.Motivo_de_Finalizacion__c = 'Procesado';
        theCase.Dar_de_baja__c=true;
        insert theCase;
        
        theCase = [SELECT ID, Dar_de_baja__c 
                    FROM Case
                    WHERE Id=:theCase.id];
        
        System.debug(theCase);
        system.assertNotEquals('Baja', contract.Estado__c);
        
        Test.startTest();
        BajaContratosScheduler scheduler = new BajaContratosScheduler();
        scheduler.execute(null);
        Test.stopTest();
        
        contract = [SELECT Estado__c FROM Contrato__c WHERE Id = :contract.Id];
        
        system.assertEquals('Baja', contract.Estado__c);
    }

	public static testmethod void siHayBajasParcialesSeDebeDarDeBajaSoloLosBeneficiariosYNoElContrato(){
		
		Account client = Build.anAccount().isPersonAccount().build();
		insert client;
        
        String contractNumber = '112233';
        Contrato__c contract = Build.aContract().withUniqueNumberWithSufix(contractNumber).forAccount(client).build();
        contract.Estado__c='Activo';
        insert contract;

		Titular__c holder = Build.aHolder().forAccount(client).forContract(contract).build();
		insert holder;

		Beneficiario__c recipient = Build.aRecipient().forAccount(client).forContract(contract).forHolder(holder).build();
		insert recipient;

		RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Pedido_de_Baja' LIMIT 1];
        Case theCase = Build.aCase().forContract(contract).withRecordType(rt).withReason('Pedido de Baja').build();
        theCase.Fecha_Impacto_de_baja__c = Date.today().addDays(-1);
        theCase.Dar_de_baja__c=true;
        insert theCase;

		Baja_Parcial__c partialUnsubscription = new Baja_Parcial__c(Caso__c = theCase.id, Beneficiario__c = recipient.id);
		insert partialUnsubscription;

		Case updateCase = theCase.clone(TRUE);
		
		updateCase.Motivo_de_Finalizacion__c='Baja';
		updateCase.Motivo_de_Baja__c ='Economico';
		updateCase.Detalle_motivo_de_baja__c = 'Incobrable';
		updateCase.Status='Cerrado';
		update updateCase;
		
		Test.startTest();
        BajaContratosScheduler scheduler = new BajaContratosScheduler();
        scheduler.execute(null);
        Test.stopTest();
		 
		contract = [SELECT Estado__c FROM Contrato__c WHERE Id = :contract.Id];
        recipient = [SELECT Estado__c, Motivo_de_baja__c, Detalle_Motivo_de_Baja__c FROM Beneficiario__C WHERE Id = :recipient.Id];


        system.assertEquals('Activo', contract.Estado__c);
		system.assertEquals('Baja', recipient.Estado__c);
		System.assertEquals(updateCase.Motivo_de_Baja__c, recipient.Motivo_de_Baja__c);
		System.assertEquals(updateCase.Detalle_motivo_de_baja__c, recipient.Detalle_Motivo_de_Baja__c);
	}

	public static testmethod void siSeDaBajaParcialDeUnTitularElContratoNoSeDebeDarDeBajaPeroSusBeneficiarioSi(){
		Account client = Build.anAccount().isPersonAccount().build();
		insert client;
        
        String contractNumber = '112233';
        Contrato__c contract = Build.aContract().withUniqueNumberWithSufix(contractNumber).forAccount(client).build();
        contract.Estado__c='Activo';
        insert contract;

		Titular__c holder = Build.aHolder().forAccount(client).forContract(contract).build();
		insert holder;

		Beneficiario__c recipient = Build.aRecipient().forAccount(client).forContract(contract).forHolder(holder).build();
		insert recipient;

		RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Pedido_de_Baja' LIMIT 1];
        Case theCase = Build.aCase().forContract(contract).withRecordType(rt).withReason('Pedido de Baja').build();
        theCase.Fecha_Impacto_de_baja__c = Date.today().addDays(-1);
        theCase.Dar_de_baja__c=true;
        insert theCase;

		Baja_Parcial__c partialUnsubscription = new Baja_Parcial__c(Caso__c = theCase.id, Titular__c = holder.id);
		insert partialUnsubscription;

		Case updateCase = theCase.clone(TRUE);
		
		updateCase.Motivo_de_Finalizacion__c='Baja';
		updateCase.Motivo_de_Baja__c ='Economico';
		updateCase.Detalle_motivo_de_baja__c = 'Incobrable';
		updateCase.Status='Cerrado';
		update updateCase;
		
		Test.startTest();
        BajaContratosScheduler scheduler = new BajaContratosScheduler();
        scheduler.execute(null);
        Test.stopTest();
		 
		contract = [SELECT Estado__c FROM Contrato__c WHERE Id = :contract.Id];
        recipient = [SELECT Estado__c, Motivo_de_Baja__c, Detalle_Motivo_de_Baja__c FROM Beneficiario__C WHERE Id = :recipient.Id];
		holder = [SELECT Estado__c , Motivo_de_Baja__c, Detalle_Motivo_de_Baja__c FROM Titular__c WHERE Id = :holder.Id];

        system.assertEquals('Activo', contract.Estado__c);
		system.assertEquals('Baja', recipient.Estado__c);
		System.assertEquals('Baja', holder.Estado__c);
		System.assertEquals(updateCase.Motivo_de_Baja__c, recipient.Motivo_de_Baja__c);
		System.assertEquals(updateCase.Motivo_de_Baja__c, holder.Motivo_de_Baja__c);
		System.assertEquals(updateCase.Detalle_motivo_de_baja__c,recipient.Detalle_Motivo_de_Baja__c);
		System.assertEquals(updateCase.Detalle_motivo_de_baja__c,holder.Detalle_Motivo_de_Baja__c);

	}
    
    static Usuario_no_envia_a_SAP__c aCustomSetting;
    static {
		aCustomSetting = new Usuario_no_envia_a_SAP__c();
		aCustomSetting.Name = UserInfo.getUserName();
		aCustomSetting.No_envia__c = true;

		insert aCustomSetting;
        
    }
}
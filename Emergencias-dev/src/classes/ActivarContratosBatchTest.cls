@isTest
private class ActivarContratosBatchTest {
	private static testMethod void itShouldBePosibleToActivateTheClonedContractOfACaseMatchingTheSettingsTypeAndCloseReasonValue() {
		Case aCase = Build.aCase().withRecordType(caseType).forAccount(anAccount).forContract(aContract)
			.withClonedContract(aCloneContract).isClosed().withImpactDate(System.today().addDays(-1))
			.WithCloseReason(someSettings.Valores_de_activacion__c.split(';')[0]).build();
		insert aCase;
		
		Test.startTest();
		ActivarContratosScheduler scheduler = new ActivarContratosScheduler();
        scheduler.execute(null);
		Test.stopTest();
		
		
		List<Contrato__c> contracts = [
			SELECT Id, Estado__c
			FROM Contrato__c
			WHERE Id = :aCase.Contrato__c
				OR Id = :aCase.Contrato_clonado__c
		];
		
		System.assertEquals(
			aCase.Contrato__c == contracts[0].Id,
			contracts[0].Estado__c == 'Baja',
			'Estado__c = "' + contracts[0].Estado__c + '" checked: "Baja"'
		);
		System.assertEquals(
			aCase.Contrato_clonado__c == contracts[0].Id,
			contracts[0].Estado__c == 'Activo',
			'Estado__c = "' + contracts[0].Estado__c + '" checked: "Activo"'
		);
		
		System.assertEquals(
			aCase.Contrato_clonado__c == contracts[1].Id,
			contracts[1].Estado__c == 'Activo',
			'Estado__c = "' + contracts[1].Estado__c + '" checked: "Activo"'
		);
		System.assertEquals(
			aCase.Contrato__c == contracts[1].Id,
			contracts[1].Estado__c == 'Baja',
			'Estado__c = "' + contracts[1].Estado__c + '" checked: "Baja"'
		);
	}
    
 	private static testMethod void IfTheAnswerFromSAPisNotOkThenTheCaseIsReOpenedAndTheContractsAreNotModified() {
        
		Case aCase = Build.aCase().withRecordType(caseType).forAccount(anAccount).forContract(aContract2)
			.withClonedContract(aCloneContract2).isClosed().withImpactDate(System.today().addDays(-1))
			.WithCloseReason(someSettings.Valores_de_activacion__c.split(';')[0]).build();
		insert aCase;
		
		Test.startTest();
		ActivarContratosScheduler scheduler = new ActivarContratosScheduler();
        scheduler.execute(null);
		Test.stopTest();
        
        Contrato__c contract = [
			SELECT Id, Estado__c
			FROM Contrato__c
			WHERE Id = :aCase.Contrato__c
		][0];
		
        Contrato__c contractClone = [
			SELECT Id, Estado__c
			FROM Contrato__c
			WHERE  Id = :aCase.Contrato_clonado__c
		][0];
        
        aCase = [SELECT Id, Status 
                 FROM Case
                 WHERE Id=:aCase.id][0];
		

		System.assertEquals('Abierto', aCase.Status );
        
		System.assertNotEquals('Baja', contract.Estado__c );
        
		System.assertNotEquals('Activo', contractClone.Estado__c );
        
        
	}

	@IsTest
	private static void itShouldBePosibleToActivateTheClonedContractOfACaseWhthDeveloperNameOfClientChange() {
		
		RecordType changeClientcaseType = [
			SELECT Id, DeveloperName
			FROM RecordType
			WHERE SObjectType = 'Case'
				AND DeveloperName = 'Cambio_de_Cliente'
				AND IsActive = true
		];
		
		Case aCase = Build.aCase().withRecordType(changeClientcaseType).forAccount(anAccount).forContract(aContract)
			.withClonedContract(aCloneContract).isClosed().withImpactDate(System.today().addDays(-1))
			.WithCloseReason(someSettings.Valores_de_activacion__c.split(';')[0]).build();
		insert aCase;
		
		Casos_activan_contrato_a_futuro__c anotherSettings = Build.someCaseFutureContractActivationSettngs()
			.withName('Set').withCaseType(changeClientcaseType.DeveloperName)
			.withActivationValues('Procesado').build();
		insert anotherSettings;

		Test.startTest();
		ActivarContratosScheduler scheduler = new ActivarContratosScheduler();
        scheduler.execute(null);
		Test.stopTest();
		
		
		List<Contrato__c> contracts = [
			SELECT Id, Estado__c
			FROM Contrato__c
			WHERE Id = :aCase.Contrato__c
				OR Id = :aCase.Contrato_clonado__c
		];
		
		System.assertEquals(
			aCase.Contrato__c == contracts[0].Id,
			contracts[0].Estado__c == 'Baja',
			'Estado__c = "' + contracts[0].Estado__c + '" checked: "Baja"'
		);
		System.assertEquals(
			aCase.Contrato_clonado__c == contracts[0].Id,
			contracts[0].Estado__c == 'Activo',
			'Estado__c = "' + contracts[0].Estado__c + '" checked: "Activo"'
		);
		
		System.assertEquals(
			aCase.Contrato_clonado__c == contracts[1].Id,
			contracts[1].Estado__c == 'Activo',
			'Estado__c = "' + contracts[1].Estado__c + '" checked: "Activo"'
		);
		System.assertEquals(
			aCase.Contrato__c == contracts[1].Id,
			contracts[1].Estado__c == 'Baja',
			'Estado__c = "' + contracts[1].Estado__c + '" checked: "Baja"'
		);
	}

	//==========================================================================
	static RecordType caseType;
	static Casos_activan_contrato_a_futuro__c someSettings;
	static Account anAccount;
	static Contrato__c aContract;
	static Contrato__c aContract2;
	static Contrato__c aCloneContract;
	static Contrato__c aCloneContract2;
	
	static {
		caseType = [
			SELECT Id, DeveloperName
			FROM RecordType
			WHERE SObjectType = 'Case'
				AND DeveloperName = 'Cambio_de_Cobertura'
				AND IsActive = true
		];
		someSettings = Build.someCaseFutureContractActivationSettngs().withCaseType(caseType.DeveloperName)
			.withActivationValues('Procesado;Conforme').build();
		insert someSettings;
		anAccount = Build.anAccount().build();
		insert anAccount;
		aContract = Build.aContract().forAccount(anAccount).withSkipSend(100).withActiveStatus().build();
        aContract.Estado_de_Envio_a_SAP__c='Ok';
		aCloneContract = Build.aContract().forAccount(anAccount).withSkipSend(100).withPendingStatus().build();
		insert new List<Contrato__c> {aContract, aCloneContract};
            
		aContract2 = Build.aContract().forAccount(anAccount).withSkipSend(100).withActiveStatus().build();
        aContract2.Estado_de_Envio_a_SAP__c='ERROR';
        aCloneContract2 = Build.aContract().forAccount(anAccount).withSkipSend(100).withPendingStatus().build();
		insert new List<Contrato__c> {aContract2, aCloneContract2};
            
	}
}
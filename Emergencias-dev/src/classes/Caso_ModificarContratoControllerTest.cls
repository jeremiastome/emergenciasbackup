@isTest
private class Caso_ModificarContratoControllerTest {
	private static testMethod void itShouldBePosibleToObtainTheClonedContractOfACase() {
		insert cloningSettings;
		
		Contrato__c result = Caso_ModificarContratoController.getClonedContract(aCase.Id);
		
		System.assertEquals(aContract.Id, result.Id);
		System.assertEquals(aContract.Contrato_de_Padrones__c, result.Contrato_de_Padrones__c);
	}
	
	private static testMethod void ifTheCaseIsNotTheMasterCase_ItShouldBePosibleToObtainTheMasterCasesClonedContract() {
		insert subCase;
		insert cloningSettings;
		
		
		Contrato__c result = Caso_ModificarContratoController.getClonedContract(subCase.Id);
		
		System.assertEquals(aContract.Id, result.Id);
		System.assertEquals(aContract.Contrato_de_Padrones__c, result.Contrato_de_Padrones__c);
	}
	
	private static testMethod void ifTheCaseIsAnAdditionCase_TheOriginalContractShouldBeReturned() {
		insert additionSettings;
		
		Contrato__c result = Caso_ModificarContratoController.getClonedContract(aCase.Id);
		
		System.assertEquals(originalContract.Id, result.Id);
		System.assertEquals(originalContract.Contrato_de_Padrones__c, result.Contrato_de_Padrones__c);
	}
	
	private static testMethod void ifTheCaseIsNeitherAnAdditionOrCloningCase_NullshouldBeReturned() {
		Contrato__c result = Caso_ModificarContratoController.getClonedContract(aCase.Id);
		
		System.assertEquals(null, result);
	}
	
	private static testMethod void itShouldBePosibleToGetTheHoldersForTheObtainedContract() {
		List<Titular__c> holders = new List<Titular__c>();
		for(Integer i = 0; i < 5; i++) {
			holders.add(
				Build.aHolder().forContract(aContract).forAccount(anAccount).build()
			);
		}
		insert holders;
		insert cloningSettings;
		
		Contrato__c result = Caso_ModificarContratoController.getClonedContract(aCase.Id);
		
		System.assertEquals(holders.size(), result.Titulares__r.size());
	}
	
	private static testMethod void ifTheCaseDoesntHaveTheCorrespondingContractForItsType_NullShouldBeReturned() {
		aCase.Contrato_clonado__c = null;
		update aCase;
		
		insert cloningSettings;
		
		Contrato__c result = Caso_ModificarContratoController.getClonedContract(aCase.Id);
		
		System.assertEquals(null, result);
	}
	
	private static testMethod void itShouldBePosibleToKnowWhenCloningSettingsAffectACase() {
		insert cloningSettings;
		
		String result = Caso_ModificarContratoController.getSettingsType(aCase.Id);
		
		System.assertEquals('Cloning', result);
	}
	
	private static testMethod void itShouldBePosibleToKnowWhenAdditionSettingsAffectACase() {
		insert additionSettings;
		
		String result = Caso_ModificarContratoController.getSettingsType(aCase.Id);
		
		System.assertEquals('Addition', result);
	}
	
	private static testMethod void itShouldBePosibleToKnowWhenNoSettingsAffectACase() {
		String result = Caso_ModificarContratoController.getSettingsType(aCase.Id);
		
		System.assertEquals('None', result);
	}
	
	//==========================================================================
	static Caso_generador__c cloningSettings;
	static Casos_Beneficiarios_Descuentos__c additionSettings;
	static Account anAccount;
	static Contrato__c aContract;
	static Contrato__c originalContract;
	static Case aCase;
	static Case subCase;
	
	static {
		RecordType caseRecordType = [
			SELECT Id, DeveloperName
			FROM RecordType
			WHERE SObjectType = 'Case'
				AND DeveloperName = 'Cambio_de_Cobertura'
			LIMIT 1
		];
		
		anAccount = Build.anAccount().build();
		insert anAccount;
		originalContract = Build.aContract().forAccount(anAccount).withUniqueNumber().isMassiveContract().build();
		aContract = Build.aContract().forAccount(anAccount).withUniqueNumber().isMassiveContract().build();
		insert new List<Contrato__c> {originalContract, aContract};
		aCase = Build.aCase().forAccount(anAccount).withClonedContract(aContract)
			.forContract(originalContract).withRecordType(caseRecordType).build();
		insert aCase;
		subCase = Build.aCase().forAccount(anAccount).forMasterCase(aCase).forContract(originalContract)
			.withRecordType(caseRecordType).build();
		
		cloningSettings = Build.someCaseContractCloneSettings().forCaseRecordType(caseRecordType)
			.withCloseReasonCorrect('Procesado')
			.withCloseReasonIncorrect('Rechazado').build();
		additionSettings = Build.someAdditionCaseSettings()
			.forCaseRecordType(caseRecordType).withCloseReasonCorrect('Procesado')
			.withCloseReasonIncorrect('Rechazado').build();
	}
}
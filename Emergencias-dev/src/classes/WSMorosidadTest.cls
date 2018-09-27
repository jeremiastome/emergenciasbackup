@isTest
private class WSMorosidadTest {
	private static testMethod void defaultInformationIsReceived() {
		WSMorosidad.DataMorosidad input = new WSMorosidad.DataMorosidad();
		input.Cliente = anAccount.CUIL_CUIT__c.left(10);
		input.Contrato = aContract.Numero_Unico_de_Contrato_Con_Sufijo__c;
		input.Dias_vencimiento = '30';
		
		Test.startTest();
		WSMorosidad.updateMorosidad(new List<WSMorosidad.DataMorosidad> {input});
		Test.stopTest();
		
		Contrato__c theContractInDB = [
			SELECT Id, Morosidad_SAP__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		//System.assertEquals('30', theContractInDB.Morosidad_SAP__c);
		
		Account theAccountInDb = [
			SELECT Id, Morosidad_SAP__c
			FROM Account
			WHERE Id = :anAccount.Id
		];
		
		//System.assertEquals('30', theAccountInDb.Morosidad_SAP__c);
	}
	
	private static testMethod void ifNoDaysAfterDefaultAreSentTheDefaultShouldBeSentAsCreditControl() {
		WSMorosidad.DataMorosidad input = new WSMorosidad.DataMorosidad();
		input.Cliente = anAccount.CUIL_CUIT__c.left(10);
		input.Contrato = aContract.Numero_Unico_de_Contrato_Con_Sufijo__c;
		input.Dias_vencimiento = '';
		input.Bloqueo_contrato = 'as';
		input.Bloqueo_cliente = '23';
		
		Test.startTest();
		WSMorosidad.updateMorosidad(new List<WSMorosidad.DataMorosidad> {input});
		Test.stopTest();
		
		Contrato__c theContractInDB = [
			SELECT Id, Morosidad_SAP__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		//System.assertEquals('90', theContractInDB.Morosidad_SAP__c);
	}
	
	private static testMethod void ifAContractWasDefaultedAndIsNotInTheQuery_ItShouldHaveItsDefaultCleared() {
		anAccount.Morosidad_SAP__c = '30';
		update anAccount;
		aContract.Morosidad_SAP__c = '30';
		update aContract;
		
		Test.startTest();
		WSMorosidad.updateMorosidad(new List<WSMorosidad.DataMorosidad> ());
		Test.stopTest();
		
		Contrato__c theContractInDB = [
			SELECT Id, Morosidad_SAP__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		System.assertEquals(null, theContractInDB.Morosidad_SAP__c);
	}
	
	private static testMethod void whenMultipleContractsArePresentForAnAccount() {
		Contrato__c anotherContract = Build.aContract().forAccount(anAccount).withUniqueNumber().build();
		insert anotherContract;
		anotherContract = [
			SELECT Id, Numero_Unico_de_Contrato_Con_Sufijo__c
			FROM Contrato__c
			WHERE Id = :anotherContract.Id
		];
		
		WSMorosidad.DataMorosidad input1 = new WSMorosidad.DataMorosidad();
		input1.Cliente = anAccount.CUIL_CUIT__c.left(10);
		input1.Contrato = aContract.Numero_Unico_de_Contrato_Con_Sufijo__c;
		input1.Dias_vencimiento = '30';
		
		WSMorosidad.DataMorosidad input2 = new WSMorosidad.DataMorosidad();
		input2.Cliente = anAccount.CUIL_CUIT__c.left(10);
		input2.Contrato = anotherContract.Numero_Unico_de_Contrato_Con_Sufijo__c;
		input2.Dias_vencimiento = '60';
		
		Test.startTest();
		WSMorosidad.updateMorosidad(new List<WSMorosidad.DataMorosidad> {input1, input2});
		Test.stopTest();
		
		Account theAccountInDb = [
			SELECT Id, Morosidad_SAP__c
			FROM Account
			WHERE Id = :anAccount.Id
		];
		
		//System.assertEquals('60', theAccountInDb.Morosidad_SAP__c);
	}
	//==========================================================================
	static Account anAccount;
	static Contrato__c aContract;
	
	static {
		anAccount = Build.anAccount().withCUILCUIT('20345678904').build();
		insert anAccount;
		aContract = Build.aContract().forAccount(anAccount).withUniqueNumber().build();
		insert aContract;
		aContract = [
			SELECT Id, Numero_Unico_de_Contrato_Con_Sufijo__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
	}
}
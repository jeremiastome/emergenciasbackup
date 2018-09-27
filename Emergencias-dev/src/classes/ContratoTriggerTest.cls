@isTest
private class ContratoTriggerTest {
	private static testMethod void itShouldBePosibleToInsertAContractForAnAccount() {
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).withCollectorType('CobComun').build();
		Cobrador__c Cobrador = Build.aCollector().withName('SR1').build();
  
		insert Cobrador;
		System.debug(Cobrador);
		insert aContract;
		
		System.assertNotEquals(null, aContract.Id);
	}
	
	private static testMethod void ifAContractWithCreditCardNumberHasAnInvalidNumberItsInsertionShouldFail() {
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount)
			.withCardNumber('4123fakecard6789').build();
		
		boolean failed = false;
		try {
			insert aContract;
		}
		catch (Exception ex) {
			failed = true;
			System.assert(
				ex.getMessage().contains(Label.Tarjeta_invalida),
				'The error message "' + ex.getMessage() + '" '
				+ 'did not contain "' + Label.Tarjeta_invalida + '"'
			);
		}
		System.assert(failed, 'The insertion did not fail.');
	}
	
	private static testMethod void ifAContractWithCreditCardNumberHasAnInvalidNumberWhenUpdatedItShouldFail() {
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).build();
		insert aContract;
		
		aContract.Numero_de_Tarjeta__c = '4123fakecard6789';
		boolean failed = false;
		try {
			update aContract;
		}
		catch (Exception ex) {
			failed = true;
			System.assert(
				ex.getMessage().contains(Label.Tarjeta_invalida),
				'The error message "' + ex.getMessage() + '" '
				+ 'did not contain "' + Label.Tarjeta_invalida + '"'
			);
		}
		System.assert(failed, 'The insertion did not fail.');
	}
	
	private static testMethod void whenAContractWithAValidCardNumberIsInserted_TheNumberShouldBeSavedInThePlainField() {
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount)
			.withValidCardNumber().build();
		
		insert aContract;
		
		Contrato__c theContractInDB = [
			SELECT Id, Numero_de_Tarjeta__c, Tarjeta_sin_cifrar__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		System.assertEquals(aContract.Numero_de_Tarjeta__c, theContractInDB.Tarjeta_sin_cifrar__c);
		System.assertEquals(
			'************' + aContract.Numero_de_Tarjeta__c.right(4),
			theContractInDB.Numero_de_Tarjeta__c
		);
	}
	
	private static testMethod void ifAnInvalidCBUIsInserted_AnErrorShouldBeAdded() {
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).withCBU('1233rdsfds23').build();
		
		boolean failed = false;
		try {
			insert aContract;
		}
		catch (Exception ex) {
			failed = true;
			System.assert(
				ex.getMessage().contains(Label.CBU_invalido),
				'The error message "' + ex.getMessage() + '" '
				+ 'did not contain "' + Label.CBU_invalido + '"'
			);
		}
		System.assert(failed, 'The insertion did not fail.');
	}
	
	private static testMethod void ifAnInvalidCBUIsUpdated_AnErrorShouldBeAdded() {
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).build();
		insert aContract;
		
		aContract.CBU_cifrado__c = '1233rdsfds23';
		boolean failed = false;
		try {
			update aContract;
		}
		catch (Exception ex) {
			failed = true;
			System.assert(
				ex.getMessage().contains(Label.CBU_invalido),
				'The error message "' + ex.getMessage() + '" '
				+ 'did not contain "' + Label.CBU_invalido + '"'
			);
		}
		System.assert(failed, 'The insertion did not fail.');
	}
    
    private static testMethod void whenAContractWithAValidCBUIsInserted_TheNumberShouldBeSavedInThePlainField() {
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount)
			.withValidCBU().build();
		
		insert aContract;
		
		Contrato__c theContractInDB = [
			SELECT Id, CBU__C, CBU_cifrado__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		System.assertEquals(aContract.CBU_cifrado__c, theContractInDB.CBU__C);
		System.assertEquals(
			aContract.CBU_cifrado__c.left(6)+ '**********' + aContract.CBU_cifrado__c.right(4),
			theContractInDB.CBU_cifrado__c);
	}
	
	//============================================================
	//SAP interface
	private static testMethod void aContractShouldHaveItsSkipSendFieldLoweredEveryTime() {
		Contrato__c aContract = Build.aContract().forAccount(anAccount).withUniqueNumber().withSkipSend(2).build();
		insert aContract;
		
		Contrato__c theContractInDB = [
			SELECT Id, Saltear_envio__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		System.assertEquals(aContract.Saltear_envio__c - 1, theContractInDB.Saltear_envio__c);
	}
	
	private static testMethod void itShouldBePosibleToSendTheContractToSAP() {
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		RecordType contractType = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Contrato'
				AND sObjectType = 'Contrato__c'
				AND IsActive = true
		];
		
		String contractNumber = 'a345789';
		Contrato__c aContract = Build.aContract().forAccount(anAccount).withUniqueNumber(contractNumber)
			.withStatus('En proceso de venta').withRecordType(contractType).withSkipSend(0).build();
		
		insert aContract;
		Test.startTest();
		aContract.Estado__c = 'Activo';
		update aContract;
		Test.stopTest();
		
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out request =
			(WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out)serverMock.requestObj;
		
		System.assertEquals(1, request.Pedido.size() );
		System.assertEquals('A', request.Pedido[0].Cabecera.TipoOperacion);
	}
	
	private static testMethod void contractsThatDoNotBillAreNotToBeSentToSAP() {
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		
		String contractNumber = 'a345789';
		Contrato__c aContract = Build.aContract().forAccount(anAccount).withUniqueNumber(contractNumber)
			.withStatus('En proceso de venta').doesNotBill().withSkipSend(0).notWaitingToBeSent().build();
		
		insert aContract;
		Test.startTest();
		aContract.Estado__c = 'Activo';
		update aContract;
		Test.stopTest();
		
		System.assertEquals(null, serverMock.requestObj);
		
		Contrato__c contractInDB = [
			SELECT Id, Esperando_envio__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		System.assertEquals(false, contractInDB.Esperando_envio__c);
	}
	
	private static testMethod void whenAContractWouldBeSentToSAPTheExpectingSendFieldShouldBeSet() {
		RecordType contractType = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Contrato'
				AND sObjectType = 'Contrato__c'
				AND IsActive = true
		];
		
		String contractNumber = 'a345789';
		Contrato__c aContract = Build.aContract().forAccount(anAccount).withUniqueNumber(contractNumber)
			.withStatus('En proceso de venta').withRecordType(contractType).withSkipSend(0)
			.notWaitingToBeSent().build();
		
		insert aContract;
		
		aContract.Estado__c = 'Activo';
		update aContract;
		
		Contrato__c contractInDB = [
			SELECT Id, Esperando_envio__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		System.assertEquals(true, contractInDB.Esperando_envio__c);
	}
	
	//============================================================
	//Contract unique number
	//
	//
	// ESTA FUNCIONALIDAD YA NO SE USA
	// 
	/*
	private static testMethod void whenAContractWithUniqueContractNumberIsInsertedAndThereAreNoSettingsForTheLetter_itShouldBeCreated() {
		String contractNumber = 'a345789';
		Contrato__c aContract = Build.aContract().forAccount(anAccount).withUniqueNumber(contractNumber).build();
		insert aContract;
		
		Contrato__c theContractInDB = [
			SELECT Id, Numero_unico_de_contrato_letra__c, Numero_unico_de_contrato_numero__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		Numeros_de_contratos__c settingsInDB = Numeros_de_contratos__c.getValues('A');
		System.assertEquals(theContractInDB.Numero_unico_de_contrato_numero__c, settingsInDB.Numero_maximo__c);
	}*/
	/*private static testMethod void whenAContractWithUniqueContractNumberIsInsertedTheFirstCharacterShouldBeSavedInTheUniqueNumberLetterField() {
		Numeros_de_contratos__c contractNumberSettings = Build.aContractNumberSetting().withLetter('A').withMaxNumber(123).build();
		insert contractNumberSettings;
		String contractNumber = 'a345789';
		Contrato__c aContract = Build.aContract().forAccount(anAccount).withUniqueNumber(contractNumber).build();
		insert aContract;
		
		Contrato__c theContractInDB = [
			SELECT Id, Numero_unico_de_contrato_letra__c, Numero_unico_de_contrato_numero__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		System.assertEquals(contractNumber.left(1).toUpperCase(), theContractInDB.Numero_unico_de_contrato_letra__c);
		
		Numeros_de_contratos__c settingsInDB = Numeros_de_contratos__c.getValues('A');
		System.assertEquals(theContractInDB.Numero_unico_de_contrato_numero__c, settingsInDB.Numero_maximo__c);
	}*/
	
	private static testMethod void whenAContractWithUniqueContractNumberAndSuffixIsInsertedTheFullNumberShouldBePopulated() {
		String contractNumber = 'a345789';
		Contrato__c aContract = Build.aContract().forAccount(anAccount).withUniqueNumber(contractNumber).withSuffix(1).build();
		insert aContract;
		
		Contrato__c theContractInDB = [
			SELECT Id, Numero_Unico_de_Contrato_Con_Sufijo__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		System.assertEquals(
			aContract.Numero_Unico_de_Contrato__c + String.valueOf(aContract.Sufijo__c).leftPad(2, '0'),
			theContractInDB.Numero_Unico_de_Contrato_Con_Sufijo__c
		);
	}
	// ESTA FUNCIONALIDAD YA NO SE USA
	// 
	/*
	private static testMethod void whenAContractIsUpdatedWithAUniqueNumber_TheSettingsShouldBeUpdated() {
		String contractNumber = 'a345789';
		Contrato__c aContract = Build.aContract().forAccount(anAccount).build();
		insert aContract;
		
		System.assertEquals(null, Numeros_de_contratos__c.getAll().get('A'));
		
		aContract.Numero_unico_de_contrato__c = contractNumber;
		update aContract;
		
		Contrato__c theContractInDB = [
			SELECT Id, Numero_unico_de_contrato_letra__c, Numero_unico_de_contrato_numero__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		Numeros_de_contratos__c settingsInDB = Numeros_de_contratos__c.getValues('A');
		System.assertEquals(theContractInDB.Numero_unico_de_contrato_numero__c, settingsInDB.Numero_maximo__c);
	}
	*/
	private static testMethod void whenAContractWithUniqueContractNumberIsUpdatedWithTheUniqueNumber_TheSettingsShouldNotBeUpdated() {
		Numeros_de_contratos__c numberSettings = new Numeros_de_contratos__c();
		numberSettings.Name = 'A';
		numberSettings.Numero_maximo__c = 300000;
		insert numberSettings;
		
		String contractNumber = 'a345789';
		Contrato__c aContract = Build.aContract().forAccount(anAccount).withUniqueNumber(contractNumber).build();
		insert aContract;
		

		aContract.Saltear_envio__c = 2000;
		update aContract;
		
		Numeros_de_contratos__c settingsInDB = Numeros_de_contratos__c.getValues('A');
		System.assertEquals(numberSettings.Numero_maximo__c, settingsInDB.Numero_maximo__c);
	}
	
	//==========================================================================
	static Account anAccount;
	
	static {
		anAccount = Build.anAccount().withBillingLatitude(23.9876789).withBillingLongitude(43.1243454).build();
		insert anAccount;
	}
}
@isTest
private class AccountTriggerTest {
	private static testmethod void whenAPersonAccountIsUpdatedItShouldCopyUniqueCustomCodeToSAPCode() {
		Account anAccount = Build.anAccount().isPersonAccount().withUniqueCustomerCode('321').build();
		anAccount.Es_Cliente__c=true;
		insert anAccount;
		anAccount.N_mero_nico_de_Cliente__c = '123';
		update anAccount;

		Account accountInBD = [select Codigo_SAP_contacto__pc from account where id = :anAccount.id];
		System.assertEquals('123', accountInBD.Codigo_SAP_contacto__pc);
	}

	private static testMethod void whenAnAccountIsInsertedItShouldBeSentToSAP() {
		Account anAccount = Build.anAccount().availableToSendToSAP().build();
		anAccount.Es_Cliente__c=true;
		
		Test.startTest();
		insert anAccount;
		Test.stopTest();
		
		String receivedBody = serverMock.receivedRequest.getBody();
		//System.assert(receivedBody.contains('<TipoOperacion>A</TipoOperacion>'));
	}

	private static testMethod void whenAnAccountIsUpdatedItShouldBeSentToSAP() {
		Account anAccount = Build.anAccount().availableToSendToSAP().build();
		anAccount.Es_Cliente__c=true;
		
		insert anAccount;
		Test.startTest();
		update anAccount;
		Test.stopTest();
		
		String receivedBody = serverMock.receivedRequest.getBody();
		System.assert(receivedBody.contains('<TipoOperacion>M</TipoOperacion>'));
	}

	/*
	private static testMethod void whenAnAccountIsDeletedItShouldBeSentToSAP() {
		Account anAccount = Build.anAccount().availableToSendToSAP().build();
		
		insert anAccount;
		Test.startTest();
		delete anAccount;
		Test.stopTest();
		
		String receivedBody = serverMock.receivedRequest.getBody();
		System.assert(receivedBody.contains('<TipoOperacion>B</TipoOperacion>'));
	}
	*/
	private static testMethod void whenInsertingAnAccountItsCuitShouldBeCopiedAsItsClientNumberExceptForTheLastDigit() {
		Account anAccount = Build.anAccount().withCUILCUIT('20123456784').availableToSendToSAP().build();
		anAccount.Es_Cliente__c=true;
        
		Test.startTest();
		insert anAccount;
		Test.stopTest();
		
		Account theAccountInDB = [
			SELECT Id, N_mero_nico_de_Cliente__c
			FROM Account
			WHERE Id = :anAccount.Id
		];
		System.assertEquals(
			anAccount.CUIL_CUIT__c.left(anAccount.CUIL_CUIT__c.length() - 1),
			theAccountInDB.N_mero_nico_de_Cliente__c
		);
	}
	
	private static testMethod void whenUpdatingAnAccountIfTheUniqueClientNumberIsNotSetItShouldTakeItFromTheCuitCuil() {
		delete sapSettings;
		Account anAccount = Build.anAccount().availableToSendToSAP().build();
		anAccount.Es_Cliente__c=true;
		
		insert anAccount;
		anAccount.CUIL_CUIT__c = '20123456784';
        anAccount.N_mero_nico_de_Cliente__c = '';
		Test.startTest();
		update anAccount;
		Test.stopTest();
		
		Account theAccountInDB = [
			SELECT Id, N_mero_nico_de_Cliente__c
			FROM Account
			WHERE Id = :anAccount.Id
		];
		System.assertEquals(
			anAccount.CUIL_CUIT__c.left(anAccount.CUIL_CUIT__c.length() - 1),
			theAccountInDB.N_mero_nico_de_Cliente__c
		);
	}
	
	private static testMethod void ifTheCuilChangesTheClientNumberShouldNotChange() {
		delete sapSettings;
		Account anAccount = Build.anAccount().withCUILCUIT('20123456784').availableToSendToSAP().build();
		anAccount.Es_Cliente__c=true;
		
		insert anAccount;
		anAccount.CUIL_CUIT__c = '20123454384';
		update anAccount;
		
		Account theAccountInDB = [
			SELECT Id, N_mero_nico_de_Cliente__c
			FROM Account
			WHERE Id = :anAccount.Id
		];
		System.assertNotEquals(
			anAccount.CUIL_CUIT__c.left(anAccount.CUIL_CUIT__c.length() - 1),
			theAccountInDB.N_mero_nico_de_Cliente__c
		);
	}
	
	private static testMethod void whenTheAccountIsNotReadyItShouldntBeSent() {
		Account anAccount = Build.anAccount().withCUILCUIT('20123456784').build();
		anAccount.Es_Cliente__c=true;
		
		Test.startTest();
		insert anAccount;
		Test.stopTest();
		
		System.assertEquals(null, serverMock.receivedRequest);
	}
	
	private static testMethod void whenAnAccountIsUpdatedToBeReadyItShouldBeSentToSAPAsAnInsertion() {
		Account anAccount = Build.anAccount().build();
		anAccount.Es_Cliente__c=true;
		
		insert anAccount;
		anAccount.Dado_de_alta__c = true;
		Test.startTest();
		update anAccount;
		Test.stopTest();
		
		String receivedBody = serverMock.receivedRequest.getBody();
		System.assert(receivedBody.contains('<TipoOperacion>A</TipoOperacion>'));
	}
	
	private static testMethod void whenAnAccountIsUpdatedToStopBeingReadyItShouldBeSentToSAPAsADeletion() {
		Account anAccount = Build.anAccount().availableToSendToSAP().build();
		anAccount.Es_Cliente__c=true;
		insert anAccount;
		anAccount.Dado_de_alta__c = false;
        
		Test.startTest();
		update anAccount;
		Test.stopTest();
		
		String receivedBody = serverMock.receivedRequest.getBody();
		System.assert(receivedBody.contains('<TipoOperacion>B</TipoOperacion>'));
	}

	private static testMethod void itShouldBePosibleToSkipSendingTheAccountToSAP() {
		Account anAccount = Build.anAccount().availableToSendToSAP().withSkipSend(2).build();
		anAccount.Es_Cliente__c=true;
		
		Test.startTest();
		insert anAccount;
		Test.stopTest();
		
		System.assertEquals(null, serverMock.receivedRequest);
		
		Account theAccountInDb = [
			SELECT Id, Saltear_envio__c
			FROM Account
			WHERE Id = :anAccount.Id
		];
		
		System.assertEquals(1, theAccountInDb.Saltear_envio__c);
	}
	
	private static testMethod void whenAPersonAccountIsInsertedTheUniqueClientNumberShouldBeCopiedToTheContactSide() {
		Account anAccount = Build.anAccount().isPersonAccount().build();
		anAccount.Es_Cliente__c=true;
		insert anAccount;
		
		Account theAccountInDB = [
			SELECT Id, N_mero_nico_de_Cliente__c, Codigo_SAP_contacto__pc
			FROM Account
			WHERE Id = :anAccount.Id
		];
		
		System.assertEquals(theAccountInDB.N_mero_nico_de_Cliente__c, theAccountInDB.Codigo_SAP_contacto__pc);
	}
	
	//==========================================================================
	static Configuracion_SAP__c sapSettings;
	static WebServiceMock serverMock;
	
	static {
		sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').build();
		insert sapSettings;
		
		serverMock = new WebServiceMock();
		Test.setMock(HttpCalloutMock.class, serverMock);
		serverMock.returnBody = 'resp';
	}
}
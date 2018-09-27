@isTest
private class ContactTriggerTest {
	
	private static testMethod void whenInsertingAContactWithoutAccountItShouldBeAssignToContactFatherAccount() {

		Parametros_Operativos__c accountFatherRef = new Parametros_Operativos__c(
												     Name='Contact_Father',valor__c=anAccount.Id);
        insert accountFatherRef;
		Contact aContact = Build.aContact().build();
		Test.startTest();
		insert aContact;
		Test.stopTest();
		Contact theContactInDb = [
			SELECT accountId 
			FROM Contact
			WHERE Id = :aContact.Id
		];
		System.assertEquals(anAccount.Id,theContactInDb.AccountId);
	}

    private static testMethod void whenInsertingAContactItShouldBeSentToSAP() {
		Contact aContact = Build.aContact().forAccount(anAccount).build();
		
		Test.startTest();
		insert aContact;
		Test.stopTest();
		
		String requestBody = serverMock.receivedRequest.getBody();
        System.debug(requestBody);
		System.assertEquals(true, requestBody.contains('<TipoOperacion>A</TipoOperacion>'));
	}
	
	private static testMethod void whenAContactIsInsertedWithSkipSendItShouldNotBeSentToSAP() {
		Contact aContact = Build.aContact().forAccount(anAccount).withSkipSend(2).build();
		
		Test.startTest();
		insert aContact;
		Test.stopTest();
		
		System.assertEquals(null, serverMock.receivedRequest);
		
		Contact theContactInDb = [
			SELECT Id, Saltear_envio__c
			FROM Contact
			WHERE Id = :aContact.Id
		];
		
		System.assertEquals(aContact.Saltear_envio__c - 1, theContactInDb.Saltear_envio__c);
	}
	
	private static testMethod void whenUpdatingAContactItShouldBeSentToSAP() {
		Contact aContact = Build.aContact().forAccount(anAccount).withSkipSend(2).build();
		insert aContact;
		aContact.Saltear_envio__c = 0;
		
		Test.startTest();
		update aContact;
		Test.stopTest();
		
		String requestBody = serverMock.receivedRequest.getBody();
		System.assertEquals(true, requestBody.contains('<TipoOperacion>M</TipoOperacion>'));
	}

	
	
	//==========================================================================
	static Configuracion_SAP__c sapSettings;
	static WebServiceMock serverMock;
	static Account anAccount;
	
	static {
		serverMock = new WebServiceMock();
		Test.setMock(HttpCalloutMock.class, serverMock);
		
		sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		
		anAccount = Build.anAccount().build();
        anAccount.Saltear_envio__c=123;
		insert anAccount;
        
		
	}
}
@isTest
private class Cuenta_ValidarZonasControllerTest {
	private static testMethod void itShouldBePosibleToRequestZoneDataForAnAccount() {
		WSGetContractZone.ResponseZoneService zonesResponse = new WSGetContractZone.ResponseZoneService();
		zonesResponse.CodigoZona = '98ey329948';
		zonesResponse.AccesoCondicionado = true;
		
		serverMock.returnBodies.add(JSON.serialize(zonesResponse));
		
		Test.startTest();
		String result = Cuenta_ValidarZonasController.getZoneForAccount(anAccount.Id);
		Test.stopTest();
		
		System.assertEquals(
			'success' + Cuenta_ValidarZonasController.SEPARATOR + Label.Zona_de_cuenta_actualizada,
			result
		);
		
		Account theAccountInDB = [
			SELECT Id, Zona_de_facturacion__c
			FROM Account
			WHERE Id = :anAccount.Id
		];
		
		System.assertNotEquals(null, theAccountInDB.Zona_de_facturacion__c);
	}
	
	private static testMethod void ifTheServiceReturnsNoZoneWhenRequestingTheData_AnErrorShouldBeReturned() {
		serverMock.returnBodies.add('');
		serverMock.returnStatusCode = 404;
		
		Test.startTest();
		String result = Cuenta_ValidarZonasController.getZoneForAccount(anAccount.Id);
		Test.stopTest();
		
		System.assertEquals(
			'error' + Cuenta_ValidarZonasController.SEPARATOR + Label.Error_no_se_recibio_zona,
			result
		);
	}
	
	private static testMethod void ifTheServiceCantGetTheAccountsPositionWhenRequestingTheData_AnErrorShouldBeReturned() {
		anAccount.BillingLatitude = null;
		anAccount.BillingLongitude = null;
		anAccount.BillingCity = 'Testopolis';
		anAccount.BillingStreet = '123 Test st.';
		anAccount.BillingCountry = 'Testland';
		update anAccount;
		
		serverMock.returnBodies.add('');
		serverMock.returnStatusCode = 503;
		
		Test.startTest();
		String result = Cuenta_ValidarZonasController.getZoneForAccount(anAccount.Id);
		Test.stopTest();
		
		System.assertEquals(
			'error' + Cuenta_ValidarZonasController.SEPARATOR + Label.Error_no_se_obtuvo_posicion,
			result
		);
	}
	
	private static testMethod void ifTheServiceReturnsCorrectlyButHasNoZoneAMessageShouldBeReturned() {
		WSGetContractZone.ResponseZoneService zonesResponse = new WSGetContractZone.ResponseZoneService();
		zonesResponse.CodigoZona = null;
		zonesResponse.AccesoCondicionado = false;
		
		serverMock.returnBodies.add(JSON.serialize(zonesResponse));
		
		Test.startTest();
		String result = Cuenta_ValidarZonasController.getZoneForAccount(anAccount.Id);
		Test.stopTest();
		
		System.assertEquals(
			'success' + Cuenta_ValidarZonasController.SEPARATOR + Label.CVZ_No_esta_en_zona,
			result
		);
		
		Account theAccountInDB = [
			SELECT Id, Zona_de_facturacion__c
			FROM Account
			WHERE Id = :anAccount.Id
		];
		
		System.assertEquals(null, theAccountInDB.Zona_de_facturacion__c);
	}
	
	//==========================================================================
	static WebServiceMock serverMock;
	static Zona__c aZone;
	static Account anAccount;
	
	static {
		serverMock = new WebServiceMock();
		Test.setMock(HttpCalloutMock.class, serverMock);
		insert Build.someEmergenciesCredentials().build();
		insert Build.someGoogleSettings().build();
		
		aZone = Build.aZone().withName('Zone A').build();
		insert aZone;
		anAccount = Build.anAccount().withBillingLatitude(34.123412).withBillingLongitude(-34.98876).build();
		insert anAccount;
		
		Test.setCurrentPage(new PageReference('Page.Cuenta_ValidarZonas_VF'));
		ApexPages.currentPage().getParameters().put('Id', anAccount.Id);
	}
}
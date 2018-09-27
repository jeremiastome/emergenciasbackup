@isTest
private class WSGetContractZoneTest {
	private static testMethod void itShouldBePosibleToCallTheZoneService() {
		WSGetContractZone.ResponseZoneService response = new WSGetContractZone.ResponseZoneService();
		response.CodigoZona = 'ZAC 97';
		response.AccesoCondicionado = true;

		serverMock.returnBody = JSON.serialize(response);
		WSGetContractZone.Position position = new WSGetContractZone.Position(-34.69254, -58.44941);

		Test.startTest();
		WSGetContractZone.ResponseZoneService result = WSGetContractZone.callZoneService(position);
		Test.stopTest();

		System.assertEquals(response.CodigoZona, result.CodigoZona);
		System.assertEquals(response.AccesoCondicionado, result.AccesoCondicionado);

		System.assertEquals(
			loginSettings.Host__c + loginSettings.Path_zona_condicionada__c,
			serverMock.receivedRequest.getEndpoint()
		);

		WSGetContractZone.Position requestedPos = (WSGetContractZone.Position)JSON.deserialize(
			serverMock.receivedRequest.getBody(),
			WSGetContractZone.Position.class
		);

		System.assertEquals(position.Latitud, requestedPos.Latitud);
		System.assertEquals(position.Longitud, requestedPos.Longitud);
	}

	private static testMethod void itShouldBePosibleToCallTheCollectorsService() {
		WSGetContractZone.ResponseCollectors response = new WSGetContractZone.ResponseCollectors();
		WSGetContractZone.Collector responseCollector = new WSGetContractZone.Collector();

		responseCollector.CodigoSAP = '70000041';
		responseCollector.CodigoZona = 'B49001';
		responseCollector.EmpresaCobranza = 'EMME';
		responseCollector.LocalidadCabecera = 'Lomas de Zamora';
		responseCollector.NombreCobrador = 'K2';
		responseCollector.NombreDepartamento = 'LOMAS DE ZAMORA';
		responseCollector.NombreProvincia = 'BUENOS AIRES';
		responseCollector.TipoCobrador = 'Cobrador Común';

		response.CobradoresList = new List<WSGetContractZone.Collector>();
		response.CobradoresList.add(responseCollector);

		serverMock.returnBody = JSON.serialize(response);
		WSGetContractZone.Position position = new WSGetContractZone.Position(-34.69254, -58.44941, 'code thingy');

		Test.startTest();
		WSGetContractZone.ResponseCollectors result = WSGetContractZone.callCollectorsService(position);
		Test.stopTest();

		System.assertEquals(1, result.CobradoresList.size());
		System.assertEquals(responseCollector.CodigoSAP, result.CobradoresList[0].CodigoSAP);
		System.assertEquals(responseCollector.CodigoZona, result.CobradoresList[0].CodigoZona);
		System.assertEquals(responseCollector.EmpresaCobranza, result.CobradoresList[0].EmpresaCobranza);
		System.assertEquals(responseCollector.LocalidadCabecera, result.CobradoresList[0].LocalidadCabecera);
		System.assertEquals(responseCollector.NombreCobrador, result.CobradoresList[0].NombreCobrador);
		System.assertEquals(responseCollector.NombreDepartamento, result.CobradoresList[0].NombreDepartamento);
		System.assertEquals(responseCollector.NombreProvincia, result.CobradoresList[0].NombreProvincia);
		System.assertEquals(responseCollector.TipoCobrador, result.CobradoresList[0].TipoCobrador);

		System.assertEquals(
			loginSettings.Host__c + loginSettings.Path_cobradores__c,
			serverMock.receivedRequest.getEndpoint()
		);

		WSGetContractZone.Position requestedPos = (WSGetContractZone.Position)JSON.deserialize(
			serverMock.receivedRequest.getBody(),
			WSGetContractZone.Position.class
		);

		System.assertEquals(position.Latitud, requestedPos.Latitud);
		System.assertEquals(position.Longitud, requestedPos.Longitud);
		System.assertEquals(position.CodTipoCobrador, requestedPos.CodTipoCobrador);
	}

	private static testMethod void itShouldBePosibleToObtainTheZoneDataForAContractFromTheServer() {
        Cobrador__c cobradorTest2 = build.aCollector().withName('SR1').build();
        insert cobradorTest2;

		insert aZone;
		insert aCollector;

		WSGetContractZone.ResponseCollectors collectorResponse = prepareCollectorResponse();

		serverMock.returnBodies.add(JSON.serialize(collectorResponse));

		Test.startTest();
		WSGetContractZone.getContractZoneData(aContract.Id);
		Test.stopTest();

		Contrato__c theContractInDB = [
			SELECT Id, Zona__c, Zona_automatica__c, Cobrador__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];

		aZone = [select id from Zona__c where Name = 'B49001'];
		System.assertEquals(aZone.Id, theContractInDB.Zona__c);
		System.assertEquals(aZone.Id, theContractInDB.Zona_automatica__c);
		System.assertEquals(aCollector.Id, theContractInDB.Cobrador__c);

		System.assertEquals(1, serverMock.receivedRequests.size());
		WSGetContractZone.Position requestedPos = (WSGetContractZone.Position)JSON.deserialize(
			serverMock.receivedRequests[0].getBody(),
			WSGetContractZone.Position.class
		);

		System.assertEquals(anAccount.BillingLatitude, requestedPos.Latitud);
		System.assertEquals(anAccount.BillingLongitude, requestedPos.Longitud);
		System.assertEquals(aContract.Tipo_de_Cobrador__c, requestedPos.CodTipoCobrador);
	}

	private static testMethod void itShouldBePosibleToGetAPositionFromTheGoogleServices() {
		WSGetContractZone.GoogleGeoResponse response = new WSGetContractZone.GoogleGeoResponse();
		response.status = 'OK';
		response.results = new List<WSGetContractZone.GoogleResult>();
		WSGetContractZone.GoogleResult gResult = new WSGetContractZone.GoogleResult();
		gResult.geometry = new WSGetContractZone.GoogleGeometry();
		gResult.geometry.location = new WSGetContractZone.GoogleLocation();
		gResult.geometry.location.lat = 23.6545654;
		gResult.geometry.location.lng = 32.243454;
		response.results.add(gResult);

		serverMock.returnBody = JSON.serialize(response);

		String locationString = 'some location';

		Test.startTest();
		WSGetContractZone.Position result = WSGetContractZone.getLocationFromGoogle(locationString);
		Test.stopTest();

		System.assertEquals(gResult.geometry.location.lat, result.Latitud);
		System.assertEquals(gResult.geometry.location.lng, result.Longitud);

		System.assertEquals(
			'https://maps.googleapis.com/maps/api/geocode/json?address='
				+ EncodingUtil.urlEncode(locationString, 'UTF-8')
				+ '&key=' + googleSettings.Key__c,
			serverMock.receivedRequest.getEndpoint()
		);
	}

	private static testMethod void itShouldBePosibleToGetAPositionsFromTheGoogleServices() {
		WSGetContractZone.GoogleGeoResponse response = new WSGetContractZone.GoogleGeoResponse();
		response.status = 'OK';
		response.results = new List<WSGetContractZone.GoogleResult>();
		WSGetContractZone.GoogleResult gResult = new WSGetContractZone.GoogleResult();
		gResult.geometry = new WSGetContractZone.GoogleGeometry();
		gResult.geometry.location = new WSGetContractZone.GoogleLocation();
		gResult.geometry.location.lat = 23.6545654;
		gResult.geometry.location.lng = 32.243454;
		response.results.add(gResult);

		serverMock.returnBody = JSON.serialize(response);

		String locationString = 'some location';

		Test.startTest();
		WSGetContractZone.Position result = WSGetContractZone.getLocationFromGoogle(locationString);
		Test.stopTest();

		System.assertEquals(gResult.geometry.location.lat, result.Latitud);
		System.assertEquals(gResult.geometry.location.lng, result.Longitud);

		System.assertEquals(
			'https://maps.googleapis.com/maps/api/geocode/json?address='
				+ EncodingUtil.urlEncode(locationString, 'UTF-8')
				+ '&key=' + googleSettings.Key__c,
			serverMock.receivedRequest.getEndpoint()
		);
	}

	private static testMethod void ifTheZoneOrTheCollectorArentPresentInTheDatabase_TheyShouldBeCreated() {
        Cobrador__c cobradorTest2 = build.aCollector().withName('SR1').build();
        insert cobradorTest2;

		//WSGetContractZone.ResponseZoneService zonesResponse = prepareZoneResponse();
		WSGetContractZone.ResponseCollectors collectorResponse = prepareCollectorResponse();

		//serverMock.returnBodies.add(JSON.serialize(zonesResponse));
		serverMock.returnBodies.add(JSON.serialize(collectorResponse));

		Test.startTest();
		WSGetContractZone sender = new WSGetContractZone(aContract.Id);
		System.enqueueJob(sender);
		Test.stopTest();

		List<Zona__c> zones = [
			SELECT Id
			FROM Zona__c
			WHERE ID_Externo__c = :collectorResponse.getZone().id_externo__c
		];
		System.assertEquals(1, zones.size());

		List<Cobrador__c> collectors = [
			SELECT Id
			FROM Cobrador__c
			WHERE Codigo_Sap__c = :aCollector.Codigo_Sap__c
		];

		System.assertEquals(1, collectors.size());

		Contrato__c theContractInDB = [
			SELECT Id, Zona__c, Zona_automatica__c, Cobrador__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];

		System.assertEquals(zones[0].Id, theContractInDB.Zona__c);
		System.assertEquals(zones[0].Id, theContractInDB.Zona_automatica__c);
		System.assertEquals(collectors[0].Id, theContractInDB.Cobrador__c);
	}

	private static testMethod void itShouldBePosibleToGetTheZoneDataForAnAccount() {
		insert aZone;

		WSGetContractZone.ResponseZoneService zonesResponse = prepareZoneResponse();

		serverMock.returnBodies.add(JSON.serialize(zonesResponse));

		Test.startTest();
		integer result = WSGetContractZone.getAccountZoneData(anAccount.Id);
		Test.stopTest();

		System.assertEquals(WSGetContractZone.RESULT_OK, result);

		Account theAccountInDb = [
			SELECT Id, Zona_de_facturacion__c
			FROM Account
			WHERE Id = :anAccount.Id
		];

		System.assertEquals(aZone.Id, theAccountInDb.Zona_de_facturacion__c);

		System.assertEquals(1, serverMock.receivedRequests.size());
		WSGetContractZone.Position requestedPos = (WSGetContractZone.Position)JSON.deserialize(
			serverMock.receivedRequests[0].getBody(),
			WSGetContractZone.Position.class
		);

		System.assertEquals(anAccount.BillingLatitude, requestedPos.Latitud);
		System.assertEquals(anAccount.BillingLongitude, requestedPos.Longitud);
	}

	//==========================================================================
	private static WSGetContractZone.ResponseZoneService prepareZoneResponse() {
		WSGetContractZone.ResponseZoneService result = new WSGetContractZone.ResponseZoneService();
		result.CodigoZona = aZone.ID_Externo__c;
		result.AccesoCondicionado = aZone.Tipo__c == 'Acceso condicionado';

		return result;
	}

	public static WSGetContractZone.ResponseCollectors prepareCollectorResponse() {
		WSGetContractZone.ResponseCollectors response = new WSGetContractZone.ResponseCollectors();
		WSGetContractZone.Collector responseCollector = new WSGetContractZone.Collector();

		responseCollector.CodigoSAP = aCollector.Codigo_Sap__c;
		responseCollector.CodigoZona = 'B49001';
		responseCollector.EmpresaCobranza = 'EMME';
		responseCollector.LocalidadCabecera = 'Lomas de Zamora';
		responseCollector.NombreCobrador = 'K2';
		responseCollector.NombreDepartamento = 'LOMAS DE ZAMORA';
		responseCollector.NombreProvincia = 'BUENOS AIRES';
		responseCollector.TipoCobrador = 'Cobrador Común';

		response.CobradoresList = new List<WSGetContractZone.Collector>();
		response.CobradoresList.add(responseCollector);

		return response;
	}

	//==========================================================================
	static Account anAccount;
	static Contact aContact;
	static Contrato__c aContract;
	static Zona__c aZone;
	static Cobrador__c aCollector;
	static WebServiceMock serverMock;
	static Credenciales_Emergencias__c loginSettings;
	static Api_Key_Google_Maps__c googleSettings;

	static {
		serverMock = new WebServiceMock();
		Test.setMock(HttpCalloutMock.class, serverMock);
		loginSettings = Build.someEmergenciesCredentials().build();
		insert loginSettings;
		googleSettings = Build.someGoogleSettings().build();
		insert googleSettings;

		anAccount = Build.anAccount().withBillingLatitude(32.23433).withBillingLongitude(12.2344).withSkipSend(1000).build();
		insert anAccount;
		aContact = Build.aContact().forAccount(anAccount).withSkipSend(1000).build();
		insert aContact;
		aContract = Build.aContract().forAccount(anAccount).withACollectorType().withActiveStatus().withSkipSend(1000).build();
		insert aContract;


		aZone = Build.aZone().withExternalId('potato Zone').withTypeConditionedAccess().build();
		aCollector = Build.aCollector().withSAPCode('v94uy9404').build();
	}
}
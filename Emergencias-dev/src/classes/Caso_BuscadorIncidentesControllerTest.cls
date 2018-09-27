@isTest
private class Caso_BuscadorIncidentesControllerTest {
	private static testMethod void itShouldBePosibleToObtainAResponseFromTheWebService() {
		theWebService.returnBody = '{"value": 1}';
		String entityType = '1';
		String entityNumber = 'V9383042';
		DateTime timeTo = System.now();
		DateTime timeFrom = System.now().addDays(-1);
	
		Test.startTest();
		String resultStr = Caso_BuscadorIncidentesController.SearchIncidents(entityType, entityNumber, timeTo, timeFrom);
		Test.stopTest();
	
		System.assertEquals(theWebService.returnBody, resultStr);
	
		Map<String, Object> requestBody = (Map<String, Object>)JSON.deserializeUntyped(
			theWebService.receivedRequest.getBody()
		);
		System.assertEquals(entityType, (String)requestBody.get('TipoEntidad'));
		System.assertEquals(entityNumber, (String)requestBody.get('NumeroEntidad'));
		System.assertEquals('/Date(' + timeFrom.getTime() + ')/', (String)requestBody.get('InstanteDesde'));
		System.assertEquals('/Date(' + timeTo.getTime() + ')/', (String)requestBody.get('InstanteHasta'));
	
		System.assertEquals(
			'Basic ' + EncodingUtil.base64Encode(blob.valueOf(loginSettings.Usuario__c + ':' + loginSettings.Contrasena__c)),
			theWebService.receivedRequest.getHeader('authorization')
		);
		System.assertEquals('application/json', theWebService.receivedRequest.getHeader('Content-Type'));
		System.assertEquals(
			loginSettings.Host__c + loginSettings.Path_incidentes__c,
			theWebService.receivedRequest.getEndpoint()
		);
	}
	
	private static testMethod void itShouldBePosibleToSaveIncidentsFromAJSONToACase() {
		List<Incidente__c> incidents = new List<Incidente__c> {
			Build.anIncident().withEntityNumber('afg28ry93u').build(),
			Build.anIncident().withEntityNumber('br44id4493').build(),
			Build.anIncident().withEntityNumber('c5fp5ohotu').build()
		};
	
		Caso_BuscadorIncidentesController.saveIncidents(JSON.serialize(incidents), aCase.Id);
	
		List<Incidente__c> savedIncidents = [
			SELECT Id, Numero_de_Entidad__c
			FROM Incidente__c
			ORDER BY Numero_de_Entidad__c ASC
		];
	
		System.assertEquals(incidents.size(), savedIncidents.size());
		for(Integer i = 0; i < savedIncidents.size(); i++) {
			System.assertEquals(incidents[i].Numero_de_Entidad__c, savedIncidents[i].Numero_de_Entidad__c);
		}
	}
	
	private static testMethod void itShouldBePosibleToGetTheIncidentsForACase() {
		List<Incidente__c> incidents = new List<Incidente__c> {
			Build.anIncident().withEntityNumber('afg28ry93u').forCase(aCase).build(),
			Build.anIncident().withEntityNumber('br44id4493').forCase(aCase).build(),
			Build.anIncident().withEntityNumber('c5fp5ohotu').forCase(aCase).build()
		};
		insert incidents;
		Set<Id> incidentIds = new Set<Id>();
		for(Incidente__c incident : incidents) {
			incidentIds.add(incident.Id);
		}
	
		List<Incidente__c> result = Caso_BuscadorIncidentesController.getSavedIncidents(aCase.Id);
	
		System.assertEquals(incidents.size(), result.size());
		for(Incidente__c incident : result) {
			System.assert(incidentIds.contains(incident.Id));
		}
	}
	//==========================================================================
	static WebServiceMock theWebService;
	static Credenciales_Emergencias__c loginSettings;
	static Case aCase;
	static Account anAccount;
	
	static {
		theWebService = new WebServiceMock();
		Test.setMock(HttpCalloutMock.class, theWebService);
	
		anAccount = Build.anAccount().build();
		insert anAccount;
	
		aCase = Build.aCase().forAccount(anAccount).build();
		insert aCase;
		// theWebService.returnBody =
		// 	'{"RCDServiceList":['
		// 		+ '{"Clasificacion":"AMARILLO",'
		// 		+ '"Estado":"En Curso",'
		// 		+ '"Instante":"\/Date(1484847161000-0300)\/",'
		// 		+ '"NomPaciente":"Filomeni Marcelo",'
		// 		+ '"NumEntidad":"H749068\/001",'
		// 		+ '"NumServicio":"09096487"}'
		// 	+']}';
		
		loginSettings = Build.someEmergenciesCredentials().build();
		insert loginSettings;
	}
}
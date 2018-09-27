public class Caso_BuscadorIncidentesController {
	@AuraEnabled
	public static String SearchIncidents(String entityType, String entityNumber, DateTime timeTo, DateTime timeFrom) {
		Credenciales_Emergencias__c login = Credenciales_Emergencias__c.getInstance();
		String auth = EncodingUtil.base64Encode(
			blob.valueOf(
				login.Usuario__c + ':' + login.Contrasena__c
			)
		);

		Map<String, String> body = new Map<String, String> {
			'TipoEntidad' => entityType,
			'NumeroEntidad' => entityNumber
		};
		if(timeTo != null) {
			body.put('InstanteHasta', '/Date(' + timeTo.getTime() + ')/');
		}
		if(timeFrom != null) {
			body.put('InstanteDesde', '/Date(' + timeFrom.getTime() + ')/');
		}

		Http http = new Http();
		HttpRequest request = new HttpRequest();
		request.setEndpoint(
			login.Host__c + login.Path_incidentes__c
		);
		request.setMethod('POST');
		request.setHeader('authorization', 'Basic ' + auth);
		request.setHeader('Content-Type', 'application/json');
		request.setBody(JSON.serialize(body));
        request.setTimeout(120000);
		HttpResponse response = http.send(request);

		if (response.getStatusCode() != 200) {
			return 'Error: ' + response.getStatusCode();
		}
		return response.getBody();
	}

	@AuraEnabled
	public static void saveIncidents(String incidentsJSON, Id caseId) {
		List<Incidente__c> incidents = (List<Incidente__c>)JSON.deserialize(incidentsJSON, List<Incidente__c>.class);
		for(Incidente__c i : incidents) {
			i.Caso__c = caseId;
		}

		insert incidents;
	}

	@AuraEnabled
	public static List<Incidente__c> getSavedIncidents(Id caseId) {
		return [
			SELECT Id, Clasificacion__c, Estado__c, Instante__c, Detalles__c,
				Nombre_de_Paciente__c, Numero_de_Entidad__c, Numero_de_Servicio__c
			FROM Incidente__c
			WHERE Caso__c = :caseId
		];
	}

	public static String[] obtenerClavesDeSistemaDeClienteAsociado(Id idCaso) {
		String[] clavesSistema = new String[]{};
		Case caso = [
			SELECT id,
					Contrato__r.Clave_Sistema_Contrato__c,
					AccountId
			 FROM Case
			 WHERE id = :idCaso
			 LIMIT 1
		];

		Boolean tieneClaveContrato = caso.Contrato__r.Clave_Sistema_Contrato__c != null;
		if(tieneClaveContrato) {
			clavesSistema.add(caso.Contrato__r.Clave_Sistema_Contrato__c);
			return clavesSistema;
		}
		Boolean tieneCuenta = caso.AccountId != null;
		if(!tieneCuenta) return clavesSistema;

		Id idClient = caso.AccountId;
		return Vista360Controller.obtenerClavesDeSistemaDeCliente(idClient);
	}


}
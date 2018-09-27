public class WSIncidente {
	public static String searchIncidents(String[] keys, DateTime dateFrom, DateTime dateTo) {
		if (keys == null || keys.isEmpty()) {
			return null;
		}

		Credenciales_Emergencias__c login = Credenciales_Emergencias__c.getInstance();
		String auth = EncodingUtil.base64Encode(
			blob.valueOf(
				login.Usuario__c + ':' + login.Contrasena__c
			)
		);

		Http http = new Http();
		HttpRequest request = new HttpRequest();
		request.setEndpoint(
			login.Host__c + login.Path_incidentes__c
		);
		request.setMethod('POST');
		request.setHeader('authorization', 'Basic ' + auth);
		request.setHeader('Content-Type', 'application/json');
		request.setBody(JSON.serialize(new WSIncidenteRequest(keys, dateFrom, dateTo)));
		System.debug('request: ' + request.getBody());
        request.setTimeout(120000);
		HttpResponse response = http.send(request);
		System.debug('response: ' + response);
		if (response.getStatusCode() != 200) {
			return 'Error: ' + response.getStatusCode();
		}
		return response.getBody();
	}

	public class WSIncidenteRequest {
		public String[] ListaClaveSistema {get; set;}
		public String  InstanteDesde {get; set;}
		public String  InstanteHasta {get; set;}

		public WSIncidenteRequest(String[] keys, DateTime dateFrom, DateTime dateTo) {
			ListaClaveSistema = keys;
			InstanteDesde = '/Date('+String.valueOf(dateFrom.getTime())+'-0300)/';
			InstanteHasta = '/Date('+String.valueOf(dateTo.getTime())+'-0300)/';
		}
	}
}
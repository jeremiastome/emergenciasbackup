public class WSGetContractZone implements Queueable, Database.AllowsCallouts {
	public static integer RESULT_OK = 0;
	public static integer RESULT_OK_NO_DATA = -1;
	public static integer RESULT_POSITION_ERROR = 1;
	public static integer RESULT_NO_ZONE_ERROR = 2;

	private static integer ZONE_SERVICE = 0;
	private static integer COLLECTOR_SERVICE = 1;

	Id contractId;

	public WSGetContractZone(Id contractId) {
		this.contractId = contractId;
	}

	public void execute(QueueableContext context) {
        getContractZoneData(contractId);
    }

	public static void getContractZoneData(Id contractId) {

		Contrato__c con = [
			SELECT Id, Tipo_de_Cobrador__c,
				Contacto_Cobranza__r.MailingLatitude, Contacto_Cobranza__r.MailingLongitude,
				Cliente__r.BillingLatitude, Cliente__r.BillingLongitude, Cliente__r.BillingStreet,
				Cliente__r.BillingCity, Cliente__r.BillingCountry
			FROM Contrato__c
			WHERE Id = :contractId
		];

		Position pos;
		if(con.Contacto_Cobranza__r != null) {
			pos = new Position(
				con.Contacto_Cobranza__r.MailingLatitude,
				con.Contacto_Cobranza__r.MailingLongitude
			);
		}
		else {
			pos = getAccountPosition(con.Cliente__r);
		}

		if(pos == null) {
			System.debug('Error: No se pudo obtener posicion para el contrato.');
			return;
		}
		else {
			pos.CodTipoCobrador = con.Tipo_de_Cobrador__c;
		}
        System.debug ('Con cobrador: '+pos);
		ResponseCollectors collectorResponse ;

		collectorResponse = callCollectorsService(pos);

		Contrato__c conToUpdate = new Contrato__c();
        conToUpdate.Id = con.Id;
        System.debug(collectorResponse);

		conToUpdate.Zona__c = obtainZoneId(collectorResponse);
		conToUpdate.Zona_automatica__c = conToUpdate.Zona__c;

        Cobrador__c collector;
		if(collectorResponse != null &&
           !collectorResponse.CobradoresList.isEmpty()  )  {

            if( !String.isBlank( collectorResponse.CobradoresList[0].getCollector().Codigo_Sap__c) ) {
				collector = collectorResponse.CobradoresList[0].getCollector();
            }
        }

        if(collector==null) {
            String codTipoCobrador = (pos.CodTipoCobrador=='CobComun' ? 'SR1' : 'SR2' );
            System.debug(codTipoCobrador);
            collector = [SELECT Id
                         FROM Cobrador__c
                         WHERE Name=:codTipoCobrador][0];

        } else {
        	upsert collector Codigo_Sap__c;
        }

		conToUpdate.Cobrador__c = collector.Id;

		update conToUpdate;
	}

	public static integer getAccountZoneData(Id accountId) {
		Account acc = [
			SELECT Id, BillingLatitude, BillingLongitude, BillingStreet,
				BillingCity, BillingCountry
			FROM Account
			WHERE Id = :accountId
		];

		Position pos = getAccountPosition(acc);
		if(pos == null) {
			System.debug('Error: no se pudo obtener la posicion de la cuenta ' + acc.Id);
			return RESULT_POSITION_ERROR;
		}

		ResponseZoneService zoneResponse = callZoneService(pos);
		if(zoneResponse != null) {
			Account accToUpdate = new Account(Id = acc.Id);
			accToUpdate.Zona_de_facturacion__c = obtainZoneId(zoneResponse);
			if(String.isBlank(accToUpdate.Zona_de_facturacion__c)) {
				return RESULT_OK_NO_DATA;
			}
			else {
				update accToUpdate;
				return RESULT_OK;
			}
		}
		else {
			System.debug('Error: no se pudo obtener datos de zona para la cuenta ' + acc.Id);
			return RESULT_NO_ZONE_ERROR;
		}
	}

	public static ResponseZoneService callZoneService(Position pos) {
		HttpRequest request = prepareRequest(ZONE_SERVICE);
		request.setBody(JSON.serialize(pos));
		Http http = new Http();
		HttpResponse response = http.send(request);

		if (response.getStatusCode() != 200) {
			System.debug('Error: ' + response.getStatusCode());
			return null;
		}
		try {
			return (ResponseZoneService)JSON.deserialize(response.getBody(), ResponseZoneService.class);
		}
		catch (Exception e) {
			System.debug('Error malformed response: ' + response.getBody());
			return null;
		}
	}

	public static ResponseCollectors callCollectorsService(Position pos) {
		HttpRequest request = prepareRequest(COLLECTOR_SERVICE);

		request.setBody(JSON.serialize(pos));
		Http http = new Http();
		HttpResponse response = http.send(request);

		if (response.getStatusCode() != 200) {
			System.debug('Error: ' + response.getStatusCode());
			return null;
		}
		try {
			return (ResponseCollectors)JSON.deserialize(response.getBody(), ResponseCollectors.class);
		}
		catch (Exception e) {
			System.debug('Error malformed response: ' + response.getBody());
			return null;
		}
	}

	public static void getLocationsFromGoogle(String address, Integer size) {
		for(Integer i = 0; i < 100; i++) {
			System.debug(size+ '  ' +i);
			getLocationFromGoogle(address);
		}
		getLocationsFromGoogle(address, size - 1);
	}

	public static Position getLocationFromGoogle(String address) {
		Api_Key_Google_Maps__c gSettings = Api_Key_Google_Maps__c.getInstance();
		HttpRequest request = new HttpRequest();
		request.setEndpoint(
			'https://maps.googleapis.com/maps/api/geocode/json?address='
				+ EncodingUtil.urlEncode(address, 'UTF-8')
				+ '&key=' + gSettings.Key__c
		);
		request.setMethod('GET');

		Http http = new Http();
		HttpResponse response = http.send(request);
		System.debug('*** response : ' + response);
		if(response.getStatusCode() == 200) {
			GoogleGeoResponse gRes = (GoogleGeoResponse)JSON.deserialize(response.getBody(), GoogleGeoResponse.class);
			if(gRes.status == 'OK') {
				GoogleLocation loc = gRes.results[0].geometry.location;
				System.debug('*** Loc : ' + loc);
				return new Position(loc.lat, loc.lng);
			}
			else {
				System.debug('Error: google response: ' + response.getBody());
			}
		}
		else {
			System.debug('Error: Codigo de estado ' + response.getStatusCode() + ' recibido desde Google');
		}
		return null;
	}

	private static HttpRequest prepareRequest(integer service) {
		Credenciales_Emergencias__c login = Credenciales_Emergencias__c.getInstance();
		String auth = EncodingUtil.base64Encode(
			blob.valueOf(
				login.Usuario__c + ':' + login.Contrasena__c
			)
		);

		HttpRequest request = new HttpRequest();
		System.debug('*** Prepare request 2: ' +service +'  '+ ZONE_SERVICE);
		if(service == ZONE_SERVICE) {
			request.setEndpoint(
				login.Host__c + login.Path_zona_condicionada__c
			);
		}
		else {//service == COLLECTOR_SERVICE
			request.setEndpoint(
				login.Host__c + login.Path_cobradores__c
			);
		}

		request.setMethod('POST');
		request.setHeader('authorization', 'Basic ' + auth);
		request.setHeader('Content-Type', 'application/json');

		return request;
	}

	public static Position getAccountPosition(Account acc) {
		Position pos;
		if(acc.BillingLatitude != null) {
			pos = new Position(
				acc.BillingLatitude,
				acc.BillingLongitude
			);
		}
		else {
			String locationString = acc.BillingStreet + ', ' + acc.BillingCity + ', ' + acc.BillingCountry;
			pos = getLocationFromGoogle(locationString);
		}

		return pos;
	}

	private static Id obtainZoneId(ResponseZoneService zoneResponse) {
		Zona__c zone = zoneResponse.getZone();
		System.debug('*** Zone: ' + zone);
		if(!String.isBlank(zone.ID_Externo__c)) {
            System.debug(zone.ID_Externo__c);
			upsert zone ID_Externo__c;
		}
        return zone.Id;
    }

	private static Id obtainZoneId(ResponseCollectors collectorsResponse) {
		Zona__c zone = collectorsResponse.getZone();
		if(!String.isBlank(zone.ID_Externo__c)) {
            System.debug(zone.ID_Externo__c);
			upsert zone ID_Externo__c;
		}
        return zone.Id;
    }

	public class Position {
		public decimal Latitud;
		public decimal Longitud;
		public String CodTipoCobrador;

		public Position(decimal lat, decimal lon) {
			Latitud = lat;
			Longitud = lon;
		}

		public Position(decimal lat, decimal lon, String ctc) {
			Latitud = lat;
			Longitud = lon;
			CodTipoCobrador = ctc;
		}
	}

	public class ResponseZoneService {
		public String CodigoZona;
		public boolean AccesoCondicionado;

		public Zona__c getZone() {
			return new Zona__c(
                Name = CodigoZona,
				ID_Externo__c = CodigoZona,
				Tipo__c = AccesoCondicionado?'Acceso condicionado':'Cobrador'
			);
		}
	}

	public class ResponseCollectors {
		public Zona__c getZone() {
		if (CobradoresList!=null&&CobradoresList.size()>0)
			return new Zona__c(
                Name = CobradoresList[0].CodigoZona,
				ID_Externo__c = CobradoresList[0].CodigoZona,
				Tipo__c = 'Cobrador'
			);
			else
				return new Zona__c(
					Name = 'S08400',
					ID_Externo__c = 'S08400',
					Tipo__c = 'Cobrador'
				);
		}
		public List<Collector> CobradoresList;
	}

	public class Collector {
		public String CodigoSAP;

		public String CodigoZona;
		public String EmpresaCobranza;
		public String LocalidadCabecera;
		public String NombreCobrador;
		public String NombreDepartamento;
		public String NombreProvincia;
		public String TipoCobrador;

		public Cobrador__c getCollector() {
			return new Cobrador__c(
				Codigo_Sap__c = CodigoSAP
				//TODO
			);
		}
	}

	public class GoogleGeoResponse {
		public String status;
		public List<GoogleResult> results;
	}

	public class GoogleResult {
		public GoogleGeometry geometry;
	}

	public class GoogleGeometry {
		public GoogleLocation location;
	}

	public class GoogleLocation {
		public decimal lat;
		public decimal lng;
	}
}
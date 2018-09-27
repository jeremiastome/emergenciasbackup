public class WSAccountToSAP {
	public static void sendAccountToSAP(Id accId, String operationType) {
		HttpRequest request = prepareRequest();
		if (request == null) {
			return;
		}

		Http http = new Http();
		SAPClient client = prepareAccount(accId);
		request.setBody(PrepareXML.accountToSap(client, operationType));

		System.debug('XML incoming:');
		System.debug(request.getBody());

		Account accToUpdate = new Account();
		accToUpdate.Id = accId;
		accToUpdate.Request_SF__c = request.getBody();
		accToUpdate.Saltear_envio__c = 2;

		try {
			HttpResponse response = http.send(request);

			if (response.getStatusCode() != 200) {
				System.debug('Error: ' + response.getStatusCode());
				System.debug('Error: Cuenta fallo al ser enviada a sap con Id ' + accId);
				accToUpdate.Estado_de_Envio_a_SAP__c = 'Fallo de comunicacion';
			}
			System.debug('Result: ' + response.getBody());
			accToUpdate.Status_Envio__c = response.getStatusCode().format();
			accToUpdate.Response_SAP__c = response.getBody();
			String description = accToUpdate.Response_SAP__c;

			integer index = description.IndexOf('<Descripcion>') + 13;
			integer last = description.IndexOf('</Descripcion>');

			if (index!=-1 && last!=-1) {
				accToUpdate.Descripcion_de_respuesta_de_SAP__c = description.subString(index, last);
			}


			if (operationType == 'A' && accToUpdate.Estado__c != 'Activo') {
				accToUpdate.Estado__c = 'Activo';
                accToUpdate.Dado_de_alta__c=true;
			}

			if (response.getBody().contains('<Tipo>S</Tipo>')) {
				accToUpdate.Estado_de_Envio_a_SAP__c = 'Ok';
			}
			else {
				accToUpdate.Estado_de_Envio_a_SAP__c = 'Error en el impacto a SAP';
			}
		}
		catch(Exception ex) {
			accToUpdate.Status_Envio__c = '-1';
			accToUpdate.Response_SAP__c = 'Exception: ' + ex.getMessage();
			accToUpdate.Estado_de_Envio_a_SAP__c = 'Error de comunicacion';
			accToUpdate.Descripcion_de_respuesta_de_SAP__c = accToUpdate.Response_SAP__c;
		}
		update accToUpdate;
	}

	public static void sendContactToSAP(Id conId, String operationType) {
		HttpRequest request = prepareRequest();
		if (request == null) {
			return;
		}

		Http http = new Http();
		SAPClient client = prepareContact(conId);
		request.setBody(PrepareXML.accountToSap(client, operationType));

		System.debug('XML incoming:');
		System.debug(request.getBody());

		Contact conToUpdate = new Contact();
		conToUpdate.Id = conId;
		conToUpdate.Request_SF__c = request.getBody();
		conToUpdate.Saltear_envio__c = 2;

		try {
			HttpResponse response = http.send(request);

			if (response.getStatusCode() != 200) {
				System.debug('Error: ' + response.getStatusCode());
				System.debug('Error: Contacto fallo al ser enviada a sap con Id ' + conId);
			}
			System.debug('Result: ' + response.getBody());
			conToUpdate.Status_Envio__c = response.getStatusCode().format();
			conToUpdate.Response_SAP__c = response.getBody();
			String description = conToUpdate.Response_SAP__c;

			integer index = description.IndexOf('<Descripcion>') + 13;
			integer last = description.IndexOf('</Descripcion>');

			if (index!=-1 && last!=-1) {
				conToUpdate.Descripcion_de_respuesta_de_SAP__c = description.subString(index, last);
			}


			Contact theContact = [
			                      SELECT Id, AccountId, Account.Dado_de_alta__c
			                      FROM Contact
			                      WHERE Id = :conId
			                     ];

			if (theContact.Account.Dado_de_alta__c) {
				AccountTriggerHelper.sendAccountToSAP(theContact.AccountId, 'M');
			}
		}
		catch(Exception ex) {
			conToUpdate.Status_Envio__c = '-1';
			conToUpdate.Response_SAP__c = 'Exception: ' + ex.getMessage();
			conToUpdate.Descripcion_de_respuesta_de_SAP__c = conToUpdate.Response_SAP__c;
		}
		update conToUpdate;
	}

	private static HttpRequest prepareRequest() {
		Configuracion_SAP__c sapSettings = Configuracion_SAP__c.getInstance();
		if (String.isBlank(sapSettings.Url__c)) {
			return null;
		}
		String auth = EncodingUtil.base64Encode(
		  blob.valueOf(
				sapSettings.Usuario__c + ':' + sapSettings.Contrasena__c
			)
		);

		String url = sapSettings.Url__c
			+ '?senderParty='
			+ '&senderService=BC_SF'
			+ '&receiverParty='
			+ '&receiverService='
			+ '&interface=SI_ABM_Clientes_Request'
			+ '&interfaceNamespace=urn:ABM_Clientes';


		HttpRequest request = new HttpRequest();
		request.setTimeout(120000);
		request.setEndpoint(url);
		request.setMethod('POST');
		request.setHeader('authorization', 'Basic ' + auth);
		request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
		request.setHeader('SOAPAction', '"http://sap.com/xi/WebService/soap1.1"');

		return request;
	}

	private static SAPClient prepareAccount(Id accId) {
		Account acc = [
			SELECT Id, N_mero_nico_de_Cliente__c, Salutation, FirstName, LastName, Nombre_de_Fantasia__c, Organizacion_de_Ventas__c,
				BillingStreet, BillingCity, BillingPostalCode, BillingCountry, BillingState, Name, Sociedad__c, Piso_depto__c, Depto__c, piso__c,
				Phone, Fax_alternativo__c, PersonEmail, CUIL_CUIT__c, Condicion_IVA__c, Canal_de_Distribucion__c,
				Tipo_NIF__c, IsPersonAccount, Estado__c, Correo_Electronico__c, Status_Envio__c, Request_SF__c, Response_SAP__c, 
				(
					SELECT Id, Codigo_SAP_contacto__c
					FROM Contacts
				), (
					SELECT Id, Contact.Codigo_SAP_contacto__c
					FROM AccountContactRelations
					WHERE IsActive = true
				)
			FROM Account
			WHERE Id = :accId
			//ALL ROWS
		];

        System.debug(acc.Contacts);
        System.debug(acc.AccountContactRelations);
        
		SAPClient result = new SAPClient();
		result.uniqueNumber = acc.N_mero_nico_de_Cliente__c;
		if (acc.IsPersonAccount) {
			result.salutation = acc.Salutation;
			result.firstName = acc.FirstName;
			result.lastName = acc.LastName;
			result.isFisicalPerson = 'True';
		}
		else {
			result.salutation = '0003';
			result.firstName = acc.Name;
			result.alias = acc.Nombre_de_Fantasia__c;
			result.isFisicalPerson = 'False';
		}
		//if (acc.BillingStreet != null) {
			//result.setStreetAndNumber(acc.BillingStreet);
		//}
		// Now we have to send the full street and number in the street name
		
		String billingStreet = acc.BillingStreet;

		if (billingStreet != null && billingStreet.length() > 0) { 
			for (integer i=1 ; i<=billingStreet.length() ; i++ ) {
				if (billingStreet.substring(i-1, i)==' ' 
				 && billingStreet.subString(0, i-1).isNumeric() 
				 && !billingStreet.subString(billingStreet.length()-1, billingStreet.length()).isNumeric()  ) {
             
					billingStreet = billingStreet.subString(i, billingStreet.length()) +' '+
	                				billingStreet.subString(0, i-1);
				}
			}
		} 

		result.streetName = billingStreet;

		result.streetNumber = '';
		if (String.isNotBlank(acc.Piso__c))
		{
			result.floor = acc.Piso__c;
			result.dpto = acc.Depto__c;			
		}
		else
		{
			result.floor = acc.Piso_Depto__c;
		}

		result.city = acc.BillingCity;
		result.postalCode = acc.BillingPostalCode;
		result.country = acc.BillingCountry;
		result.state = acc.BillingState;
		result.phone = acc.Phone;
		result.fax = acc.Fax_alternativo__c;
		result.email = acc.Correo_Electronico__c;
		result.nif1 = acc.CUIL_CUIT__c.replace('-', '');
		result.nif1Type = acc.Tipo_NIF__c;
		result.taxClass = acc.Condicion_IVA__c;
		result.salesOrg = acc.Organizacion_de_Ventas__c;
		result.clientSoc = acc.Sociedad__c;
		result.distChannel = acc.Canal_de_Distribucion__c;
        

		for (AccountContactRelation acr : acc.AccountContactRelations) {
			SAPContactRelation rel = new SAPContactRelation();
            System.debug(acr.Contact);
			rel.sapId = acr.Contact.Codigo_SAP_contacto__c;

			result.sapContacts.add(rel);
		}

		return result;
	}

	private static SAPClient prepareContact(Id conId) {
		Contact acc = [
		  SELECT Id, Salutation, FirstName, LastName, MailingStreet, MailingCity, Piso_depto__c,
		  MailingPostalCode, MailingCountry, MailingState, Codigo_SAP_contacto__c
		  , condicion_de_IVA__c, Depto__c, Piso__c,
		  /*Account.Organizacion_de_Ventas__c*/Organizacion_de_Ventas__c,Tipo_Nif__c
		  FROM Contact
		  WHERE Id = :conId
		  //ALL ROWS
		];

		SAPClient result = new SAPClient();
		result.uniqueNumber = acc.Codigo_SAP_contacto__c;
		result.salutation = acc.Salutation;
		result.firstName = acc.FirstName;
		result.lastName = acc.LastName;
		result.nif1Type = acc.Tipo_Nif__c;

		//if (acc.MailingStreet != null) {
			//result.setStreetAndNumber(acc.MailingStreet);
		//}
		// Now we have to send the full street and number in the street name

		result.streetName = acc.MailingStreet;
		result.streetNumber = '';
		if (String.isNotBlank(acc.Piso__c))
		{
			result.floor = acc.Piso__c;
			result.dpto = acc.Depto__c;			
		}
		else
		{
			result.floor = acc.Piso_Depto__c;			
		}

		result.city = acc.MailingCity;
		result.postalCode = acc.MailingPostalCode;
		result.country = acc.MailingCountry;
		result.state = acc.MailingState;
		result.salesOrg = acc.Organizacion_de_Ventas__c;//acc.Account.Organizacion_de_Ventas__c;
		result.distChannel = '10';//acc.Account.Canal_de_Distribucion__c;
		result.destinatary = 'True';
		result.taxClass = acc.condicion_de_IVA__c;
		return result;
	}

	public class SAPClient {
		public String uniqueNumber = '';
		public String salutation = '';
		public String postalCode = '';
		public String country = '';
		public String state = '';
		public String phone = '';
		public String fax = '';
		public String email = '';
		public String nif1 = '';
		public String nif1Type = '';
		public String taxClass = '';
		public String isFisicalPerson = '';
		public String salesOrg = '';
		public String clientSoc = '';
		public String distChannel = '';
		public String destinatary = '';
		public String floor = '';
		public String dpto = '';

		public String streetNumber {
			get {
				if (streetNumber != null) {
					return streetNumber.toUpperCase();
				}
				else {
					return '';
				}
			}
			set;
		}

		public String firstName {
			get {
				if (firstName != null) {
					return firstName.toUpperCase();
				}
				else {
					return '';
				}
			}
			set;
		}
		public String lastName {
			get {
				if (lastName != null) {
					return lastName.toUpperCase();
				}
				else {
					return '';
				}
			}
			set;
		}
		public String streetName {
			get {
				if (streetName != null) {
					return streetName.toUpperCase();
				}
				else {
					return '';
				}
			}
			set;
		}
		public String city {
			get {
				if (city != null) {
					return city.toUpperCase();
				}
				else {
					return '';
				}
			}
			set;
		}
		public String alias {
			get {
				if (alias != null) {
					return alias.toUpperCase();
				}
				else {
					return '';
				}
			}
			set;
		}

		public List<SAPContactRelation> sapContacts = new List<SAPContactRelation> ();

		public void setStreetAndNumber(String address) {
			Pattern addressPattern = Pattern.compile('(^([0-9]+) (.+)$)|(^(.+) ([0-9]+)$)');
			Matcher addressMatch = addressPattern.matcher(address);
			if (addressMatch.matches() && addressMatch.hitEnd()) {
				if (addressMatch.group(1) != null) {
					streetName = addressMatch.group(3);
					streetNumber = addressMatch.group(2);
				}
				else {
					streetName = addressMatch.group(5);
					streetNumber = addressMatch.group(6);
				}
			}
			else {
				streetName = address;
			}
		}
	}

	public class SAPContactRelation {
		public String sapId = '';
		public String paymentCondition = '';
	}
}
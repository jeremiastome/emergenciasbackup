@isTest
private class WSAccountToSAPTest {
	//=====================================
	// Accounts
	//=====================================
	private static testMethod void itShouldBePosibleToSendTheDataOfaPersonAccountToSAP() {
		serverMock.returnBody = generateResponse();
		String operationType = 'M';
		Test.startTest();
		WSAccountToSAP.sendAccountToSAP(aPersonAccount.Id, operationType);
		Test.stopTest();
		
		aPersonAccount = [
			SELECT Id, N_mero_nico_de_Cliente__c, Salutation, FirstName, LastName,
				BillingStreet, BillingCity, BillingPostalCode, BillingCountry, BillingState, Piso_Depto__c,
				Phone, Fax_alternativo__c, PersonEmail, CUIL_CUIT__c,
				Tipo_NIF__c, IsPersonAccount, Estado__c, Correo_Electronico__c,
				Organizacion_de_Ventas__c, Canal_de_Distribucion__c
			FROM Account
			WHERE Id = :aPersonAccount.Id
		];
		
		System.assertEquals(sapSettings.Url__c, serverMock.receivedRequest.getEndpoint().split('\\?')[0]);
		String expectedParameters = 'senderParty='
		+ '&senderService=BC_SF'
		+ '&receiverParty='
		+ '&receiverService='
		+ '&interface=SI_ABM_Clientes_Request'
		+ '&interfaceNamespace=urn:ABM_Clientes';
		System.assertEquals(expectedParameters, serverMock.receivedRequest.getEndpoint().split('\\?')[1]);
		
		String requestBody = serverMock.receivedRequest.getBody();
		Map<String, Object> requestData = xmlToMap(requestBody);
		
		System.assert(requestData.containsKey('Envelope'), requestData.keySet());
		Map<String, Object> soapEnvelope = (Map<String, Object>)requestData.get('Envelope');
		
		System.assert(soapEnvelope.containsKey('Header'), soapEnvelope.keySet());
		System.assert(soapEnvelope.containsKey('Body'), soapEnvelope.keySet());
		Map<String, Object> soapBody = (Map<String, Object>)soapEnvelope.get('Body');
		
		System.assert(soapBody.containsKey('MT_ABM_Clientes_Request_Out'), soapBody.keySet());
		Map<String, Object> accountData = (Map<String, Object>)soapBody.get('MT_ABM_Clientes_Request_Out');
		
		System.assert(accountData.containsKey('TipoOperacion'));
		System.assertEquals(operationType, (String)accountData.get('TipoOperacion'));
		
		System.assert(accountData.containsKey('GeneralesCliente'));
		Map<String, Object> clientGeneralData = (Map<String, Object>)accountData.get('GeneralesCliente');
		
		System.assert(clientGeneralData.containsKey('Cliente'));
		System.assertEquals(aPersonAccount.N_mero_nico_de_Cliente__c, (String)clientGeneralData.get('Cliente'));
		
		System.assert(clientGeneralData.containsKey('Tratamiento'));
		System.assertEquals(aPersonAccount.Salutation, (String)clientGeneralData.get('Tratamiento'));
		
		System.assert(clientGeneralData.containsKey('Nombre'));
		System.assertEquals(aPersonAccount.FirstName.toUpperCase(), (String)clientGeneralData.get('Nombre'));
		
		System.assert(clientGeneralData.containsKey('Apellido'));
		System.assertEquals(aPersonAccount.LastName.toUpperCase(), (String)clientGeneralData.get('Apellido'));
		
		System.assert(clientGeneralData.containsKey('Calle'));
		System.assertEquals('TEST ST. 1234', (String)clientGeneralData.get('Calle'));
		
		System.assert(clientGeneralData.containsKey('Piso'));
		System.assertEquals(aPersonAccount.Piso_depto__c, (String)clientGeneralData.get('Piso'));

		System.assert(clientGeneralData.containsKey('Poblacion'));
		System.assertEquals(aPersonAccount.BillingCity.toUpperCase(), (String)clientGeneralData.get('Poblacion'));
		
		System.assert(clientGeneralData.containsKey('CodigoPostal'));
		System.assertEquals(aPersonAccount.BillingPostalCode, (String)clientGeneralData.get('CodigoPostal'));
		
		System.assert(clientGeneralData.containsKey('Pais'));
		System.assert(clientGeneralData.containsKey('Region'));
		
		System.assert(clientGeneralData.containsKey('Telefono'));
		System.assertEquals(aPersonAccount.Phone, (String)clientGeneralData.get('Telefono'));
		
		System.assert(clientGeneralData.containsKey('Fax'));
		System.assertEquals(aPersonAccount.Fax_alternativo__c, (String)clientGeneralData.get('Fax'));
		
		System.assert(clientGeneralData.containsKey('Email'));
		System.assertEquals(aPersonAccount.Correo_Electronico__c, (String)clientGeneralData.get('Email'));
		
		System.assert(clientGeneralData.containsKey('Nif1'));
		System.assertEquals(aPersonAccount.CUIL_CUIT__c, (String)clientGeneralData.get('Nif1'));
		
		System.assert(clientGeneralData.containsKey('TipoNif1'));
		System.assertEquals(aPersonAccount.Tipo_NIF__c, (String)clientGeneralData.get('TipoNif1'));
		
		System.assert(clientGeneralData.containsKey('PersonaFisica'));
		System.assertEquals('True', (String)clientGeneralData.get('PersonaFisica'));
		
		System.assert(clientGeneralData.containsKey('ImpVolNegocio'));
		
		System.assert(clientGeneralData.containsKey('Bloqueado'));
		System.assertEquals('False', (String)clientGeneralData.get('Bloqueado'));
		
		System.assert(clientGeneralData.containsKey('Busqueda'));
		System.assert(clientGeneralData.containsKey('Empleado'));
		System.assert(clientGeneralData.containsKey('Destinatario'));
		
		//=========================================================
		System.assert(accountData.containsKey('SociedadCliente'));
		Map<String, Object> clientSocietyData = (Map<String, Object>)accountData.get('SociedadCliente');
		
		System.assert(clientSocietyData.containsKey('Sociedad'));
		System.assert(clientSocietyData.containsKey('NroCuentaAnterior'));
		System.assert(clientSocietyData.containsKey('CodigoActividad'));
		
		System.assert(clientSocietyData.containsKey('CondicionDePago'));
		System.assertEquals('C020', clientSocietyData.get('CondicionDePago'));
		
		System.assert(clientSocietyData.containsKey('ViaDePago'));
		System.assertEquals('M', clientSocietyData.get('ViaDePago'));
		
		//=========================================================
		System.assert(accountData.containsKey('VentaClientes'));
		Map<String, Object> clientSaleData = (Map<String, Object>)accountData.get('VentaClientes');
		System.assert(clientSaleData.containsKey('OrganizacionVentas'));
		System.assertEquals(aPersonAccount.Organizacion_de_Ventas__c, clientSaleData.get('OrganizacionVentas'));
		System.assert(clientSaleData.containsKey('CanalDistribucion'));
		System.assertEquals(aPersonAccount.Canal_de_Distribucion__c, clientSaleData.get('CanalDistribucion'));
		System.assert(clientSaleData.containsKey('CondicionPagoFactura'));
		System.assert(clientSaleData.containsKey('Solicitante'));
		System.assert(clientSaleData.containsKey('ResponsableDePago'));
		System.assert(clientSaleData.containsKey('ResponsableDeFactura'));
		System.assert(clientSaleData.containsKey('Destinatario'));
	}
	
	private static testMethod void ifNoSettingsAreFoundTheAccountShouldntBeSent() {
		delete sapSettings;
		serverMock.returnBody = generateResponse();
		
		Test.startTest();
		WSAccountToSAP.sendAccountToSAP(aPersonAccount.Id, 'A');
		Test.stopTest();
		
		System.assertEquals(null, serverMock.receivedRequest);
	}
	
	private static testMethod void ifTheClientsBillingCountryIsArgentinaTheCountryCodeShouldBeReturned() {
		serverMock.returnBody = generateResponse();
		aPersonAccount.BillingCountry = 'Argentina';
		update aPersonAccount;
		Test.startTest();
		WSAccountToSAP.sendAccountToSAP(aPersonAccount.Id, 'A');
		Test.stopTest();
		
		aPersonAccount = [
			SELECT Id, N_mero_nico_de_Cliente__c, Salutation, FirstName, LastName,
				BillingStreet, BillingCity, BillingPostalCode, BillingCountry, BillingState,
				Phone, Fax_alternativo__c, PersonEmail, CUIL_CUIT__c,
				Tipo_NIF__c, IsPersonAccount, Estado__c, Correo_Electronico__c
			FROM Account
			WHERE Id = :aPersonAccount.Id
		];
		
		String requestBody = serverMock.receivedRequest.getBody();
		Map<String, Object> requestData = xmlToMap(requestBody);
		
		Map<String, Object> soapEnvelope = (Map<String, Object>)requestData.get('Envelope');
		Map<String, Object> soapBody = (Map<String, Object>)soapEnvelope.get('Body');
		Map<String, Object> accountData = (Map<String, Object>)soapBody.get('MT_ABM_Clientes_Request_Out');
		Map<String, Object> clientGeneralData = (Map<String, Object>)accountData.get('GeneralesCliente');
		
		System.assertEquals('AR', (String)clientGeneralData.get('Pais'));
	}
	
	/*private static testMethod void theStreetNumberAndStreetShouldBeCorrectlySeparatedWhenTheNumberIsFirst() {
		String street = 'Test st.';
		String streetNumber = '1234';
		serverMock.returnBody = generateResponse();
		aPersonAccount.BillingStreet = streetNumber + ' ' + street;
		update aPersonAccount;
		Test.startTest();
		WSAccountToSAP.sendAccountToSAP(aPersonAccount.Id, 'A');
		Test.stopTest();
		
		aPersonAccount = [
			SELECT Id, N_mero_nico_de_Cliente__c, Salutation, FirstName, LastName,
				BillingStreet, BillingCity, BillingPostalCode, BillingCountry, BillingState,
				Phone, Fax_alternativo__c, PersonEmail, CUIL_CUIT__c,
				Tipo_NIF__c, IsPersonAccount, Estado__c, Correo_Electronico__c
			FROM Account
			WHERE Id = :aPersonAccount.Id
		];
		
		String requestBody = serverMock.receivedRequest.getBody();
		Map<String, Object> requestData = xmlToMap(requestBody);
		Map<String, Object> soapEnvelope = (Map<String, Object>)requestData.get('Envelope');
		Map<String, Object> soapBody = (Map<String, Object>)soapEnvelope.get('Body');
		Map<String, Object> accountData = (Map<String, Object>)soapBody.get('MT_ABM_Clientes_Request_Out');
		Map<String, Object> clientGeneralData = (Map<String, Object>)accountData.get('GeneralesCliente');
		
		System.assertEquals(street.toUpperCase(), (String)clientGeneralData.get('Calle'));
		System.assertEquals(streetNumber, (String)clientGeneralData.get('Altura'));
	}
	
	private static testMethod void theStreetNumberAndStreetShouldBeCorrectlySeparatedWhenTheNumberIsLast() {
		String street = 'Test st.';
		String streetNumber = '1234';
		serverMock.returnBody = generateResponse();
		aPersonAccount.BillingStreet = street + ' ' + streetNumber;
		update aPersonAccount;
		Test.startTest();
		WSAccountToSAP.sendAccountToSAP(aPersonAccount.Id, 'A');
		Test.stopTest();
		
		aPersonAccount = [
			SELECT Id, N_mero_nico_de_Cliente__c, Salutation, FirstName, LastName,
				BillingStreet, BillingCity, BillingPostalCode, BillingCountry, BillingState,
				Phone, Fax_alternativo__c, PersonEmail, CUIL_CUIT__c,
				Tipo_NIF__c, IsPersonAccount, Estado__c, Correo_Electronico__c
			FROM Account
			WHERE Id = :aPersonAccount.Id
		];
		
		String requestBody = serverMock.receivedRequest.getBody();
		Map<String, Object> requestData = xmlToMap(requestBody);
		Map<String, Object> soapEnvelope = (Map<String, Object>)requestData.get('Envelope');
		Map<String, Object> soapBody = (Map<String, Object>)soapEnvelope.get('Body');
		Map<String, Object> accountData = (Map<String, Object>)soapBody.get('MT_ABM_Clientes_Request_Out');
		Map<String, Object> clientGeneralData = (Map<String, Object>)accountData.get('GeneralesCliente');
		
		System.assertEquals(street.toUpperCase(), (String)clientGeneralData.get('Calle'));
		System.assertEquals(streetNumber, (String)clientGeneralData.get('Altura'));
	}*/
	
	private static testMethod void ifTheClientsBillingStateShouldBeSentAsACode() {
		serverMock.returnBody = generateResponse();
		aPersonAccount.BillingState = 'Capital federal';
		update aPersonAccount;
		Test.startTest();
		WSAccountToSAP.sendAccountToSAP(aPersonAccount.Id, 'A');
		Test.stopTest();
		
		aPersonAccount = [
			SELECT Id, N_mero_nico_de_Cliente__c, Salutation, FirstName, LastName,
				BillingStreet, BillingCity, BillingPostalCode, BillingCountry, BillingState,
				Phone, Fax_alternativo__c, PersonEmail, CUIL_CUIT__c,
				Tipo_NIF__c, IsPersonAccount, Estado__c, Correo_Electronico__c
			FROM Account
			WHERE Id = :aPersonAccount.Id
		];
		
		String requestBody = serverMock.receivedRequest.getBody();
		Map<String, Object> requestData = xmlToMap(requestBody);
		Map<String, Object> soapEnvelope = (Map<String, Object>)requestData.get('Envelope');
		Map<String, Object> soapBody = (Map<String, Object>)soapEnvelope.get('Body');
		Map<String, Object> accountData = (Map<String, Object>)soapBody.get('MT_ABM_Clientes_Request_Out');
		Map<String, Object> clientGeneralData = (Map<String, Object>)accountData.get('GeneralesCliente');
		
		System.assertEquals('00', (String)clientGeneralData.get('Region'));
	}
	
	private static testMethod void theUsernameAndPasswordShouldBeSentToTheServer() {
		serverMock.returnBody = generateResponse();
		
		Test.startTest();
		WSAccountToSAP.sendAccountToSAP(aPersonAccount.Id, 'A');
		Test.stopTest();
		String expectedAuthorization = 'Basic ' + EncodingUtil.base64Encode(
			blob.valueOf(
				sapSettings.Usuario__c + ':' + sapSettings.Contrasena__c
			)
		);
		
		System.assertEquals(expectedAuthorization, serverMock.receivedRequest.getHeader('authorization'));
	}
	
	private static testMethod void itShouldBePosibleToLinkRelatedContactsInSAP() {
		serverMock.returnBody = generateResponse();
		
		List<Contact> contacts = new List<Contact>();
		for(Integer i = 0; i < 3; i++) {
			Contact aContact = Build.aContact().forAccount(anAccount).withSkipSend(2).build();
			contacts.add(aContact);
		}
		insert contacts;
		
		Test.startTest();
		WSAccountToSAP.sendAccountToSAP(anAccount.Id, 'A');
		Test.stopTest();
		
		Dom.Document xmlDocument = new Dom.Document();
		xmlDocument.load(serverMock.receivedRequest.getBody());
		Dom.XMLNode accountData = xmlDocument.getRootElement().getChildElements()[1].getChildElements()[0];
		System.assertEquals(4 + contacts.size(), accountData.getChildren().size());
		
		for(Dom.XMLNode node : accountData.getChildren()) {
			if(node.getName() == 'VentaClientes') {
				System.assertNotEquals(null, node.getChildElement('OrganizacionVentas', null));
				System.assertNotEquals(null, node.getChildElement('CanalDistribucion', null));
				System.assertNotEquals(null, node.getChildElement('CondicionPagoFactura', null));
				System.assertNotEquals(null, node.getChildElement('Solicitante', null));
				System.assertNotEquals(null, node.getChildElement('ResponsableDePago', null));
				System.assertNotEquals(null, node.getChildElement('ResponsableDeFactura', null));
				System.assertNotEquals(null, node.getChildElement('Destinatario', null));
			}
		}
	}
	
	private static testMethod void itShouldBePosibleToLinkARelatedContactInSAP() {
		serverMock.returnBody = generateResponse();
		
		Contact aContact = Build.aContact().forAccount(anAccount).withSkipSend(2).build();
		insert aContact;
        
		aContact = [SELECT Id, Codigo_SAP_contacto__c FROM Contact WHERE Id = :aContact.Id];
        
		Test.startTest();
		WSAccountToSAP.sendAccountToSAP(anAccount.Id, 'A');
		Test.stopTest();
        
		Dom.Document xmlDocument = new Dom.Document();
		xmlDocument.load(serverMock.receivedRequest.getBody());
		Dom.XMLNode accountData = xmlDocument.getRootElement().getChildElements()[1].getChildElements()[0];
        System.debug(xmlDocument.getRootElement().getChildElements());
        
		Dom.XMLNode contactData;
		for(Dom.XMLNode node : accountData.getChildren()) {
			if(node.getName() == 'VentaClientes') {
                System.debug(aContact.Codigo_SAP_contacto__c);
                System.debug(node.getChildElement('ResponsableDePago', null).getText());
                
				if(aContact.Codigo_SAP_contacto__c == node.getChildElement('ResponsableDePago', null).getText()) {
					contactData = node;
				}
			}
		}
		
		System.assertEquals(
			aContact.Codigo_SAP_contacto__c, 
			contactData.getChildElement('ResponsableDePago', null).getText()
		);
		System.assertEquals(
			aContact.Codigo_SAP_contacto__c,
			contactData.getChildElement('ResponsableDeFactura', null).getText()
		);
		System.assertEquals(
			aContact.Codigo_SAP_contacto__c,
			contactData.getChildElement('Destinatario', null).getText()
		);
	}
	
	private static testMethod void itShouldBePosibleToSendContactsRelatedToPersonAccounts() {
		serverMock.returnBody = generateResponse();
		Contact aContact = Build.aContact().forAccount(anAccount).withSkipSend(2).build();
		insert aContact;
		aContact = [SELECT Id, Codigo_SAP_contacto__c FROM Contact WHERE Id = :aContact.Id];
		AccountContactRelation anAccountContactRelation = Build.anAccountContactRelation()
			.forAccount(aPersonAccount).forContact(aContact).build();
		insert anAccountContactRelation;
		
		Test.startTest();
		WSAccountToSAP.sendAccountToSAP(aPersonAccount.Id, 'A');
		Test.stopTest();
		
		Dom.Document xmlDocument = new Dom.Document();
		xmlDocument.load(serverMock.receivedRequest.getBody());
		Dom.XMLNode accountData = xmlDocument.getRootElement().getChildElements()[1].getChildElements()[0];
		System.assertEquals(5, accountData.getChildren().size());
		
		boolean foundContactNode = false;
		for(Dom.XMLNode node : accountData.getChildren()) {
			if(node.getName() == 'VentaClientes') {
				if(aContact.Codigo_SAP_contacto__c == node.getChildElement('ResponsableDePago', null).getText()) {
					foundContactNode = true;
				}
			}
		}
		System.assert(foundContactNode, 'The contact wasn\'t sent with the account.');
	}
	//=====================================
	// Contacts
	//=====================================
	private static testMethod void itShouldBePosibleToSendAContactToSAP() {
		anAccount.Dado_de_alta__c = false;
		anAccount.Saltear_envio__c = 2;
		update anAccount;
		
		serverMock.returnBody = generateResponse();
		String operationType = 'A';
		Contact aContact = Build.aContact().forAccount(anAccount).withFirstName('Test')
			.withLastName('Mann').withSalutation('0001').withMailingStreet('Te st. 123')
			.withMailingCountry('Testland').withMailingState('Testbec').withFloorApartment('5th a')
			.withMailingCity('Testopolis').withMailingPostalCode('cp1234a').build();
		insert aContact;
		aContact = [
			SELECT Id, Salutation, FirstName, LastName, MailingStreet, MailingCity, Piso_Depto__c,
				MailingPostalCode, MailingCountry, MailingState, Codigo_SAP_contacto__c,
            /*Account.Organizacion_de_Ventas__c*/Organizacion_de_ventas__c /*,Account.Canal_de_Distribucion__c*/ 
			FROM Contact
			WHERE Id = :aContact.Id
		];
		
		Test.startTest();
		WSAccountToSAP.sendContactToSAP(aContact.Id, operationType);
		Test.stopTest();
		
		String requestBody = serverMock.receivedRequest.getBody();
		Map<String, Object> requestData = xmlToMap(requestBody);
		Map<String, Object> soapEnvelope = (Map<String, Object>)requestData.get('Envelope');
		Map<String, Object> soapBody = (Map<String, Object>)soapEnvelope.get('Body');
		Map<String, Object> contactData = (Map<String, Object>)soapBody.get('MT_ABM_Clientes_Request_Out');
		Map<String, Object> clientGeneralData = (Map<String, Object>)contactData.get('GeneralesCliente');
		
		System.assert(clientGeneralData.containsKey('Cliente'));
		System.assertEquals(aContact.Codigo_SAP_contacto__c, (String)clientGeneralData.get('Cliente'));
		
		System.assert(clientGeneralData.containsKey('Tratamiento'));
		System.assertEquals(aContact.Salutation, (String)clientGeneralData.get('Tratamiento'));
		
		System.assert(clientGeneralData.containsKey('Nombre'));
		System.assertEquals(aContact.FirstName.toUpperCase(), (String)clientGeneralData.get('Nombre'));
		
		System.assert(clientGeneralData.containsKey('Apellido'));
		System.assertEquals(aContact.LastName.toUpperCase(), (String)clientGeneralData.get('Apellido'));
		
		System.assert(clientGeneralData.containsKey('Calle'));
		System.assertEquals(aContact.MailingStreet.toUpperCase(), (String)clientGeneralData.get('Calle'));
		
		System.assert(clientGeneralData.containsKey('Piso'));
		System.assertEquals(aContact.Piso_depto__c, (String)clientGeneralData.get('Piso'));
		
		System.assert(clientGeneralData.containsKey('Poblacion'));
		System.assertEquals(aContact.MailingCity.toUpperCase(), (String)clientGeneralData.get('Poblacion'));
		
		System.assert(clientGeneralData.containsKey('CodigoPostal'));
		System.assertEquals(aContact.MailingPostalCode, (String)clientGeneralData.get('CodigoPostal'));
		
		System.assert(clientGeneralData.containsKey('Pais'));
		System.assert(clientGeneralData.containsKey('Region'));
		
		System.assert(clientGeneralData.containsKey('Destinatario'));
		System.assertEquals('True', (String)clientGeneralData.get('Destinatario'));
		
		System.assert(contactData.containsKey('VentaClientes'));
		Map<String, Object> clientSaleData = (Map<String, Object>)contactData.get('VentaClientes');
		//System.assert(clientSaleData.containsKey('OrganizacionVentas'));
		//System.assertEquals(anAccount.Organizacion_de_Ventas__c, clientSaleData.get('OrganizacionVentas'));
		//System.assert(clientSaleData.containsKey('CanalDistribucion'));
		//System.assertEquals(anAccount.Canal_de_Distribucion__c, clientSaleData.get('CanalDistribucion'));
		System.assertEquals('10', clientSaleData.get('CanalDistribucion'));
	}
    
    
	private static testMethod void itShouldBePosibleToSendAContactToSAPBySenderContactController() {
		
		anAccount.Dado_de_alta__c = false;
		anAccount.Saltear_envio__c = 2;
		update anAccount;
		
		serverMock.returnBody = generateResponse();
		String operationType = 'A';
		Contact aContact = Build.aContact().forAccount(anAccount).withFirstName('Test')
			.withLastName('Mann').withSalutation('0001').withMailingStreet('Te st. 123')
			.withMailingCountry('Testland').withMailingState('Testbec').withFloorApartment('5th a')
			.withMailingCity('Testopolis').withMailingPostalCode('cp1234a').build();
		insert aContact;

		PageReference pageRef = Page.SenderContact;
		pageRef.getParameters().put('id', aContact.id);
		Test.setCurrentPage(pageRef);
		SenderContactController controller = new SenderContactController();

		aContact = [
			SELECT Id, Salutation, FirstName, LastName, MailingStreet, MailingCity, Piso_Depto__c,
				MailingPostalCode, MailingCountry, MailingState, Codigo_SAP_contacto__c,
				Organizacion_de_Ventas__c
			FROM Contact
			WHERE Id = :aContact.Id
		];
		
		Test.startTest();
		controller.send();
		Test.stopTest();
		
		String requestBody = serverMock.receivedRequest.getBody();
		Map<String, Object> requestData = xmlToMap(requestBody);
		Map<String, Object> soapEnvelope = (Map<String, Object>)requestData.get('Envelope');
		Map<String, Object> soapBody = (Map<String, Object>)soapEnvelope.get('Body');
		Map<String, Object> contactData = (Map<String, Object>)soapBody.get('MT_ABM_Clientes_Request_Out');
		Map<String, Object> clientGeneralData = (Map<String, Object>)contactData.get('GeneralesCliente');
		
		System.assert(clientGeneralData.containsKey('Cliente'));
		System.assertEquals(aContact.Codigo_SAP_contacto__c, (String)clientGeneralData.get('Cliente'));
		
		System.assert(clientGeneralData.containsKey('Tratamiento'));
		System.assertEquals(aContact.Salutation, (String)clientGeneralData.get('Tratamiento'));
		
		System.assert(clientGeneralData.containsKey('Nombre'));
		System.assertEquals(aContact.FirstName.toUpperCase(), (String)clientGeneralData.get('Nombre'));
		
		System.assert(clientGeneralData.containsKey('Apellido'));
		System.assertEquals(aContact.LastName.toUpperCase(), (String)clientGeneralData.get('Apellido'));
		
		System.assert(clientGeneralData.containsKey('Calle'));
		System.assertEquals(aContact.MailingStreet.toUpperCase(), (String)clientGeneralData.get('Calle'));
		
		System.assert(clientGeneralData.containsKey('Piso'));
		System.assertEquals(aContact.Piso_depto__c, (String)clientGeneralData.get('Piso'));
		
		System.assert(clientGeneralData.containsKey('Poblacion'));
		System.assertEquals(aContact.MailingCity.toUpperCase(), (String)clientGeneralData.get('Poblacion'));
		
		System.assert(clientGeneralData.containsKey('CodigoPostal'));
		System.assertEquals(aContact.MailingPostalCode, (String)clientGeneralData.get('CodigoPostal'));
		
		System.assert(clientGeneralData.containsKey('Pais'));
		System.assert(clientGeneralData.containsKey('Region'));
		
		System.assert(clientGeneralData.containsKey('Destinatario'));
		System.assertEquals('True', (String)clientGeneralData.get('Destinatario'));
		
		System.assert(contactData.containsKey('VentaClientes'));
		Map<String, Object> clientSaleData = (Map<String, Object>)contactData.get('VentaClientes');
		//System.assert(clientSaleData.containsKey('OrganizacionVentas'));
		//System.assertEquals(anAccount.Organizacion_de_Ventas__c, clientSaleData.get('OrganizacionVentas'));
		System.assert(clientSaleData.containsKey('CanalDistribucion'));
		System.assertEquals('10', clientSaleData.get('CanalDistribucion'));
	}
	
	private static testMethod void afterSendingAContact_IfTheAccountIsEnabledForSAPItShouldBeSent() {
		serverMock.returnBody = generateResponse();
		
		anAccount.Dado_de_alta__c = true;
		anAccount.Status_Envio__c = null;
		anAccount.Saltear_envio__c = 2;
		update anAccount;
		
		Contact aContact = Build.aContact().forAccount(anAccount).withFirstName('Test')
			.withLastName('Mann').withSalutation('0001').withMailingStreet('Te st. 123')
			.withMailingCountry('Testland').withMailingState('Testbec').withSkipSend(2)
			.withMailingCity('Testopolis').withMailingPostalCode('cp1234a').build();
		insert aContact;
		
		Test.startTest();
		WSAccountToSAP.sendContactToSAP(aContact.Id, 'A');
		Test.stopTest();
		
		System.assertEquals(2, serverMock.callsMade);
		
		anAccount = [
			SELECT Id, Status_Envio__c
			FROM Account
			WHERE Id = :anAccount.Id
		];
		
		System.assertNotEquals(null, anAccount.Status_Envio__c);
	}
	
	//TODO test update contact fields
	
	//==========================================================================
	private static String generateResponse() {
		XmlStreamWriter writer = new XmlStreamWriter();
		
		writer.writeStartDocument(null, '1.0');
		writer.writeStartElement(null, 'Respuesta', null);
		//Respuesta
		writer.writeEmptyElement(null, 'Resultado', null);
		writer.writeEmptyElement(null, 'Mensaje', null);
		//End Respuesta
		writer.writeEndElement();
		String xmlOut = writer.getXmlString();
		writer.close();
		return xmlOut;
	}
	
	private static Map<String, Object> xmlToMap(String xmlStr) {
		//Due to the way the sap object is formatted, this can be done.
		Map<String, Object> result = new Map<String, Object>();
		
		XmlStreamReader xmlReader = new XmlStreamReader(xmlStr);
		while(true) {
			if(xmlReader.getEventType() == XmlTag.START_ELEMENT) {
				String tagName = xmlReader.getLocalName();
				result.put(tagName, getTagContents(xmlReader));
			}
			
			if(xmlReader.hasNext()) {
				xmlReader.next();
			}
			else {
				break;
			}
		}
		
		return result;
	}
	
	private static Object getTagContents(XmlStreamReader xmlReader) {
		if(!xmlReader.hasNext()) {
			//Bad formatting
			return null;
		}
		xmlReader.next();
		
		if(xmlReader.getEventType() == XmlTag.CHARACTERS) {
			String result = xmlReader.getText();
			if(!xmlReader.hasNext()) {
				//Bad formatting
				return null;
			}
			xmlReader.next();
			if(xmlReader.getEventType() != XmlTag.END_ELEMENT) {
				//Bad formatting
				return null;
			}
			return result;
		}
		
		Map<String, Object> result = new Map<String, Object>();
		while(true) {
			if(xmlReader.getEventType() == XmlTag.START_ELEMENT) {
				String tagName = xmlReader.getLocalName();
				result.put(tagName, getTagContents(xmlReader));
				if(!xmlReader.hasNext()) {
					//Bad formatting
					return null;
				}
				xmlReader.next();
			}
			
			if(!xmlReader.hasNext()) {
				//Bad formatting
				return null;
			}
			else if(xmlReader.getEventType() == XmlTag.END_ELEMENT) {
				break;
			}
		}
		
		return result;
	}
	//==========================================================================
	static Configuracion_SAP__c sapSettings;
	static WebServiceMock serverMock;
	static Account aPersonAccount;
	static Account anAccount;
	
	static {
		serverMock = new WebServiceMock();
		Test.setMock(HttpCalloutMock.class, serverMock);
		
		sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		
		aPersonAccount = Build.anAccount().isPersonAccount().withFirstName('Test')
			.withSkipSend(20)//Make sure its not sent in the triggers
			.withLastName('Mann').withBillingPostalCode('C1234AAC').withPhone('2345678909')
			.withCUILCUIT('20123456786').withNifType('12').withSalutation('0002')
			.withStatus('En Proceso de Venta').withPhone('23456789').withAlternativeFax('45678765456')
			.withEmail('user@users.use').withBillingStreet('1234 Test st.').withBillingState('Testate')
			.withBillingCity('Testopolis').withBillingPostalCode('A1234').withFloorApartment('5th a')
			.withBillingCountry('Testland').availableToSendToSAP().withNifType('80')
			.withSalesOrganization('0020').withDistributionChannel('10').build();
		
		anAccount = Build.anAccount().withName('TestMann').withSkipSend(2)
			.withBillingPostalCode('C1234AAC').withPhone('2345678909')
			.withNifType('12').withAlternativeFax('45678765456')
			.withStatus('En Proceso de Venta').withPhone('23456789')
			.withEmail('user@users.use').withBillingStreet('1234 Test st.').withBillingState('Testate')
			.withBillingCity('Testopolis').withBillingPostalCode('A1234').withFloorApartment('5th a')
			.withBillingCountry('Testland').availableToSendToSAP().withNifType('80')
			.withSalesOrganization('0010').withDistributionChannel('30').build();
		
		insert new List<Account> {anAccount, aPersonAccount};
            
        Usuario_No_envia_a_SAP__c user = new Usuario_No_envia_a_SAP__c();
        user.Name = UserInfo.getUserName();
        user.No_envia__c = true;
        insert user;
        
	}
}
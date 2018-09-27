@isTest
private class ContratosPedidos_EnviarSAPTest {
	private static testMethod void itShouldBePosibleToSendAnInsertedContractThroughItsId() {
		prepareIdSendData();
		
		Test.startTest();
		ContratosPedidos_EnviarSAP.sendContract(aContract.Id, 'A');
		Test.stopTest();
		
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out request =
			(WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out)serverMock.requestObj;
		
		System.assertEquals(1, request.Pedido.size());
	}
	
	private static testMethod void ifTheOldPositionNumbersAreNotObtainable_ItShouldBeShownToTheUserInTheContract() {
		prepareIdSendData();
		
		Test.startTest();
		ContratosPedidos_EnviarSAP.sendContract(aContract.Id, 'M');
		Test.stopTest();
		
		Contrato__c theContractInDB = [
			SELECT Id, Status_Envio__c, Estado_de_Envio_a_SAP__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		System.assertEquals('-1', theContractInDB.Status_Envio__c);
		System.assertEquals(
			'Error: No se pudo obtener los numeros de posiciones desde SAP',
			theContractInDB.Estado_de_Envio_a_SAP__c
		);
	}
	
	private static testMethod void sentDiscountsShouldBeUpdatedWhenSendingTheContractSuccessfully() {
		prepareIdSendData();
		
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In response = generateSapContractResponse();
		WSSAPContratosPedidos.Msg_element responseMessage = new WSSAPContratosPedidos.Msg_element();
		responseMessage.Tipo = 'S';
		response.Msg.add(responseMessage);
		serverMock.responseObj = response;
		
		Test.startTest();
		ContratosPedidos_EnviarSAP.sendContract(aContract.Id, 'A');
		Test.stopTest();
		
		Descuento_Recargo_Aplicado__c theAppliedDiscountInDB = [
			SELECT Id, Estado_de_envio__c
			FROM Descuento_Recargo_Aplicado__c
			WHERE Producto_de_Contrato__r.Contrato__c = :aContract.Id
		];
		
		System.assertEquals('Enviado', theAppliedDiscountInDB.Estado_de_envio__c);
	}
	
	private static testMethod void whenTheContractIsSentTheStatusFieldsShouldBeUpdated() {
		prepareIdSendData();
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In response = generateSapContractResponse();
		WSSAPContratosPedidos.Msg_element responseMessage = new WSSAPContratosPedidos.Msg_element();
		responseMessage.Tipo = 'S';
		response.Msg.add(responseMessage);
		serverMock.responseObj = response;
		
		Test.startTest();
		ContratosPedidos_EnviarSAP.sendContract(aContract.Id, 'A');
		Test.stopTest();
		
		Contrato__c theContractInDB = [
			SELECT Id, Esperando_envio__c, Status_Envio__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		System.assertEquals(false, theContractInDB.Esperando_envio__c);
		System.assertEquals('200', theContractInDB.Status_Envio__c);
	}
	
	//===================================================================================
	private static WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In generateSapContractResponse() {
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In result =
			new WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In();
		
		result.Msg = new List<WSSAPContratosPedidos.Msg_element>();
		result.Documento = new WSSAPContratosPedidos.Documento_element();
		
		return result;
	}
	
	private static void prepareIdSendData() {
		Cobertura__c aCoverage = Build.aCoverage().forProduct(productsMap.values()[0]).forContract(aContract).build();
		insert aCoverage;
		Descuento_Recargo_Aplicado__c anAppliedDiscount = Build.anAppliedDiscount().forDiscount(aDiscount)
			.forCoverage(aCoverage).withStartDate(Date.newInstance(2017, 8, 12))
			.withEndDate(Date.newInstance(2017, 9, 12)).withAmountSubsidized(1).build();
		insert anAppliedDiscount;
		
		List<Titular__c> holders = [
			SELECT Id
			FROM Titular__c
			WHERE Contrato__c = :aContract.Id
		];
		if(holders.size() == 0) {
			holders.add(Build.aHolder().forContract(aContract).forAccount(anAccount).build());
			insert holders;
		}
		
		String province = Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues()[0].getValue();
		Interlocutor_Provincia__c aProvinceSetting = Build.aProvinceSetting().withName(province).withSAPCode('78yi32307u').build();
		insert aProvinceSetting;
		
		RecordType addressRecipientType = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Domicilio'
				AND SObjectType = 'Beneficiario__c'
		];
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract).forHolder(holders[0])
			.withIVATreatment(ivaTreatment).withProvince(province).build();
		Beneficiario__c anAddressRecipient = Build.aRecipient().forContract(aContract).forHolder(holders[0])
			.withRecordType(addressRecipientType).withFixedPersonAmount(2).withInTransitPersonAmount(10)
			.withIVATreatment(ivaTreatment).withProvince(province).build();
		insert new List<Beneficiario__c> {aRecipient, anAddressRecipient};
		
		List<Cobertura_de_Beneficiario__c> coverageRecipientRelations = new List<Cobertura_de_Beneficiario__c>();
		coverageRecipientRelations.add(Build.aCoverageRecipientRelation().forCoverage(aCoverage).forRecipient(aRecipient).build());
		coverageRecipientRelations.add(Build.aCoverageRecipientRelation().forCoverage(aCoverage).forRecipient(anAddressRecipient).build());
		
		insert coverageRecipientRelations;
	}
	
	//===================================================================================
	static WebServiceSoapMock serverMock;
	static Configuracion_SAP__c sapSettings;
	static Account anAccount;
	static Contrato__c aContract;
	static Map<integer, Contact> contactMap;
	static Map<String, Product2> productsMap;
	static Descuento_Recargo__c aDiscount;
	static Descuento_Recargo__c aSpecialDiscount;
	static Descuento_Recargo__c aCustomDiscount;
	static Cobrador__c aCollector;
	
	static List<Cobertura__c> coveragesToSend;
	static Map<Id, List<Descuento_Recargo_Aplicado__c>> appliedDiscountsToSend;
	
	static {
		serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		
		//=================================================
		anAccount = Build.anAccount().withCUILCUIT('23456789234').build();
		insert anAccount;
		anAccount = [
			SELECT Id, N_mero_nico_de_Cliente__c
			FROM Account
			WHERE Id = :anAccount.Id
		];
		
		//=================================================
		List<Zona__c> zones = new List<Zona__c>();
		for(Integer i = 0; i < 3; i++) {
			zones.add(Build.aZone().withSAPName('ZAP!' + i).build());
		}
		insert zones;
		
		//=================================================
		aCollector = Build.aCollector().withName('Mr. Cole Hector').withSAPCode('12345678').build();
		insert aCollector;
		
		//=================================================
		List<Contact> contacts = new List<Contact> ();
		for(Integer i = 0; i < 3; i++) {
			contacts.add(Build.aContact().forAccount(anAccount).withManualBillingZone(zones[i]).build());
		}
		insert contacts;
		Set<Id> contactIds = new Set<Id>();
		for(Contact aContact : contacts) {
			contactIds.add(aContact.Id);
		}
		contactMap = new Map<integer, Contact>();
		integer index = 0;
		for(Contact aContact : [
			SELECT Id, Numero_unico_de_Contacto__c, Zona_de_cobranza_manual__r.Name
			FROM Contact
			WHERE Id IN :contactIds
		]) {
			contactMap.put(index++, aContact);
		}
		
		//=================================================
		RecordType contractRecordType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Contrato__c'
				AND IsActive = true
				AND DeveloperName = 'Contrato'
		];
		String cardType = Contrato__c.Tipo_de_Tarjeta__c.getDescribe().getPicklistValues()[0].getValue();
		aContract = Build.aContract().forAccount(anAccount).withCollector(aCollector)
			.withUniqueNumber().withSalesOrganization('0010').withDistributionChannel('30')
			.withContactoCobranza(contactMap.get(ContratosPedidos_EnviarSAP.CONTACTO_DELIVERY))
			.withContactoDelivery(contactMap.get(ContratosPedidos_EnviarSAP.CONTACTO_FACTURACION))
			.withContactoFacturacion(contactMap.get(ContratosPedidos_EnviarSAP.CONTACTO_COBRANZA))
			.withPaymentCondition('C010').withCardType(cardType).withPaymentMethod('A')
			.withStartDate(Date.newInstance(2017, 9, 30)).withEndDate(Date.newInstance(2018, 12, 1))
			.withValidCardNumber().withSkipSend(2).withRecordType(contractRecordType).build();
		insert aContract;
		aContract = [
			SELECT Id, Numero_Unico_de_Contrato_Con_Sufijo__c, Organizacion_de_Ventas__c, Contrato_de_Padrones__c,
				Canal_de_Distribucion__c, Condicion_de_pago__c,Forma_de_pago__c, Fecha_Baja__c, Grupo_de_Vendedores__c,
				Fecha_Alta__c, Oficina_de_Venta__c, Tipo_de_Tarjeta__c, Tarjeta_sin_cifrar__c, Estado__c,
				Factura_por_Adelantado__c, Es_evento__c, Bloqueo_Factura__c, CBU__c,  Fecha_Inicio_de_Vigencia__c,
				Cobrador__r.Codigo_Sap__c, Cliente__r.N_mero_nico_de_Cliente__c,
				Contacto_Cobranza__r.Numero_unico_de_contacto__c,
				Contacto_Cobranza__r.Zona_de_cobranza_manual__r.Name, Zona__r.Name,
				Contacto_de_delivery__r.Numero_unico_de_contacto__c,
				Contacto_Facturacion__r.Numero_unico_de_contacto__c,
				RecordType.DeveloperName, (
					SELECT Id, Producto__c, Cantidad__c, Cantidad_en_transito__c, Adicionales__c//, Descuento__c
					FROM Coberturas__r
				)
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		//=================================================
		productsMap = new Map<String, Product2>();
		String sectorVal = Product2.Sector__c.getDescribe().getPicklistValues()[0].getValue();
		for(Integer i = 0; i < 5; i++) {
			Product2 aProduct = Build.aProduct().withName('Prod ' + i)
				.withNumber('Prod ' + i).withSector(sectorVal).build();
			productsMap.put(aProduct.Numero__c, aProduct);
		}
		insert productsMap.values();
		
		//=================================================
		aDiscount = Build.aDiscount().withValue(20.23).withUnit('%').withDiscountCode('1refdfi').build();
		aCustomDiscount = Build.aDiscount().withUnit('%').withDiscountCode('ZDV0').build();
		aSpecialDiscount = Build.aDiscount().withValue(100).withUnit('%')
			.withName('Hasta 1 menor sin cargo cada dos adultos').withDiscountCode('2recs').build();
		insert new List<Descuento_Recargo__c> {aDiscount, aSpecialDiscount, aCustomDiscount};
		
		//=================================================
		coveragesToSend = new List<Cobertura__c>();
		appliedDiscountsToSend = new Map<Id, List<Descuento_Recargo_Aplicado__c>>();
	}
}
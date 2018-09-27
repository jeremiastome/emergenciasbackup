@isTest
private class ContractToSAPConverterBaseTest {
	//====================================
	//Header
	@isTest
	private static void itShouldBePosibleToPrepareTheHeaderForAContract() {
		TestContractToSAPConverter converter = new TestContractToSAPConverter(aContract.Id, 'A');
		
		WSSAPContratosPedidos.Cabecera_element requestHeader = converter.generateRequest().Cabecera;
		
		System.assertEquals('A', requestHeader.TipoOperacion);
		System.assertEquals(aContract.Tipo_de_documento_sap__c, requestHeader.TipoDocumento);
		System.assertEquals(aContract.Numero_Unico_de_Contrato_Con_Sufijo__c, requestHeader.NumeroDePedido);
		System.assertEquals(aContract.Organizacion_de_Ventas__c, requestHeader.OrganizacionVentas);
		System.assertEquals(aContract.Canal_de_Distribucion__c, requestHeader.CanalDistribucion);
		System.assertEquals('00', requestHeader.Sector);
		System.assertEquals('', requestHeader.NumeroPedidoCliente);
		System.assertEquals(aContract.Tipo_de_Tarjeta__c, requestHeader.TipoTarjeta);
		System.assertEquals(aContract.Tarjeta_sin_cifrar__c, requestHeader.Tarjeta);
		System.assertEquals('20170930', requestHeader.IniVigenciaContrato);
		System.assertEquals('20181201', requestHeader.FinVigenciaContrato);
		System.assertEquals('50', requestHeader.ReglaFact);
		System.assertEquals('', requestHeader.BloqueoFact);
		System.assertEquals(anAccount.N_mero_nico_de_Cliente__c, requestHeader.Solicitante);
		System.assertEquals(aCollector.Codigo_Sap__c, requestHeader.Cobrador);
		System.assertEquals(aDeliveryContact.Numero_unico_de_contacto__c, requestHeader.DestinatarioMercancias);
		System.assertEquals(aBillingContact.Numero_unico_de_contacto__c, requestHeader.DestinatarioFactura);
		System.assertEquals(aCollectionContact.Numero_unico_de_contacto__c, requestHeader.ResponsableDePago);
		System.assertEquals(aCollectionContact.Zona_de_cobranza_manual__r.Name, requestHeader.Radio);
		
		System.assertEquals(
			aContract.Forma_de_Pago__c + aContract.Condicion_de_pago__c,
			requestHeader.CondicionDePago
		);
		System.assertEquals(
			aContract.Oficina_de_Venta__c + '-' + aContract.Grupo_de_Vendedores__c,
			requestHeader.OficinaDeVentas
		);
		System.assertEquals(
			aContract.Factura_por_Adelantado__c? 'True':' ',
			requestHeader.FactAdelantado
		);
	}
	
	@isTest
	private static void ifTheContractDoesntHaveAStartOrEndDateSpecialDatesShouldBeUsed() {
		aContract.Fecha_Alta__c = null;
		aContract.Fecha_Baja__c = null;
		update aContract;
		String expectedDate = String.ValueOf(System.today().year())
			+ String.ValueOf(System.today().month()).leftPad(2,'0')
			+ String.ValueOf(System.today().day()).leftPad(2,'0');
		
		TestContractToSAPConverter converter = new TestContractToSAPConverter(aContract.Id, 'A');
		
		WSSAPContratosPedidos.Cabecera_element requestHeader = converter.generateRequest().Cabecera;
		System.assertEquals(expectedDate, requestHeader.IniVigenciaContrato);
		System.assertEquals('99991231', requestHeader.FinVigenciaContrato);
	}
	
	@isTest
	private static void ifThePaymentMethodIsDebitThenTheCBUShouldBeSentInTheCardFieldToSAP() {
		RecordType contractRecordType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Contrato__c'
				AND IsActive = true
				AND DeveloperName = 'Contrato'
		];
		aContract = Build.aContract().forAccount(anAccount).withCollector(aCollector)
			.withUniqueNumber().withSalesOrganization('0010').withDistributionChannel('30')
			.withContactoDelivery(aDeliveryContact).withContactoFacturacion(aBillingContact)
			.withContactoCobranza(aCollectionContact).withPaymentCondition('C010')
			.withDebitPaymentMethod().withValidCBU().withStartDate(Date.newInstance(2017, 9, 30))
			.withEndDate(Date.newInstance(2018, 12, 1)).withValidCardNumber().withSkipSend(200)
			.withRecordType(contractRecordType).withSalesOffice().withSalesGroup().build();
		insert aContract;
		
		TestContractToSAPConverter converter = new TestContractToSAPConverter(aContract.Id, 'A');
		WSSAPContratosPedidos.Cabecera_element requestHeader = converter.generateRequest().Cabecera;
		
		System.assertEquals(aContract.CBU__c, requestHeader.Tarjeta);
	}
	
	@isTest
	private static void ifTheContractHasNoContacts_theFieldsShouldBeLeftEmpty() {
		aContract.Contacto_Cobranza__c = null;
		aContract.Contacto_Facturacion__c = null;
		aContract.Contacto_de_delivery__c = null;
		update aContract;
		
		TestContractToSAPConverter converter = new TestContractToSAPConverter(aContract.Id, 'A');
		WSSAPContratosPedidos.Cabecera_element requestHeader = converter.generateRequest().Cabecera;
		
		System.assertEquals('', requestHeader.DestinatarioMercancias);
		System.assertEquals('', requestHeader.DestinatarioFactura);
		System.assertEquals('', requestHeader.ResponsableDePago);
	}
	
	@isTest
	private static void ifTheContractHasNoCollectionContactAndTheContractHasAZoneSet_ItShouldBeSentAsTheRadius() {
		Zona__c aZone = Build.aZone().withName('Twilight').build();
		insert aZone;
		
		aContract.Contacto_Cobranza__c = null;
		aContract.Zona__c = aZone.Id;
		update aContract;
		
		TestContractToSAPConverter converter = new TestContractToSAPConverter(aContract.Id, 'A');
		WSSAPContratosPedidos.Cabecera_element requestHeader = converter.generateRequest().Cabecera;
		
		System.assertEquals(aZone.Name, requestHeader.Radio);
	}
	
	@isTest
	private static void ifTheContractIsForMassiveClientsTheDocumentTypeShouldBeC1() {
		aContract.Contrato_de_Padrones__c = true;
		update aContract;
		
		TestContractToSAPConverter converter = new TestContractToSAPConverter(aContract.Id, 'A');
		WSSAPContratosPedidos.Cabecera_element requestHeader = converter.generateRequest().Cabecera;
		
		System.assertEquals('C1', requestHeader.TipoDocumento);
		System.assertEquals('', requestHeader.FactAdelantado);
		System.assertEquals('', requestHeader.ReglaFact);
	}
	
	@isTest
	private static void ifTheContractHasAPetroleumDistributionChannelTheDocumentTypeShouldBeC3() {
		aContract.Canal_de_Distribucion__c = '32';//'32' == 'Corporaciones – Petroleo'
		update aContract;
		
		TestContractToSAPConverter converter = new TestContractToSAPConverter(aContract.Id, 'A');
		WSSAPContratosPedidos.Cabecera_element requestHeader = converter.generateRequest().Cabecera;
		
		System.assertEquals('C3', requestHeader.TipoDocumento);
		System.assertEquals('', requestHeader.FactAdelantado);
		System.assertEquals('', requestHeader.ReglaFact);
	}
	
	@isTest
	private static void ifTheContractHasAValidityStartDateItShouldBeSent() {
		aContract.Fecha_Inicio_de_Vigencia__c = System.today().addDays(3);
		update aContract;
		TestContractToSAPConverter converter = new TestContractToSAPConverter(aContract.Id, 'A');
		
		WSSAPContratosPedidos.Cabecera_element requestHeader = converter.generateRequest().Cabecera;
		
		String expectedDate = String.ValueOf(aContract.Fecha_Inicio_de_Vigencia__c.year())
			+ String.ValueOf(aContract.Fecha_Inicio_de_Vigencia__c.month()).leftPad(2,'0')
			+ String.ValueOf(aContract.Fecha_Inicio_de_Vigencia__c.day()).leftPad(2,'0');
		
		System.assertEquals(expectedDate, requestHeader.IniVigenciaContrato);
	}
	
	@isTest
	private static void ifTheContractIsBeingSentForSimulationTheAccountDataShouldNotBeSentAndTheAccountNumberReplacedWithADefaultNumber() {
		Cuenta_de_cotizador__c simulationAccountSettings = Build.someSimulationAccountSettings().build();
		insert simulationAccountSettings;
		TestContractToSAPConverter converter = new TestContractToSAPConverter(aContract.Id, 'S');
		
		WSSAPContratosPedidos.Cabecera_element requestHeader = converter.generateRequest().Cabecera;
		
		System.assertEquals(simulationAccountSettings.Numero_unico_CF__c, requestHeader.Solicitante);
		System.assertEquals('', requestHeader.DestinatarioMercancias);
		System.assertEquals('', requestHeader.DestinatarioFactura);
		System.assertEquals('', requestHeader.ResponsableDePago);
		System.assertEquals('', requestHeader.Radio);
	}
	
	private class TestContractToSAPConverter extends ContractToSAPConverterBase {
		public TestContractToSAPConverter(Id contractId, String operation) {
			super(contractId, operation);
		}
	}
	
	//==========================================================================
	static Cobrador__c aCollector;
	static Account anAccount;
	static Contact aDeliveryContact;
	static Contact aBillingContact;
	static Contact aCollectionContact;
	static Contrato__c aContract;
	
	static {
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
		integer index = 0;
		for(Contact aContact : [
			SELECT Id, Numero_unico_de_Contacto__c, Zona_de_cobranza_manual__r.Name
			FROM Contact
			WHERE Id IN :contactIds
		]) {
			if(aDeliveryContact == null) {
				aDeliveryContact = aContact;
			}
			else if(aBillingContact == null) {
				aBillingContact = aContact;
			}
			else {
				aCollectionContact = aContact;
			}
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
			.withContactoDelivery(aDeliveryContact).withContactoFacturacion(aBillingContact)
			.withContactoCobranza(aCollectionContact).withPaymentCondition('C010')
			.withCardType(cardType).withPaymentMethod('A').withStartDate(Date.newInstance(2017, 9, 30))
			.withEndDate(Date.newInstance(2018, 12, 1)).withValidCardNumber().withSkipSend(200)
			.withRecordType(contractRecordType).withSalesOffice().withSalesGroup()
			.withSapDocumentType('C0').build();
		insert aContract;
		
		aContract = [
			SELECT Id, Numero_Unico_de_Contrato_Con_Sufijo__c, Organizacion_de_Ventas__c,
				Contrato_de_Padrones__c, Canal_de_Distribucion__c, Condicion_de_pago__c,
				Forma_de_pago__c, Fecha_Baja__c, Grupo_de_Vendedores__c, Fecha_Alta__c,
				Oficina_de_Venta__c, Tipo_de_Tarjeta__c, Tarjeta_sin_cifrar__c, Estado__c,
				Factura_por_Adelantado__c, Es_evento__c, Bloqueo_Factura__c, CBU__c,
				Importe__c, Fecha_Inicio_de_Vigencia__c, Tipo_de_documento_sap__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
	}
}
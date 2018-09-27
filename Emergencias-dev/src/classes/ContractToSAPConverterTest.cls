@isTest
private class ContractToSAPConverterTest {
	//====================================
	//Position
	//Person
	private static testMethod void itShouldBePosibleToPreparePositionsForProductsForPersonRecipients() {
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		List<Beneficiario__c> recipients = addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'A');
		List<WSSAPContratosPedidos.Posicion_element> positions = converter.generateRequest().ListaPosiciones.Posicion;
		
		System.assertEquals(1, positions.size());
		
		System.assertEquals('A', positions[0].TipoOperacion);
		System.assertEquals('100', positions[0].NumeroPosicion);
		System.assertEquals(aProduct.Numero__c, positions[0].CodigoMaterial);
		System.assertEquals(formatNumber(recipients.size(), 3), positions[0].Cantidad);
		System.assertEquals(aProduct.Sector__c, positions[0].Sector);
		System.assertEquals('', positions[0].ZonaDeVentas);
		System.assertEquals(ivaTreatment, positions[0].CondIVABenef);
		System.assertEquals(aProvinceSetting.Codigo_SAP__c, positions[0].DestinatarioMercancias);
		System.assertEquals('', positions[0].GrupoDeClientes);
		System.assertEquals('', positions[0].MotivoDeRechazo);
		System.assertEquals('', positions[0].Cobrador);
		System.assertEquals('', positions[0].Radio);
	}
	
	private static testMethod void unitRecipientsShouldBeSeparatedByIVATreatment() {
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		String ivaTreatmentA = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		String ivaTreatmentB = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[1].getValue();
		List<Beneficiario__c> recipientsA = addPersonRecipients(aCoverage, 5, ivaTreatmentA, aProvinceSetting.Name);
		List<Beneficiario__c> recipientsB = addPersonRecipients(aCoverage, 2, ivaTreatmentB, aProvinceSetting.Name);
		
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'A');
		List<WSSAPContratosPedidos.Posicion_element> positions = converter.generateRequest().ListaPosiciones.Posicion;
		
		boolean ivaAFound = false;
		boolean ivaBFound = false;
		System.assertEquals(2, positions.size());
		for(Integer i = 0; i < positions.size(); i++) {
			WSSAPContratosPedidos.Posicion_element position = positions[i];
			
			System.assertEquals('A', position.TipoOperacion);
			System.assertEquals(String.valueOf((i + 1) * 100), position.NumeroPosicion);
			
			if(position.CondIVABenef == ivaTreatmentA) {
				System.assertEquals(String.valueOf(recipientsA.size()) + '.000', position.Cantidad);
				ivaAFound = true;
			}
			else {
				System.assertEquals(String.valueOf(recipientsB.size()) + '.000', position.Cantidad);
				ivaBFound = true;
			}
		}
		
		System.assert(ivaAFound);
		System.assert(ivaBFound);
	}
	
	private static testMethod void unitRecipientsShouldBeSeparatedByProvince() {
		String province = Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues()[1].getValue();
		Interlocutor_Provincia__c anotherProvinceSetting = Build.aProvinceSetting().withName(province).withSAPCode('78yi22307u').build();
		insert anotherProvinceSetting;
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		List<Beneficiario__c> recipientsA = addPersonRecipients(aCoverage, 5, ivaTreatment, aProvinceSetting.Name);
		List<Beneficiario__c> recipientsB = addPersonRecipients(aCoverage, 2, ivaTreatment, anotherProvinceSetting.Name);
		
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'A');
		List<WSSAPContratosPedidos.Posicion_element> positions = converter.generateRequest().ListaPosiciones.Posicion;
		
		boolean provinceAFound = false;
		boolean provinceBFound = false;
		System.assertEquals(2, positions.size());
		for(Integer i = 0; i < positions.size(); i++) {
			WSSAPContratosPedidos.Posicion_element position = positions[i];
			
			System.assertEquals('A', position.TipoOperacion);
			System.assertEquals(String.valueOf((i + 1) * 100), position.NumeroPosicion);
			
			if(aProvinceSetting.Codigo_SAP__c == position.DestinatarioMercancias) {
				System.assertEquals(String.valueOf(recipientsA.size()) + '.000', position.Cantidad);
				provinceAFound = true;
			}
			else {
				System.assertEquals(String.valueOf(recipientsB.size()) + '.000', position.Cantidad);
				provinceBFound = true;
			}
		}
		
		System.assert(provinceAFound);
		System.assert(provinceBFound);
	}
	
	private static testMethod void whenAContractIsPreparedForModificationsTheOldPositionNumbersShouldBeUsed() {
		String positionNumber = '300';
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		WSSAPContratosPosiciones.DT_CONTRATO_RESP responseObj = new WSSAPContratosPosiciones.DT_CONTRATO_RESP();
		responseObj.POSICIONES = new List<WSSAPContratosPosiciones.POSICIONES_element>();
		responseObj.POSICIONES.add(generateOldPosition(aProduct, ivaTreatment, aProvinceSetting.Codigo_SAP__c, positionNumber));
		serverMock.responseObj = responseObj;
		
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		List<Beneficiario__c> recipients = addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		
		Test.startTest();
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'M');
		Test.stopTest();
		WSSAPContratosPedidos.Posicion_element position = converter.generateRequest().ListaPosiciones.Posicion[0];
		
		System.assertEquals(false, converter.oldPositionNumbersFailed);
		
		System.assertEquals('M', position.TipoOperacion);
		System.assertEquals(positionNumber, position.NumeroPosicion);
	}
	
	private static testMethod void whenAContractIsPreparedForModificationsIfTheOldPositionsAreNotPresent() {
		integer positionNumber = 300;
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		WSSAPContratosPosiciones.DT_CONTRATO_RESP responseObj = new WSSAPContratosPosiciones.DT_CONTRATO_RESP();
		responseObj.POSICIONES = new List<WSSAPContratosPosiciones.POSICIONES_element>();
		responseObj.POSICIONES.add(generateOldPosition(aProduct, ivaTreatment, aProvinceSetting.Codigo_SAP__c + 'a', String.valueOf(positionNumber)));
		serverMock.responseObj = responseObj;
		
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		List<Beneficiario__c> recipients = addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		
		Test.startTest();
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'M');
		Test.stopTest();
		List<WSSAPContratosPedidos.Posicion_element> positions = converter.generateRequest().ListaPosiciones.Posicion;
		
		System.assertEquals(2, positions.size());
		
		for(WSSAPContratosPedidos.Posicion_element position : positions) {
			if(position.TipoOperacion == 'A') {
				System.assertEquals(String.valueOf(positionNumber + 100), position.NumeroPosicion);
			}
			else {
				System.assertEquals('B', position.TipoOperacion);
				System.assertEquals(String.valueOf(positionNumber), position.NumeroPosicion);
			}
		}
	}
	
	private static testMethod void ifTheOperationIsSimulation_ThePositionsShouldBeSimulations() {
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		List<Beneficiario__c> recipients = addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'S');
		List<WSSAPContratosPedidos.Posicion_element> positions = converter.generateRequest().ListaPosiciones.Posicion;
		
		System.assertEquals('S', positions[0].TipoOperacion);
	}
	
	//Address
	private static testMethod void itShouldBePosibleToPreparePositionsForProductsForAddressRecipients() {
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		Beneficiario__c recipient = addAddressRecipient(ivaTreatment, aProvinceSetting.Name);
		Cobertura_de_Beneficiario__c recipientCoverageRelation =
			addAddressRecipientRelation(aCoverage, recipient, 20, 10);
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'A');
		List<WSSAPContratosPedidos.Posicion_element> positions = converter.generateRequest().ListaPosiciones.Posicion;
		
		System.assertEquals(1, positions.size());
		
		System.assertEquals('A', positions[0].TipoOperacion);
		System.assertEquals('100', positions[0].NumeroPosicion);
		System.assertEquals(aProduct.Numero__c, positions[0].CodigoMaterial);
		System.assertEquals(
			formatNumber(
				recipientCoverageRelation.Cantidad_domicilio__c
					+ recipientCoverageRelation.Cantidad_domicilio_en_transito__c,
				3
			),
			positions[0].Cantidad
		);
		System.assertEquals(aProduct.Sector__c, positions[0].Sector);
		System.assertEquals(recipient.N_mero_nico_de_Beneficiario__c.right(3), positions[0].ZonaDeVentas);
		System.assertEquals(ivaTreatment, positions[0].CondIVABenef);
		System.assertEquals(aProvinceSetting.Codigo_SAP__c, positions[0].DestinatarioMercancias);
		System.assertEquals(recipient.Rubro_del_domicilio__c, positions[0].GrupoDeClientes);
		System.assertEquals('', positions[0].MotivoDeRechazo);
		System.assertEquals('', positions[0].Cobrador);
		System.assertEquals('', positions[0].Radio);
	}
	
	private static testMethod void addressPositionsShouldHaveTheirStaticAndInTransitAmountsSeparatedWhenTheProductIsConfiguredSo() {
		Producto_Transito__c separationSetting = Build.aProductSeparationSetting().withName(aProduct.Numero__c).build();
		insert separationSetting;
		
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		Beneficiario__c recipient = addAddressRecipient(ivaTreatment, aProvinceSetting.Name);
		Cobertura_de_Beneficiario__c recipientCoverageRelation =
			addAddressRecipientRelation(aCoverage, recipient, 20, 10);
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'A');
		List<WSSAPContratosPedidos.Posicion_element> positions = converter.generateRequest().ListaPosiciones.Posicion;
		
		System.assertEquals(2, positions.size());
		
		boolean foundStatic = false;
		boolean foundInTransit = false;
		for(WSSAPContratosPedidos.Posicion_element position : positions) {
			if(position.CodigoMaterial == aProduct.Numero__c) {
				System.assertEquals(
					formatNumber(recipientCoverageRelation.Cantidad_domicilio__c, 3),
					position.Cantidad
				);
				foundStatic = true;
			}
			else {
				System.assertEquals(aProduct.Numero__c + ' TRA', position.CodigoMaterial);
				System.assertEquals(
					formatNumber(recipientCoverageRelation.Cantidad_domicilio_en_transito__c, 3),
					position.Cantidad
				);
				foundInTransit = true;
			}
		}
		System.assert(foundStatic);
		System.assert(foundInTransit);
	}
	
	//Massive
	private static testMethod void itShouldBePosibleToPreparePositionsForProductsForMassiveRecipients() {
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		RecordType massiveRecipientType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Beneficiario__c'
				AND DeveloperName = 'Padron'
				AND IsActive = true
		];
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract).forHolder(aHolder)
			.withProvince(aProvinceSetting.Name).withRecordType(massiveRecipientType).withActiveStatus().build();
		insert aRecipient;
		
		String ivaTreatment = Cobertura_de_Beneficiario__c.Tratamiento_de_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		Cobertura_de_Beneficiario__c relationWithCoverage = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(aCoverage).withIVATreatment(ivaTreatment)
			.withAmountForMassiveRecipient(5324).Build();
		insert relationWithCoverage;
		
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'A');
		List<WSSAPContratosPedidos.Posicion_element> positions = converter.generateRequest().ListaPosiciones.Posicion;
		
		System.assertEquals(1, positions.size());
		
		System.assertEquals('A', positions[0].TipoOperacion);
		System.assertEquals('100', positions[0].NumeroPosicion);
		System.assertEquals(aProduct.Numero__c, positions[0].CodigoMaterial);
		System.assertEquals(formatNumber(relationWithCoverage.Cantidad_de_Padron__c, 3), positions[0].Cantidad);
		System.assertEquals(aProduct.Sector__c, positions[0].Sector);
		System.assertEquals('', positions[0].ZonaDeVentas);
		System.assertEquals(ivaTreatment, positions[0].CondIVABenef);
		System.assertEquals(aProvinceSetting.Codigo_SAP__c, positions[0].DestinatarioMercancias);
		System.assertEquals('', positions[0].GrupoDeClientes);
		System.assertEquals('', positions[0].MotivoDeRechazo);
		System.assertEquals('', positions[0].Cobrador);
		System.assertEquals('', positions[0].Radio);
	}
	
	//====================================
	//Conditions
	private static testMethod void discountsShouldBeAppliedToPositionsAsConditions() {
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		List<Beneficiario__c> recipients = addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		Descuento_Recargo_Aplicado__c appliedDiscount = applyDiscount(
			aCoverage,
			aDiscount,
			Date.newInstance(2017, 9, 30),
			Date.newInstance(2018, 12, 1)
		);
		
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'A');
		WSSAPContratosPedidos.Posicion_element position = converter.generateRequest().ListaPosiciones.Posicion[0];
		
		System.assertEquals(1, position.Condiciones.size());
		
		System.assertEquals('A', position.Condiciones[0].TipoOperacion);
		System.assertEquals(aDiscount.Codigo_de_descuento__c, position.Condiciones[0].ClaseCondicion);
		System.assertEquals(formatNumber(aDiscount.Valor__c, 2), position.Condiciones[0].Importe);
		System.assertEquals(aDiscount.Unidad__c, position.Condiciones[0].Unidad);
		System.assertEquals('20170930', position.Condiciones[0].FechaInicioValidez);
		System.assertEquals('20181201', position.Condiciones[0].FechaFinValidez);
	}
	
	private static testMethod void whenApplyingTheCustomDiscountTheValueShouldBeTakenFromTheCoverage() {
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		update aCoverage;
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		List<Beneficiario__c> recipients = addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		Descuento_Recargo_Aplicado__c appliedDiscount = applyCustomDiscount(
			aCoverage,
			theCustomDiscount,
			Date.newInstance(2017, 9, 30),
			Date.newInstance(2018, 12, 1),
			65.65
		);
		
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'A');
		WSSAPContratosPedidos.Posicion_element position = converter.generateRequest().ListaPosiciones.Posicion[0];
		
		System.assertEquals(formatNumber(appliedDiscount.Valor__c, 2), position.Condiciones[0].Importe);
		System.assertEquals('ZDV0', position.Condiciones[0].ClaseCondicion);
		System.assertEquals(theCustomDiscount.Unidad__c, position.Condiciones[0].Unidad);
	}
	
	private static testMethod void whenApplyingTheFreeMinorDiscountItShouldBeSentInASeparatePosition() {
		RecordType personRecipientType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Beneficiario__c'
				AND DeveloperName = 'Persona'
				AND IsActive = true
		];
		
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		List<Beneficiario__c> recipients = addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		
		Beneficiario__c bonifiedRecipient = Build.aRecipient().forContract(aContract).forHolder(aHolder)
			.withProvince(aProvinceSetting.Name).withIVATreatment(ivaTreatment).withActiveStatus()
			.withRecordType(personRecipientType).build();
		insert bonifiedRecipient;
		Cobertura_de_Beneficiario__c bonifiedRecipientCoverage = Build.aCoverageRecipientRelation()
			.forRecipient(bonifiedRecipient).forCoverage(aCoverage).Build();
		insert bonifiedRecipientCoverage;
		
		Descuento_Recargo_Aplicado__c appliedDiscount = applyDiscount(
			aCoverage,
			theFreeMinorDiscount,
			Date.newInstance(2017, 9, 30),
			Date.newInstance(2018, 12, 1)
		);
		Aplicante__c anApplicant = Build.anApplicant().forAppliedDiscount(appliedDiscount)
			.forRecipientCoverage(bonifiedRecipientCoverage).withStartDate(Date.newInstance(2017, 3, 12))
			.withEndDate(Date.newInstance(2018, 10, 8)).build();
		insert anApplicant;
		
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'A');
		List<WSSAPContratosPedidos.Posicion_element> positions = converter.generateRequest().ListaPosiciones.Posicion;
		
		System.assertEquals(2, positions.size());
		boolean foundNormal = false;
		boolean foundDiscounted = false;
		for(WSSAPContratosPedidos.Posicion_element position : positions) {
			
			if(position.Cantidad == formatNumber(1, 3)) {
				System.assertEquals(1, position.Condiciones.size());
				System.assertEquals(formatNumber(theFreeMinorDiscount.Valor__c, 2), position.Condiciones[0].Importe);
				System.assertEquals('ZDV1', position.Condiciones[0].ClaseCondicion);
				System.assertEquals(theFreeMinorDiscount.Unidad__c, position.Condiciones[0].Unidad);
				System.assertEquals('20170312', position.Condiciones[0].FechaInicioValidez);
				System.assertEquals('20181008', position.Condiciones[0].FechaFinValidez);
				foundDiscounted = true;
			}
			else {
				System.assertEquals(formatNumber(recipients.size(), 3), position.Cantidad);
				System.assertEquals(0, position.Condiciones.size());
				foundNormal = true;
			}
		}
		
		System.assert(foundNormal);
		System.assert(foundDiscounted);
	}
	
	private static testMethod void whenAVariedSalesContractIsSentTheFirstPositionShouldHaveAConditionWithTheContractsPrice() {
		RecordType contractRecordType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Contrato__c'
				AND IsActive = true
				AND DeveloperName = 'Ventas_Varias'
		];
		String cardType = Contrato__c.Tipo_de_Tarjeta__c.getDescribe().getPicklistValues()[0].getValue();
		aContract = Build.aContract().forAccount(anAccount).withPaymentCondition('C010')
			.withUniqueNumber().withSalesOrganization('0010').withDistributionChannel('30')
			.withCardType(cardType).withPaymentMethod('A').withValidCardNumber()
			.withRecordType(contractRecordType).withSalesOffice().withSalesGroup()
			.withCost(14.99).withSapDocumentType('C0').withSkipSend(200).build();
		insert aContract;
		
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		List<Beneficiario__c> recipients = addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'A');
		WSSAPContratosPedidos.Pedido_element request = converter.generateRequest();
		WSSAPContratosPedidos.Posicion_element position = request.ListaPosiciones.Posicion[0];
		
		System.assertEquals('VV', request.Cabecera.TipoDocumento);
		
		System.assertEquals(1, position.Condiciones.size());
		
		
		System.assertEquals('A', position.Condiciones[0].TipoOperacion);
		System.assertEquals('ZPR1', position.Condiciones[0].ClaseCondicion);
		System.assertEquals(formatNumber(aContract.Importe__c, 2), position.Condiciones[0].Importe);
		System.assertEquals('C/U', position.Condiciones[0].Unidad);
		System.assertEquals(request.Cabecera.IniVigenciaContrato, position.Condiciones[0].FechaInicioValidez);
		System.assertEquals('29991231', position.Condiciones[0].FechaFinValidez);
	}
	
	private static testMethod void newDiscountsAppliedToOldPositionsShouldBeSentAsAdditions() {
		String positionNumber = '300';
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		WSSAPContratosPosiciones.DT_CONTRATO_RESP responseObj = new WSSAPContratosPosiciones.DT_CONTRATO_RESP();
		responseObj.POSICIONES = new List<WSSAPContratosPosiciones.POSICIONES_element>();
		responseObj.POSICIONES.add(generateOldPosition(aProduct, ivaTreatment, aProvinceSetting.Codigo_SAP__c, positionNumber));
		serverMock.responseObj = responseObj;
		
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		List<Beneficiario__c> recipients = addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		
		Descuento_Recargo_Aplicado__c appliedDiscount = applyDiscount(
			aCoverage,
			aDiscount,
			Date.newInstance(2017, 9, 30),
			Date.newInstance(2018, 12, 1)
		);
		
		Test.startTest();
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'M');
		Test.stopTest();
		
		WSSAPContratosPedidos.Posicion_element position = converter.generateRequest().ListaPosiciones.Posicion[0];
		
		System.assertEquals('A', position.Condiciones[0].TipoOperacion);
	}
	
	private static testMethod void oldDiscountsAppliedToOldPositionsShouldBeSentAsModifications() {
		String positionNumber = '300';
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		WSSAPContratosPosiciones.DT_CONTRATO_RESP responseObj = new WSSAPContratosPosiciones.DT_CONTRATO_RESP();
		responseObj.POSICIONES = new List<WSSAPContratosPosiciones.POSICIONES_element>();
		responseObj.POSICIONES.add(generateOldPosition(aProduct, ivaTreatment, aProvinceSetting.Codigo_SAP__c, positionNumber));
		serverMock.responseObj = responseObj;
		
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		List<Beneficiario__c> recipients = addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		
		Descuento_Recargo_Aplicado__c appliedDiscount = applyDiscount(
			aCoverage,
			aDiscount,
			Date.newInstance(2017, 9, 30),
			Date.newInstance(2018, 12, 1)
		);
		appliedDiscount.Estado_de_envio__c = 'Enviado';
		update appliedDiscount;
		
		Test.startTest();
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'M');
		Test.stopTest();
		
		WSSAPContratosPedidos.Posicion_element position = converter.generateRequest().ListaPosiciones.Posicion[0];
		
		System.assertEquals('M', position.Condiciones[0].TipoOperacion);
	}
	
	private static testMethod void oldDiscountsAppliedToNewPositionsShouldBeSentAsAdditions() {
		String positionNumber = '300';
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		String otherIvaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[1].getValue();
		
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		WSSAPContratosPosiciones.DT_CONTRATO_RESP responseObj = new WSSAPContratosPosiciones.DT_CONTRATO_RESP();
		responseObj.POSICIONES = new List<WSSAPContratosPosiciones.POSICIONES_element>();
		responseObj.POSICIONES.add(generateOldPosition(aProduct, ivaTreatment, aProvinceSetting.Codigo_SAP__c, positionNumber));
		serverMock.responseObj = responseObj;
		
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		addPersonRecipients(aCoverage, 1, otherIvaTreatment, aProvinceSetting.Name);
		
		Descuento_Recargo_Aplicado__c appliedDiscount = applyDiscount(
			aCoverage,
			aDiscount,
			Date.newInstance(2017, 9, 30),
			Date.newInstance(2018, 12, 1)
		);
		appliedDiscount.Estado_de_envio__c = 'Enviado';
		update appliedDiscount;
		
		Test.startTest();
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'M');
		Test.stopTest();
		
		List<WSSAPContratosPedidos.Posicion_element> positions = converter.generateRequest().ListaPosiciones.Posicion;
		
		for(WSSAPContratosPedidos.Posicion_element position : positions) {
			if(position.TipoOperacion == 'A') {
				System.assertEquals('A', position.Condiciones[0].TipoOperacion);
			}
			else {//position.TipoOperacion == 'M'
				System.assertEquals('M', position.Condiciones[0].TipoOperacion);
			}
		}
		
	}
	
	private static testMethod void disabledDiscountsAppliedToOldPositionsShouldBeSentAsEliminations() {
		String positionNumber = '300';
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		WSSAPContratosPosiciones.DT_CONTRATO_RESP responseObj = new WSSAPContratosPosiciones.DT_CONTRATO_RESP();
		responseObj.POSICIONES = new List<WSSAPContratosPosiciones.POSICIONES_element>();
		responseObj.POSICIONES.add(generateOldPosition(aProduct, ivaTreatment, aProvinceSetting.Codigo_SAP__c, positionNumber));
		serverMock.responseObj = responseObj;
		
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		List<Beneficiario__c> recipients = addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		
		Descuento_Recargo_Aplicado__c appliedDiscount = applyDiscount(
			aCoverage,
			aDiscount,
			Date.newInstance(2017, 9, 30),
			Date.newInstance(2018, 12, 1)
		);
		appliedDiscount.Estado_de_envio__c = 'Baja';
		update appliedDiscount;
		
		Test.startTest();
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'M');
		Test.stopTest();
		
		WSSAPContratosPedidos.Posicion_element position = converter.generateRequest().ListaPosiciones.Posicion[0];
		
		System.assertEquals('B', position.Condiciones[0].TipoOperacion);
	}
	
	private static testMethod void disabledDiscountsAppliedToNewPositionsShouldNotBeSent() {
		String positionNumber = '300';
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		WSSAPContratosPosiciones.DT_CONTRATO_RESP responseObj = new WSSAPContratosPosiciones.DT_CONTRATO_RESP();
		responseObj.POSICIONES = new List<WSSAPContratosPosiciones.POSICIONES_element>();
		serverMock.responseObj = responseObj;
		
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		List<Beneficiario__c> recipients = addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		
		Descuento_Recargo_Aplicado__c appliedDiscount = applyDiscount(
			aCoverage,
			aDiscount,
			Date.newInstance(2017, 9, 30),
			Date.newInstance(2018, 12, 1)
		);
		appliedDiscount.Estado_de_envio__c = 'Baja';
		update appliedDiscount;
		
		Test.startTest();
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'M');
		Test.stopTest();
		
		WSSAPContratosPedidos.Posicion_element position = converter.generateRequest().ListaPosiciones.Posicion[0];
		
		System.assertEquals(0, position.Condiciones.size());
	}
	
	private static testMethod void disabledAndSentDiscountsAppliedToOldPositionsShouldNotBeSent() {
		String positionNumber = '300';
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		WSSAPContratosPosiciones.DT_CONTRATO_RESP responseObj = new WSSAPContratosPosiciones.DT_CONTRATO_RESP();
		responseObj.POSICIONES = new List<WSSAPContratosPosiciones.POSICIONES_element>();
		responseObj.POSICIONES.add(generateOldPosition(aProduct, ivaTreatment, aProvinceSetting.Codigo_SAP__c, positionNumber));
		serverMock.responseObj = responseObj;
		
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		List<Beneficiario__c> recipients = addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		
		Descuento_Recargo_Aplicado__c appliedDiscount = applyDiscount(
			aCoverage,
			aDiscount,
			Date.newInstance(2017, 9, 30),
			Date.newInstance(2018, 12, 1)
		);
		appliedDiscount.Estado_de_envio__c = 'Enviado baja';
		update appliedDiscount;
		
		Test.startTest();
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'M');
		Test.stopTest();
		
		WSSAPContratosPedidos.Posicion_element position = converter.generateRequest().ListaPosiciones.Posicion[0];
		
		System.assertEquals(0, position.Condiciones.size());
	}
	
	private static testMethod void ifTheOperationIsSimulation_TheDiscountsShouldBeSimulations() {
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		List<Beneficiario__c> recipients = addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		Descuento_Recargo_Aplicado__c appliedDiscount = applyDiscount(
			aCoverage,
			aDiscount,
			Date.newInstance(2017, 9, 30),
			Date.newInstance(2018, 12, 1)
		);
		
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'S');
		WSSAPContratosPedidos.Posicion_element position = converter.generateRequest().ListaPosiciones.Posicion[0];
		
		System.assertEquals('S', position.Condiciones[0].TipoOperacion);
	}
	
	//====================================
	//Other
	private static testMethod void itShouldBePosibleToKnowIfTheCallToGetTheOldPositionNumbersFailed() {
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'M');
		
		//Should fail as there are no settings inserted for the webservice.
		System.assertEquals(true, converter.oldPositionNumbersFailed);
	}
	
	private static testMethod void itShouldBePosibleToUpdateTheAppliedDiscountsThatWereSent() {
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		List<Beneficiario__c> recipients = addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		Descuento_Recargo_Aplicado__c appliedDiscount = applyDiscount(
			aCoverage,
			aDiscount,
			Date.newInstance(2017, 9, 30),
			Date.newInstance(2018, 12, 1)
		);
		
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'A');
		converter.generateRequest();
		
		converter.updateDiscountRelations();
		
		Descuento_Recargo_Aplicado__c appliedDiscountInDB = [
			SELECT Id, Estado_de_envio__c
			FROM Descuento_Recargo_Aplicado__c
			WHERE Id = :appliedDiscount.Id
		];
		
		System.assertEquals('Enviado', appliedDiscountInDB.Estado_de_envio__c);
	}
	
	private static testMethod void itShouldBePosibleToUpdateTheAppliedDiscountsThatWereEliminated() {
		Cobertura__c aCoverage = createCoverage(aProduct, new List<Id>());
		String ivaTreatment = Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()[0].getValue();
		List<Beneficiario__c> recipients = addPersonRecipients(aCoverage, 20, ivaTreatment, aProvinceSetting.Name);
		Descuento_Recargo_Aplicado__c appliedDiscount = applyDiscount(
			aCoverage,
			aDiscount,
			Date.newInstance(2017, 9, 30),
			Date.newInstance(2018, 12, 1)
		);
		appliedDiscount.Estado_de_envio__c = 'Baja';
		update appliedDiscount;
		
		ContractToSAPConverter converter = new ContractToSAPConverter(aContract.Id, 'A');
		converter.generateRequest();
		
		converter.updateDiscountRelations();
		
		Descuento_Recargo_Aplicado__c appliedDiscountInDB = [
			SELECT Id, Estado_de_envio__c
			FROM Descuento_Recargo_Aplicado__c
			WHERE Id = :appliedDiscount.Id
		];
		
		System.assertEquals('Enviado baja', appliedDiscountInDB.Estado_de_envio__c);
	}
	
	//==========================================================================
	//Object creation
	static Cobertura__c createCoverage(Product2 product, List<Id> additionals) {
		String aditionalsStr = '';
		for(Id additionalId : additionals) {
			aditionalsStr += additionalId + ';';
		}
		Cobertura__c result = Build.aCoverage().forProduct(product).forContract(aContract)
			.withAditionals(aditionalsStr).build();
		insert result;
		return result;
	}
	
	static List<Beneficiario__c> addPersonRecipients(Cobertura__c coverage, integer amount, string ivaTreatment, String province) {
		RecordType personRecipientType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Beneficiario__c'
				AND DeveloperName = 'Persona'
				AND IsActive = true
		];
		
		List<Beneficiario__c> recipients = new List<Beneficiario__c>();
		for(Integer i = 0; i < amount; i++) {
			recipients.add(
				Build.aRecipient().forContract(aContract).forHolder(aHolder).withActiveStatus()
					.withRecordType(personRecipientType).withProvince(province)
					.withIVATreatment(ivaTreatment).build()
			);
		}
		insert recipients;
		
		List<Cobertura_de_Beneficiario__c> relationsWithCoverage = new List<Cobertura_de_Beneficiario__c>();
		for(Beneficiario__c recipient : recipients) {
			relationsWithCoverage.add(
				Build.aCoverageRecipientRelation().forRecipient(recipient).forCoverage(coverage).Build()
			);
		}
		insert relationsWithCoverage;
		
		return recipients;
	}
	
	static integer addressNumber = 1;
	static Beneficiario__c addAddressRecipient(string ivaTreatment, String province) {
		RecordType addressRecipientType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Beneficiario__c'
				AND DeveloperName = 'Domicilio'
				AND IsActive = true
		];
		String withAddressCategory = Beneficiario__c.Rubro_del_domicilio__c.getDescribe().getPicklistValues()[0].getValue();
		Beneficiario__c recipient = Build.aRecipient().forContract(aContract).withActiveStatus().forHolder(aHolder)
			.withUniqueCode('123wad324' + String.valueOf(addressNumber).leftPad(3, '0'))
			.withProvince(province).withIVATreatment(ivaTreatment).withAddressCategory(withAddressCategory)
			.withRecordType(addressRecipientType).build();
		insert recipient;
		addressNumber++;
		
		return recipient;
	}
	
	static Cobertura_de_Beneficiario__c addAddressRecipientRelation(
		Cobertura__c coverage,
		Beneficiario__c recipient,
		integer amount,
		integer amountInTransit
	) {
		Cobertura_de_Beneficiario__c relationWithCoverage = Build.aCoverageRecipientRelation()
			.forRecipient(recipient).forCoverage(coverage).withDirectionAmount(amount)
			.withDirectionTransitAmount(amountInTransit).Build();
		insert relationWithCoverage;
		return relationWithCoverage;
	}
	
	static Descuento_Recargo_Aplicado__c applyDiscount(Cobertura__c coverage, Descuento_Recargo__c discount, Date startDate, Date endDate) {
		Descuento_Recargo_Aplicado__c result = Build.anAppliedDiscount().forCoverage(coverage)
			.forDiscount(discount).withStartDate(startDate).withEndDate(endDate).build();
        insert result;
		return result;
	}
	
	static Descuento_Recargo_Aplicado__c applyCustomDiscount(Cobertura__c coverage, Descuento_Recargo__c discount, Date startDate, Date endDate, decimal customValue) {
		Descuento_Recargo_Aplicado__c result = Build.anAppliedDiscount().forCoverage(coverage)
			.forDiscount(discount).withStartDate(startDate).withEndDate(endDate).withValue(customValue).build();
		insert result;
		return result;
	}
	
	
	private static WSSAPContratosPosiciones.POSICIONES_element generateOldPosition(Product2 product, String ivaTreatment, String province, String positionNumber) {
		WSSAPContratosPosiciones.POSICIONES_element pos = new WSSAPContratosPosiciones.POSICIONES_element();
		
		pos.POSICION = positionNumber;
		pos.CONTRATO = aContract.Numero_Unico_de_Contrato_Con_Sufijo__c;
		pos.BOM = product.Numero__c;
		pos.COND_IVA = ivaTreatment;
		pos.DESTINATARIO = province;
		pos.SUFIJO = '';
		pos.MENOR_S_CARGO = '';
		pos.MOTIVO_RECHAZO = '';
		
		return pos;
	}
	
	//==========================================================================
	//Helpers
	private static String formatNumber(decimal val, integer decimals) {
		String result = String.valueOf(val);
		if(result.contains('.')) {
			List<String> parts = result.split('\\.');
			return parts[0] + '.' + parts[1].rightPad(decimals, '0');
		}
		else {
			return result + '.' + ''.rightPad(decimals, '0');
		}
	}
	
	//==========================================================================
	static Interlocutor_Provincia__c aProvinceSetting;
	static Product2 aProduct;
	static Product2 anotherProduct;
	static Descuento_Recargo__c aDiscount;
	static Descuento_Recargo__c theFreeMinorDiscount;
	static Descuento_Recargo__c theCustomDiscount;
	static Cobrador__c aCollector;
	static Account anAccount;
	static Contact aDeliveryContact;
	static Contact aBillingContact;
	static Contact aCollectionContact;
	static Contrato__c aContract;
	static Titular__c aHolder;
	static Beneficiario__c aPersonRecipient;
	static Beneficiario__c anAddressRecipient;
	
	static {
		String province = Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues()[0].getValue();
		aProvinceSetting = Build.aProvinceSetting().withName(province).withSAPCode('78yi32307u').build();
		insert aProvinceSetting;
		
		aProduct = Build.aProduct().withName('Prod 1').withNumber('Prod 1')
			.withSector(Product2.Sector__c.getDescribe().getPicklistValues()[0].getValue()).build();
		anotherProduct = Build.aProduct().withName('Prod 2').withNumber('Prod 2')
			.withSector(Product2.Sector__c.getDescribe().getPicklistValues()[1].getValue()).build();
		insert new List<Product2> {aProduct, anotherProduct};
		
		aDiscount = Build.aDiscount().withName('A discount')
			.withValue(21.34).withUnit('%').withDiscountCode('ZJUE').build();
		theFreeMinorDiscount = Build.aDiscount().withName('One minor free')
			.withValue(100).withUnit('%').withDiscountCode('ZDV1').build();
		theCustomDiscount = Build.aDiscount().withName('Custom')
			.withUnit('%').withDiscountCode('ZDV0').build();
		insert new List<Descuento_Recargo__c> {aDiscount, theFreeMinorDiscount, theCustomDiscount};
		
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
		
		aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
	}
}
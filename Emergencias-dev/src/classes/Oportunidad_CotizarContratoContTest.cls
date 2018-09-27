@isTest
private class Oportunidad_CotizarContratoContTest {
	@isTest
	private static void itShouldBePosibleToKnowIfTheContractIsReadyToBeSimulated() {
		Product2 aProduct = Build.aProduct().build();
		insert aProduct;
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount)
			.withDischargeTypeNew().build();
		insert anOpportunity;
		
		Contrato__c aContract = [
			SELECT Id
			FROM Contrato__c
			WHERE Id IN (SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		];
		Titular__c aHolder = [
			SELECT Id, Numero_de_Titular__c, Ult_Numero_de_beneficiario__c, Cliente__c
			FROM Titular__c
			WHERE Contrato__c = :aContract.Id
			LIMIT 1
		];
		
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract)
			.forHolder(aHolder).build();
		insert aRecipient;
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract)
			.forProduct(aProduct).build();
		insert aCoverage;
		Cobertura_de_Beneficiario__c aCoverageRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(aCoverage).build();
		insert aCoverageRecipientRelation;
		
		System.assertEquals(
			true,
			Oportunidad_CotizarContratoController.canBeSimulated(aContract.Id)
		);
	}
	
	@isTest
	private static void ifThereAreNoRecipientProductRelations_TheContractShouldNotBeReadyForSimulation() {
		Product2 aProduct = Build.aProduct().build();
		insert aProduct;
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount)
			.withDischargeTypeNew().build();
		insert anOpportunity;
		
		Contrato__c aContract = [
			SELECT Id
			FROM Contrato__c
			WHERE Id IN (SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		];
		Titular__c aHolder = [
			SELECT Id, Numero_de_Titular__c, Ult_Numero_de_beneficiario__c, Cliente__c
			FROM Titular__c
			WHERE Contrato__c = :aContract.Id
			LIMIT 1
		];
		
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract)
			.forHolder(aHolder).build();
		insert aRecipient;
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract)
			.forProduct(aProduct).build();
		insert aCoverage;
		
		System.assertEquals(
			false,
			Oportunidad_CotizarContratoController.canBeSimulated(aContract.Id)
		);
	}
	
	@isTest
	private static void itShouldBePosibleToSendAContractForSimulation() {
		//Server mock
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		
		//=============================================
		//Server response
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In response =
			new WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In();
		response.Msg = new List<WSSAPContratosPedidos.Msg_element>();
		WSSAPContratosPedidos.Msg_element message = new WSSAPContratosPedidos.Msg_element();
		message.Tipo = 'S';
		response.Msg.add(message);
		response.Documento = new WSSAPContratosPedidos.Documento_element();
		response.Documento.Posiciones = new List<WSSAPContratosPedidos.Posiciones_element>();
		WSSAPContratosPedidos.Posiciones_element respPostion =
			new WSSAPContratosPedidos.Posiciones_element();
		respPostion.Material = '';
		respPostion.Posicion = '000100';
		respPostion.Condiciones = new List<WSSAPContratosPedidos.Condicion_IN_element>();
		WSSAPContratosPedidos.Condicion_IN_element respCondition =
			new WSSAPContratosPedidos.Condicion_IN_element();
		respCondition.Condicion = 'ZPR2';
		respCondition.Importe = '123.00';
		
		respPostion.Condiciones.add(respCondition);
		response.Documento.Posiciones.add(respPostion);
		serverMock.responseObjs.add(response);
		//=============================================
		//SAP configuration
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir')
			.withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		Cuenta_de_cotizador__c simulationAccountSettings = Build.someSimulationAccountSettings().build();
		insert simulationAccountSettings;
		//=============================================
		//Contract data
		Product2 aProduct = Build.aProduct().build();
		insert aProduct;
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount)
			.withDischargeTypeNew().build();
		insert anOpportunity;
		
		Contrato__c aContract = [
			SELECT Id
			FROM Contrato__c
			WHERE Id IN (SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		];
		Titular__c aHolder = [
			SELECT Id, Numero_de_Titular__c, Ult_Numero_de_beneficiario__c, Cliente__c
			FROM Titular__c
			WHERE Contrato__c = :aContract.Id
			LIMIT 1
		];
		
		Schema.PicklistEntry provincePicklist = Beneficiario__c.Provincia1__c.getDescribe()
			.getPicklistValues()[0];
		Schema.PicklistEntry ivaPicklist = Beneficiario__c.Tratamiento_IVA__c.getDescribe()
			.getPicklistValues()[0];
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract)
			.forHolder(aHolder).withIVATreatment(ivaPicklist.getValue())
			.withProvince(provincePicklist.getValue()).build();
		insert aRecipient;
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract)
			.forProduct(aProduct).build();
		insert aCoverage;
		Cobertura_de_Beneficiario__c aCoverageRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(aCoverage).build();
		insert aCoverageRecipientRelation;
		
		Interlocutor_Provincia__c aProvinceSetting = Build.aProvinceSetting()
			.withName(provincePicklist.getValue()).withSAPCode('78yi32307u').build();
		insert aProvinceSetting;
		
		//=============================================
		//Execution
		Test.startTest();
		ContractSAPSendSimulate.ProductSimulationResult result =
			(ContractSAPSendSimulate.ProductSimulationResult)JSON.deserialize(
				Oportunidad_CotizarContratoController.simulateContract(aContract.Id),
				ContractSAPSendSimulate.ProductSimulationResult.class
			);
		Test.stopTest();
		
		//=============================================
		//Asserts
		System.assertEquals(1, serverMock.receivedRequests);
		
		System.assertEquals(message.Tipo, result.status.Tipo);
		
		System.assertEquals(
			ContractSAPSendSimulate.numberFromSAPValue(respCondition.Importe),
			result.positions[0].noIvaPrice
		);
		System.assertEquals(
			provincePicklist.getLabel(),
			result.positions[0].provinceCode
		);
		System.assertEquals(
			ivaPicklist.getLabel(),
			result.positions[0].ivaTreatment
		);
	}
	
	@isTest
	private static void thePriceInTheConditionOfASpecialTypeShouldBeSavedAsIva() {
		//Server mock
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		
		//=============================================
		//Server response
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In response =
			new WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In();
		response.Msg = new List<WSSAPContratosPedidos.Msg_element>();
		WSSAPContratosPedidos.Msg_element message = new WSSAPContratosPedidos.Msg_element();
		message.Tipo = 'S';
		response.Msg.add(message);
		response.Documento = new WSSAPContratosPedidos.Documento_element();
		response.Documento.Posiciones = new List<WSSAPContratosPedidos.Posiciones_element>();
		WSSAPContratosPedidos.Posiciones_element respPostion =
			new WSSAPContratosPedidos.Posiciones_element();
		respPostion.Material = '';
		respPostion.Posicion = '000100';
		respPostion.Condiciones = new List<WSSAPContratosPedidos.Condicion_IN_element>();
		WSSAPContratosPedidos.Condicion_IN_element respCondition =
			new WSSAPContratosPedidos.Condicion_IN_element();
		respCondition.Condicion = 'J1AX';
		respCondition.Importe = '123.00';
		
		respPostion.Condiciones.add(respCondition);
		response.Documento.Posiciones.add(respPostion);
		serverMock.responseObjs.add(response);
		//=============================================
		//SAP configuration
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir')
			.withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		Cuenta_de_cotizador__c simulationAccountSettings = Build.someSimulationAccountSettings().build();
		insert simulationAccountSettings;
		//=============================================
		//Contract data
		Product2 aProduct = Build.aProduct().build();
		insert aProduct;
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount)
			.withDischargeTypeNew().build();
		insert anOpportunity;
		
		Contrato__c aContract = [
			SELECT Id
			FROM Contrato__c
			WHERE Id IN (SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		];
		Titular__c aHolder = [
			SELECT Id, Numero_de_Titular__c, Ult_Numero_de_beneficiario__c, Cliente__c
			FROM Titular__c
			WHERE Contrato__c = :aContract.Id
			LIMIT 1
		];
		
		Schema.PicklistEntry provincePicklist = Beneficiario__c.Provincia1__c.getDescribe()
			.getPicklistValues()[0];
		Schema.PicklistEntry ivaPicklist = Beneficiario__c.Tratamiento_IVA__c.getDescribe()
			.getPicklistValues()[0];
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract)
			.forHolder(aHolder).withIVATreatment(ivaPicklist.getValue())
			.withProvince(provincePicklist.getValue()).build();
		insert aRecipient;
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract)
			.forProduct(aProduct).build();
		insert aCoverage;
		Cobertura_de_Beneficiario__c aCoverageRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(aCoverage).build();
		insert aCoverageRecipientRelation;
		
		Interlocutor_Provincia__c aProvinceSetting = Build.aProvinceSetting()
			.withName(provincePicklist.getValue()).withSAPCode('78yi32307u').build();
		insert aProvinceSetting;
		
		//=============================================
		//Execution
		Test.startTest();
		ContractSAPSendSimulate.ProductSimulationResult result =
			(ContractSAPSendSimulate.ProductSimulationResult)JSON.deserialize(
				Oportunidad_CotizarContratoController.simulateContract(aContract.Id),
				ContractSAPSendSimulate.ProductSimulationResult.class
			);
		Test.stopTest();
		
		//=============================================
		//Asserts
		System.assertEquals(
			ContractSAPSendSimulate.numberFromSAPValue(respCondition.Importe),
			result.positions[0].priceIva
		);
	}
	
	@isTest
	private static void ifTheSAPServerReturnsAnError_PositionsShouldNotGetRecreatedAndItShouldBePosibleToShowTheError() {
		//Server mock
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		
		//=============================================
		//Server response
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In response =
			new WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In();
		response.Msg = new List<WSSAPContratosPedidos.Msg_element>();
		WSSAPContratosPedidos.Msg_element message = new WSSAPContratosPedidos.Msg_element();
		message.Tipo = 'E';
		message.Descripcion = 'Hochie mochie!';
		response.Msg.add(message);
		serverMock.responseObjs.add(response);
		//=============================================
		//SAP configuration
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir')
			.withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		Cuenta_de_cotizador__c simulationAccountSettings = Build.someSimulationAccountSettings().build();
		insert simulationAccountSettings;
		//=============================================
		//Contract data
		Product2 aProduct = Build.aProduct().build();
		insert aProduct;
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount)
			.withDischargeTypeNew().build();
		insert anOpportunity;
		
		Contrato__c aContract = [
			SELECT Id
			FROM Contrato__c
			WHERE Id IN (SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		];
		Titular__c aHolder = [
			SELECT Id, Numero_de_Titular__c, Ult_Numero_de_beneficiario__c, Cliente__c
			FROM Titular__c
			WHERE Contrato__c = :aContract.Id
			LIMIT 1
		];
		
		Schema.PicklistEntry provincePicklist = Beneficiario__c.Provincia1__c.getDescribe()
			.getPicklistValues()[0];
		Schema.PicklistEntry ivaPicklist = Beneficiario__c.Tratamiento_IVA__c.getDescribe()
			.getPicklistValues()[0];
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract)
			.forHolder(aHolder).withIVATreatment(ivaPicklist.getValue())
			.withProvince(provincePicklist.getValue()).build();
		insert aRecipient;
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract)
			.forProduct(aProduct).build();
		insert aCoverage;
		Cobertura_de_Beneficiario__c aCoverageRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(aCoverage).build();
		insert aCoverageRecipientRelation;
		
		Interlocutor_Provincia__c aProvinceSetting = Build.aProvinceSetting()
			.withName(provincePicklist.getValue()).withSAPCode('78yi32307u').build();
		insert aProvinceSetting;
		
		//=============================================
		//Execution
		Test.startTest();
		ContractSAPSendSimulate.ProductSimulationResult result =
			(ContractSAPSendSimulate.ProductSimulationResult)JSON.deserialize(
				Oportunidad_CotizarContratoController.simulateContract(aContract.Id),
				ContractSAPSendSimulate.ProductSimulationResult.class
			);
		Test.stopTest();
		
		//=============================================
		//Asserts
		System.assertEquals(message.Tipo, result.status.Tipo);
		System.assertEquals(message.Descripcion, result.status.Descripcion);
	}
	
	//TODO Free minor discount
}
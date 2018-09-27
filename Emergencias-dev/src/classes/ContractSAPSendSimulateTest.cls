@isTest
private class ContractSAPSendSimulateTest {
	//Basic send simulation
	@isTest
	private static void itShouldBePosibleToSendASimulationToSAPFromPositions() {
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
		
		//=============================================
		//Simulation request
		WSSAPContratosPedidos.Pedido_element contractRequest = new WSSAPContratosPedidos.Pedido_element();
		contractRequest.Cabecera = new WSSAPContratosPedidos.Cabecera_element();
		contractRequest.ListaPosiciones = new WSSAPContratosPedidos.ListaPosiciones_element();
		contractRequest.ListaPosiciones.posicion = new List<WSSAPContratosPedidos.Posicion_element>();
		
		//=============================================
		//Execution
		Test.startTest();
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In result =
			ContractSAPSendSimulate.sendSimulation(contractRequest);
		Test.stopTest();
		
		//=============================================
		//Assertions
		System.assertEquals(response, result);
		System.assertEquals(
			contractRequest,
			((WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out)serverMock.soapRequest).Pedido[0]
		);
	}
	
	@isTest
	private static void ifTheSettingsForSAPAreNotSet_AnErrorResponseShouldBeReturnedWhenSendingForSimulation() {
		//=============================================
		//Simulation request
		WSSAPContratosPedidos.Pedido_element contractRequest = new WSSAPContratosPedidos.Pedido_element();
		contractRequest.Cabecera = new WSSAPContratosPedidos.Cabecera_element();
		contractRequest.ListaPosiciones = new WSSAPContratosPedidos.ListaPosiciones_element();
		contractRequest.ListaPosiciones.posicion = new List<WSSAPContratosPedidos.Posicion_element>();
		
		//=============================================
		//Execution
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In result =
			ContractSAPSendSimulate.sendSimulation(contractRequest);
		
		//=============================================
		//Assertions
		System.assertNotEquals(null, result);
		System.assertEquals(1, result.Msg.size());
		System.assertEquals('ESF3', result.Msg[0].Tipo);
	}
	
	@isTest
	private static void ifSAPDoesntReturnAResponse_AnErrorMessageShouldBeGenerated() {
		//Server mock
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		
		//=============================================
		//SAP configuration
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir')
			.withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		
		//=============================================
		//Simulation request
		WSSAPContratosPedidos.Pedido_element contractRequest = new WSSAPContratosPedidos.Pedido_element();
		contractRequest.Cabecera = new WSSAPContratosPedidos.Cabecera_element();
		contractRequest.ListaPosiciones = new WSSAPContratosPedidos.ListaPosiciones_element();
		contractRequest.ListaPosiciones.posicion = new List<WSSAPContratosPedidos.Posicion_element>();
		
		//=============================================
		//Execution
		Test.startTest();
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In result =
			ContractSAPSendSimulate.sendSimulation(contractRequest);
		Test.stopTest();
		
		//=============================================
		//Assertions
		System.assertNotEquals(null, result);
		System.assertEquals(1, result.Msg.size());
		System.assertEquals('ESF1', result.Msg[0].Tipo);
	}
	
	@isTest
	private static void ifThereIsANetworkError_AnErrorMessageShouldBeGenerated() {
		//Server mock
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		serverMock.simulateNetworkError = true;
		Test.setMock(System.WebServiceMock.class, serverMock);
		
		//=============================================
		//Server response
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In response =
			new WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In();
		response.Msg = new List<WSSAPContratosPedidos.Msg_element>();
		WSSAPContratosPedidos.Msg_element message = new WSSAPContratosPedidos.Msg_element();
		message.Tipo = 'S';
		response.Msg.add(message);
		
		serverMock.responseObjs.add(response);
		//=============================================
		//SAP configuration
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir')
			.withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		
		//=============================================
		//Simulation request
		WSSAPContratosPedidos.Pedido_element contractRequest = new WSSAPContratosPedidos.Pedido_element();
		contractRequest.Cabecera = new WSSAPContratosPedidos.Cabecera_element();
		contractRequest.ListaPosiciones = new WSSAPContratosPedidos.ListaPosiciones_element();
		contractRequest.ListaPosiciones.posicion = new List<WSSAPContratosPedidos.Posicion_element>();
		
		//=============================================
		//Execution
		Test.startTest();
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In result =
			ContractSAPSendSimulate.sendSimulation(contractRequest);
		Test.stopTest();
		
		//=============================================
		//Assertions
		System.assertNotEquals(null, result);
		System.assertEquals(1, result.Msg.size());
		System.assertEquals('ESF2', result.Msg[0].Tipo);
	}
	
	//==============================================================================================
	//send simulation from AgregarProductos page.
	@isTest
	private static void itShouldBePosibleToSendForSimulationToSAPFromPositionsCreatedInTheAddProductsPage() {
		decimal expectedPrice = 123;
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
		respCondition.Importe = ContractToSAPConverterBase.formatNumber(expectedPrice, 2);
		
		respPostion.Condiciones.add(respCondition);
		response.Documento.Posiciones.add(respPostion);
		serverMock.responseObjs.add(response);
		//=============================================
		//SAP configuration
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir')
			.withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		
		//=============================================
		//Simulation request
		Product2 aProduct = Build.aProduct().withName('Prod').withNumber('Prod')
			.withSector(Product2.Sector__c.getDescribe().getPicklistValues()[0].getValue()).build();
		insert aProduct;
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).build();
		insert aContract;
		
		AgregarProductosController.ProductToAddWrapper productWrapper =
			new AgregarProductosController.ProductToAddWrapper(
				aContract.Id,
				aProduct,
				'userSalespersonGroup',
				'accountType',
				false,
				null,
				0,
				null
			);
		
		productWrapper.nextPosition.ivaTreatment = 'BG';
		productWrapper.nextPosition.provinceCode = '123';
		productWrapper.nextPosition.isInTransit = false;
		productWrapper.nextPosition.amount = 3;
		productWrapper.addPosition();
		
		List<AgregarProductosController.ProductToAddWrapper> products =
			new List<AgregarProductosController.ProductToAddWrapper>();
		products.add(productWrapper);
		
		//=============================================
		//Execution
		Test.startTest();
		ContractSAPSendSimulate.ProductSimulationResult result =
			ContractSAPSendSimulate.simulateProductPositions(aContract.Id, products);
		Test.stopTest();
		
		//=============================================
		//Assertions
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out sentRequest =
			((WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out)serverMock.soapRequest);
		System.assertEquals(1, sentRequest.Pedido[0].ListaPosiciones.Posicion.size());
		
		System.assertEquals(response.Msg[0], result.status);
		System.assertEquals(1, result.positions.size());
		System.assertEquals(expectedPrice, result.positions[0].noIvaPrice);
		System.assertEquals(aProduct.Numero__c, result.positions[0].productNumber);
		System.assertEquals(aProduct.Sector__c, result.positions[0].productSector);
	}
	
	@isTest
	private static void positionsWithNoAmountShouldNotBeSent() {
		decimal expectedPrice = 123;
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
		
		serverMock.responseObjs.add(response);
		//=============================================
		//SAP configuration
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir')
			.withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		
		//=============================================
		//Simulation request
		Product2 aProduct = Build.aProduct().withName('Prod').withNumber('Prod')
			.withSector(Product2.Sector__c.getDescribe().getPicklistValues()[0].getValue()).build();
		insert aProduct;
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).build();
		insert aContract;
		
		AgregarProductosController.ProductToAddWrapper productWrapper =
			new AgregarProductosController.ProductToAddWrapper(
				aContract.Id,
				aProduct,
				'userSalespersonGroup',
				'accountType',
				false,
				null,
				0,
				null
			);
		
		productWrapper.nextPosition.ivaTreatment = 'BG';
		productWrapper.nextPosition.provinceCode = '123';
		productWrapper.nextPosition.isInTransit = false;
		productWrapper.addPosition();
		
		List<AgregarProductosController.ProductToAddWrapper> products =
			new List<AgregarProductosController.ProductToAddWrapper>();
		products.add(productWrapper);
		
		//=============================================
		//Execution
		Test.startTest();
		ContractSAPSendSimulate.ProductSimulationResult result =
			ContractSAPSendSimulate.simulateProductPositions(aContract.Id, products);
		Test.stopTest();
		
		//=============================================
		//Assertions
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out sentRequest =
			((WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out)serverMock.soapRequest);
		System.assertEquals(0, sentRequest.Pedido[0].ListaPosiciones.Posicion.size());
	}
	
	@isTest
	private static void whenAPositionIsInTransitAndItHasAParticularProduct_TheProductNumberShouldBeAlteredToReflectThis() {
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
		respCondition.Importe = '100.00';
		
		respPostion.Condiciones.add(respCondition);
		response.Documento.Posiciones.add(respPostion);
		serverMock.responseObjs.add(response);
		//=============================================
		//SAP configuration
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir')
			.withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		
		//=============================================
		//Simulation request
		Product2 aProduct = Build.aProduct().withName('Prod').withNumber('Prod')
			.withSector(Product2.Sector__c.getDescribe().getPicklistValues()[0].getValue()).build();
		insert aProduct;
		Producto_Transito__c separationSetting = Build.aProductSeparationSetting().withName(aProduct.Numero__c).build();
		insert separationSetting;
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).build();
		insert aContract;
		
		AgregarProductosController.ProductToAddWrapper productWrapper =
			new AgregarProductosController.ProductToAddWrapper(
				aContract.Id,
				aProduct,
				'userSalespersonGroup',
				'accountType',
				false,
				null,
				0,
				null
			);
		
		productWrapper.nextPosition.ivaTreatment = 'BG';
		productWrapper.nextPosition.provinceCode = '123';
		productWrapper.nextPosition.isInTransit = true;
		productWrapper.nextPosition.amount = 3;
		productWrapper.addPosition();
		
		List<AgregarProductosController.ProductToAddWrapper> products =
			new List<AgregarProductosController.ProductToAddWrapper>();
		products.add(productWrapper);
		
		//=============================================
		//Execution
		Test.startTest();
		ContractSAPSendSimulate.ProductSimulationResult result =
			ContractSAPSendSimulate.simulateProductPositions(aContract.Id, products);
		Test.stopTest();
		
		//=============================================
		//Assertions
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out sentRequest =
			((WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out)serverMock.soapRequest);
		System.assertEquals(
			aProduct.Numero__c + ' TRA',
			sentRequest.Pedido[0].ListaPosiciones.Posicion[0].CodigoMaterial
		);
	}
	
	@isTest
	private static void ifThereIsAnErrorInTheSimulationNoPositionsShouldBeReturned() {
		//Server mock
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		serverMock.simulateNetworkError = true;
		Test.setMock(System.WebServiceMock.class, serverMock);
		
		//=============================================
		//Server response
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In response =
			new WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In();
		response.Msg = new List<WSSAPContratosPedidos.Msg_element>();
		WSSAPContratosPedidos.Msg_element message = new WSSAPContratosPedidos.Msg_element();
		message.Tipo = 'S';
		response.Msg.add(message);
		
		serverMock.responseObjs.add(response);
		//=============================================
		//SAP configuration
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir')
			.withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		
		//=============================================
		//Simulation request
		Product2 aProduct = Build.aProduct().withName('Prod').withNumber('Prod')
			.withSector(Product2.Sector__c.getDescribe().getPicklistValues()[0].getValue()).build();
		insert aProduct;
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).build();
		insert aContract;
		
		AgregarProductosController.ProductToAddWrapper productWrapper =
			new AgregarProductosController.ProductToAddWrapper(
				aContract.Id,
				aProduct,
				'userSalespersonGroup',
				'accountType',
				false,
				null,
				0,
				null
			);
		
		productWrapper.nextPosition.ivaTreatment = 'BG';
		productWrapper.nextPosition.provinceCode = '123';
		productWrapper.nextPosition.isInTransit = false;
		productWrapper.nextPosition.amount = 3;
		productWrapper.addPosition();
		
		List<AgregarProductosController.ProductToAddWrapper> products =
			new List<AgregarProductosController.ProductToAddWrapper>();
		products.add(productWrapper);
		
		//=============================================
		//Execution
		Test.startTest();
		ContractSAPSendSimulate.ProductSimulationResult result =
			ContractSAPSendSimulate.simulateProductPositions(aContract.Id, products);
		Test.stopTest();
		
		//=============================================
		//Assertions
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out sentRequest =
			((WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out)serverMock.soapRequest);
		System.assertEquals(1, sentRequest.Pedido[0].ListaPosiciones.Posicion.size());
		
		System.assertEquals('ESF2', result.status.Tipo);
		System.assertEquals(0, result.positions.size());
	}
	
	@isTest
	private static void aProductsAdditionalsShouldBeSentAsSeparatePositions() {
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
		//Position 100
		WSSAPContratosPedidos.Posiciones_element respPostion =
			new WSSAPContratosPedidos.Posiciones_element();
		respPostion.Material = '';
		respPostion.Posicion = '000100';
		respPostion.Condiciones = new List<WSSAPContratosPedidos.Condicion_IN_element>();
		WSSAPContratosPedidos.Condicion_IN_element respCondition =
			new WSSAPContratosPedidos.Condicion_IN_element();
		respCondition.Condicion = 'ZPR2';
		respCondition.Importe = '100.00';
		
		respPostion.Condiciones.add(respCondition);
		response.Documento.Posiciones.add(respPostion);
		//Position 200
		respPostion = new WSSAPContratosPedidos.Posiciones_element();
		respPostion.Material = '';
		respPostion.Posicion = '000200';
		respPostion.Condiciones = new List<WSSAPContratosPedidos.Condicion_IN_element>();
		respCondition = new WSSAPContratosPedidos.Condicion_IN_element();
		respCondition.Condicion = 'ZPR2';
		respCondition.Importe = '100.00';
		
		respPostion.Condiciones.add(respCondition);
		response.Documento.Posiciones.add(respPostion);
		
		serverMock.responseObjs.add(response);
		//=============================================
		//SAP configuration
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir')
			.withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		
		//=============================================
		//Simulation request
		Product2 aProduct = Build.aProduct().withName('Prod').withNumber('Prod')
			.withSector(Product2.Sector__c.getDescribe().getPicklistValues()[0].getValue()).build();
		Product2 aditionalProduct = Build.aProduct().withName('Adition').withNumber('Adition')
			.withSector(Product2.Sector__c.getDescribe().getPicklistValues()[0].getValue()).build();
		insert new List<Product2> {aProduct, aditionalProduct};
		Adicional_de_producto__c additionalProductRelation = Build.anAdditionalProductRelation()
			.forMainProduct(aProduct).forAdditionalProduct(aditionalProduct).build();
		insert additionalProductRelation;
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).build();
		insert aContract;
		
		AgregarProductosController.ProductToAddWrapper productWrapper =
			new AgregarProductosController.ProductToAddWrapper(
				aContract.Id,
				aProduct,
				'userSalespersonGroup',
				'accountType',
				false,
				null,
				0,
				null
			);
		
		//HACK since selected additionals are saved on 'set' of the property, adding to the
		//	resulting list will not "save" the additional.
		productWrapper.SelectedAdditionals = new List<String> {aditionalProduct.Id};
		
		productWrapper.nextPosition.ivaTreatment = 'BG';
		productWrapper.nextPosition.provinceCode = '123';
		productWrapper.nextPosition.isInTransit = false;
		productWrapper.nextPosition.amount = 3;
		productWrapper.addPosition();
		
		List<AgregarProductosController.ProductToAddWrapper> products =
			new List<AgregarProductosController.ProductToAddWrapper>();
		products.add(productWrapper);
		
		//=============================================
		//Execution
		Test.startTest();
		ContractSAPSendSimulate.ProductSimulationResult result =
			ContractSAPSendSimulate.simulateProductPositions(aContract.Id, products);
		Test.stopTest();
		
		//=============================================
		//Assertions
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out sentRequest =
			((WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out)serverMock.soapRequest);
		System.assertEquals(2, sentRequest.Pedido[0].ListaPosiciones.Posicion.size());
	}
	
	@isTest
	private static void discountsShouldBeAppliedToPositionsAndAdditionals() {
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
		//Position 100
		WSSAPContratosPedidos.Posiciones_element respPostion =
			new WSSAPContratosPedidos.Posiciones_element();
		respPostion.Material = '';
		respPostion.Posicion = '000100';
		respPostion.Condiciones = new List<WSSAPContratosPedidos.Condicion_IN_element>();
		WSSAPContratosPedidos.Condicion_IN_element respCondition =
			new WSSAPContratosPedidos.Condicion_IN_element();
		respCondition.Condicion = 'ZPR2';
		respCondition.Importe = '100.00';
		
		respPostion.Condiciones.add(respCondition);
		response.Documento.Posiciones.add(respPostion);
		//Position 200
		respPostion = new WSSAPContratosPedidos.Posiciones_element();
		respPostion.Material = '';
		respPostion.Posicion = '000200';
		respPostion.Condiciones = new List<WSSAPContratosPedidos.Condicion_IN_element>();
		respCondition = new WSSAPContratosPedidos.Condicion_IN_element();
		respCondition.Condicion = 'ZPR2';
		respCondition.Importe = '100.00';
		
		respPostion.Condiciones.add(respCondition);
		response.Documento.Posiciones.add(respPostion);
		
		serverMock.responseObjs.add(response);
		//=============================================
		//SAP configuration
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir')
			.withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		
		//=============================================
		//Simulation request
		Product2 aProduct = Build.aProduct().withName('Prod').withNumber('Prod')
			.withSector(Product2.Sector__c.getDescribe().getPicklistValues()[0].getValue()).build();
		Product2 aditionalProduct = Build.aProduct().withName('Adition').withNumber('Adition')
			.withSector(Product2.Sector__c.getDescribe().getPicklistValues()[0].getValue()).build();
		insert new List<Product2> {aProduct, aditionalProduct};
		Adicional_de_producto__c additionalProductRelation = Build.anAdditionalProductRelation()
			.forMainProduct(aProduct).forAdditionalProduct(aditionalProduct).build();
		insert additionalProductRelation;
		Descuento_Recargo__c theCustomDiscount = Build.aDiscount().withName('Custom')
			.withUnit('%').withDiscountCode('ZDV0').build();
		insert theCustomDiscount;
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).build();
		insert aContract;
		
		AgregarProductosController.ProductToAddWrapper productWrapper =
			new AgregarProductosController.ProductToAddWrapper(
				aContract.Id,
				aProduct,
				'userSalespersonGroup',
				'accountType',
				false,
				null,
				0,
				null
			);
		
		//HACK since selected additionals are saved on 'set' of the property, adding to the
		//	resulting list will not "save" the additional.
		productWrapper.SelectedAdditionals = new List<String> {aditionalProduct.Id};
            
		productWrapper.selectedDiscountType = productWrapper.AvailableDiscountOptions[0].getValue();
		productWrapper.addDiscount();
           
		productWrapper.Discounts[0].isActive = true;
		productWrapper.Discounts[0].relation.Valor__c = 12;
		
		productWrapper.nextPosition.ivaTreatment = 'BG';
		productWrapper.nextPosition.provinceCode = '123';
		productWrapper.nextPosition.isInTransit = false;
		productWrapper.nextPosition.amount = 3;
		productWrapper.addPosition();
		
		List<AgregarProductosController.ProductToAddWrapper> products =
			new List<AgregarProductosController.ProductToAddWrapper>();
		products.add(productWrapper);
		
		//=============================================
		//Execution
		Test.startTest();
		ContractSAPSendSimulate.ProductSimulationResult result =
			ContractSAPSendSimulate.simulateProductPositions(aContract.Id, products);
		Test.stopTest();
		
		//=============================================
		//Assertions
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out sentRequest =
			((WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out)serverMock.soapRequest);
		
		for(WSSAPContratosPedidos.Posicion_element position :
			sentRequest.Pedido[0].ListaPosiciones.Posicion
		) {
			System.assertEquals(1, position.Condiciones.size());
		}
	}
}
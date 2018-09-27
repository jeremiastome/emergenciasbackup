@isTest
private class ContractToSAPSimulationTest {
	//Build positions
	@isTest
	private static void itShouldBePosibleToConvertPositionsForSimulationToOutgoingPositions() {
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).build();
		insert aContract;
		
		List<SimulationPosition> positions = new List<SimulationPosition>();
		SimulationPosition position = new SimulationPosition();
		position.ivaTreatment = 'BE';
		position.provinceCode = '123';
		position.isInTransit = true;
		position.amount = 3;
		position.productNumber = 'Prod';
		position.productSector = 'Sect';
		
		positions.add(position);
		
		ContractToSAPSimulation converter = new ContractToSAPSimulation(aContract.Id, positions);
		WSSAPContratosPedidos.Pedido_element result = converter.generateRequest();
		
		System.assertNotEquals(null, result.Cabecera);
		System.assertNotEquals(null, result.ListaPosiciones);
		System.assertNotEquals(null, result.ListaPosiciones.Posicion);
		System.assertEquals(positions.size(), result.ListaPosiciones.Posicion.size());
		System.assertEquals('S', result.ListaPosiciones.Posicion[0].TipoOperacion);
		System.assertEquals('100', result.ListaPosiciones.Posicion[0].NumeroPosicion);
		System.assertEquals(position.ivaTreatment, result.ListaPosiciones.Posicion[0].CondIVABenef);
		System.assertEquals(
			ContractToSAPConverterBase.formatNumber(position.amount, 3),
			result.ListaPosiciones.Posicion[0].Cantidad
		);
		System.assertEquals(position.productSector, result.ListaPosiciones.Posicion[0].Sector);
		System.assertEquals(
			position.productNumber,
			result.ListaPosiciones.Posicion[0].CodigoMaterial
		);
		System.assertEquals(
			position.provinceCode,
			result.ListaPosiciones.Posicion[0].DestinatarioMercancias
		);
	}
	
	//==============================================================================================
	//Build conditions
	@isTest
	private static void itShouldBePosibleToConvertPositionsThatHaveDiscounts() {
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).build();
		insert aContract;
		Descuento_Recargo__c aDiscount = Build.aDiscount().withName('A discount')
			.withValue(21.34).withUnit('%').withDiscountCode('ZJUE').build();
		insert aDiscount;
		Descuento_Recargo_Aplicado__c anAppliedDiscount = Build.anAppliedDiscount()
			.withStartDate(System.today().addDays(-2)).withEndDate(System.today().addDays(10))
			.build();
		
		List<SimulationPosition> positions = new List<SimulationPosition>();
		SimulationPosition position = new SimulationPosition();
		position.ivaTreatment = 'BE';
		position.provinceCode = '123';
		position.isInTransit = true;
		position.amount = 3;
		position.productNumber = 'Prod';
		position.productSector = 'Sect';
		AgregarProductosController.DiscountToAddWrapper discountWrapper =
			new AgregarProductosController.DiscountToAddWrapper(aDiscount, anAppliedDiscount);
		
		position.discountsToSend.add(discountWrapper);
		positions.add(position);
		
		ContractToSAPSimulation converter = new ContractToSAPSimulation(aContract.Id, positions);
		WSSAPContratosPedidos.Pedido_element result = converter.generateRequest();
		
		System.assertEquals(1, result.ListaPosiciones.Posicion[0].Condiciones.size());
		System.assertEquals('S', result.ListaPosiciones.Posicion[0].Condiciones[0].TipoOperacion);
		System.assertEquals(
			aDiscount.Codigo_de_descuento__c,
			result.ListaPosiciones.Posicion[0].Condiciones[0].ClaseCondicion
		);
		System.assertEquals(
			ContractToSAPConverterBase.formatNumber(aDiscount.Valor__c, 2),
			result.ListaPosiciones.Posicion[0].Condiciones[0].Importe
		);
		System.assertEquals(aDiscount.Unidad__c, result.ListaPosiciones.Posicion[0].Condiciones[0].Unidad);
		System.assertEquals(
			ContractToSAPConverterBase.formatDate(anAppliedDiscount.Fecha_inicio__c),
			result.ListaPosiciones.Posicion[0].Condiciones[0].FechaInicioValidez
		);
		System.assertEquals(
			ContractToSAPConverterBase.formatDate(anAppliedDiscount.Fecha_Fin__c),
			result.ListaPosiciones.Posicion[0].Condiciones[0].FechaFinValidez
		);
	}
	
	@isTest
	private static void whenAddingACustomValueDiscountTheAmountShouldBeTakenFromTheRelation() {
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).build();
		insert aContract;
		Descuento_Recargo__c theCustomDiscount = Build.aDiscount().withName('Custom')
			.withUnit('%').withDiscountCode('ZDV0').build();
		insert theCustomDiscount;
		Descuento_Recargo_Aplicado__c anAppliedDiscount = Build.anAppliedDiscount()
			.withStartDate(System.today()).withEndDate(System.today()).withValue(25)
			.build();
		
		List<SimulationPosition> positions = new List<SimulationPosition>();
		SimulationPosition position = new SimulationPosition();
		position.ivaTreatment = 'BE';
		position.provinceCode = '123';
		position.isInTransit = true;
		position.amount = 3;
		position.productNumber = 'Prod';
		position.productSector = 'Sect';
		AgregarProductosController.DiscountToAddWrapper discountWrapper =
			new AgregarProductosController.DiscountToAddWrapper(theCustomDiscount, anAppliedDiscount);
		
		position.discountsToSend.add(discountWrapper);
		positions.add(position);
		
		ContractToSAPSimulation converter = new ContractToSAPSimulation(aContract.Id, positions);
		WSSAPContratosPedidos.Pedido_element result = converter.generateRequest();
		
		System.assertEquals(
			ContractToSAPConverterBase.formatNumber(anAppliedDiscount.Valor__c, 2),
			result.ListaPosiciones.Posicion[0].Condiciones[0].Importe
		);
	}
	
	@isTest
	private static void theFreeMinorDiscountShouldNotBeSent() {
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).build();
		insert aContract;
		Descuento_Recargo__c theFreeMinorDiscount = Build.aDiscount().withName('One minor free')
			.withValue(100).withUnit('%').withDiscountCode('ZDV1').build();
		insert theFreeMinorDiscount;
		Descuento_Recargo_Aplicado__c anAppliedDiscount = Build.anAppliedDiscount()
			.withStartDate(System.today().addDays(-2)).withEndDate(System.today().addDays(10))
			.build();
		
		List<SimulationPosition> positions = new List<SimulationPosition>();
		SimulationPosition position = new SimulationPosition();
		position.ivaTreatment = 'BE';
		position.provinceCode = '123';
		position.isInTransit = true;
		position.amount = 3;
		position.productNumber = 'Prod';
		position.productSector = 'Sect';
		AgregarProductosController.DiscountToAddWrapper discountWrapper =
			new AgregarProductosController.DiscountToAddWrapper(
				theFreeMinorDiscount,
				anAppliedDiscount
			);
		
		position.discountsToSend.add(discountWrapper);
		positions.add(position);
		
		ContractToSAPSimulation converter = new ContractToSAPSimulation(aContract.Id, positions);
		WSSAPContratosPedidos.Pedido_element result = converter.generateRequest();
		
		System.assertEquals(0, result.ListaPosiciones.Posicion[0].Condiciones.size());
	}
	
	@isTest
	private static void ifTheDiscountRelationDoesntHaveStartAndEndDatesSpecialDatesShouldBeUsed() {
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).build();
		insert aContract;
		Descuento_Recargo__c aDiscount = Build.aDiscount().withName('A discount')
			.withValue(21.34).withUnit('%').withDiscountCode('ZJUE').build();
		insert aDiscount;
		Descuento_Recargo_Aplicado__c anAppliedDiscount = Build.anAppliedDiscount()
			.withStartDate(null).withEndDate(null).build();
		
		List<SimulationPosition> positions = new List<SimulationPosition>();
		SimulationPosition position = new SimulationPosition();
		position.ivaTreatment = 'BE';
		position.provinceCode = '123';
		position.isInTransit = true;
		position.amount = 3;
		position.productNumber = 'Prod';
		position.productSector = 'Sect';
		AgregarProductosController.DiscountToAddWrapper discountWrapper =
			new AgregarProductosController.DiscountToAddWrapper(aDiscount, anAppliedDiscount);
		
		position.discountsToSend.add(discountWrapper);
		positions.add(position);
		
		ContractToSAPSimulation converter = new ContractToSAPSimulation(aContract.Id, positions);
		WSSAPContratosPedidos.Pedido_element result = converter.generateRequest();
		
		System.assertEquals(
			ContractToSAPConverterBase.formatDate(System.today()),
			result.ListaPosiciones.Posicion[0].Condiciones[0].FechaInicioValidez
		);
		System.assertEquals(
			'99991231',
			result.ListaPosiciones.Posicion[0].Condiciones[0].FechaFinValidez
		);
	}
	
	//==============================================================================================
	//Build prices
	@isTest
	private static void itShouldBePosibleToObtainThePriceForAPosition() {
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).build();
		insert aContract;
		
		List<SimulationPosition> positions = new List<SimulationPosition>();
		SimulationPosition position = new SimulationPosition();
		position.ivaTreatment = 'BE';
		position.provinceCode = '123';
		position.isInTransit = true;
		position.amount = 3;
		position.productNumber = 'Prod';
		position.productSector = 'Sect';
		
		positions.add(position);
		
		decimal expectedPrice = 0;
		decimal expectedIVA;
		//=================================
		//Server response
		List<WSSAPContratosPedidos.Posiciones_element> responsePositions =
			new List<WSSAPContratosPedidos.Posiciones_element>();
		
		WSSAPContratosPedidos.Posiciones_element respPosition =
			new WSSAPContratosPedidos.Posiciones_element();
		respPosition.Material = position.productNumber;
		respPosition.Posicion = '000100';
		respPosition.Condiciones = new List<WSSAPContratosPedidos.Condicion_IN_element>();
		//=================================
		//Price part 1 condition
		WSSAPContratosPedidos.Condicion_IN_element respCondition =
			new WSSAPContratosPedidos.Condicion_IN_element();
		respCondition.Condicion = 'ZPR2';
		respCondition.Importe = '123.00';
		
		expectedPrice += Decimal.valueOf(respCondition.Importe);
		respPosition.Condiciones.add(respCondition);
		//=================================
		//Price part 2 condition
		respCondition = new WSSAPContratosPedidos.Condicion_IN_element();
		respCondition.Condicion = 'ZPR3';
		respCondition.Importe = '251.00';
		
		expectedPrice += Decimal.valueOf(respCondition.Importe);
		respPosition.Condiciones.add(respCondition);
		//=================================
		//IVA condition
		respCondition = new WSSAPContratosPedidos.Condicion_IN_element();
		respCondition.Condicion = 'J1AX';
		respCondition.Importe = '35.00';
		
		expectedIVA = Decimal.valueOf(respCondition.Importe);
		respPosition.Condiciones.add(respCondition);
		
		responsePositions.add(respPosition);
		
		ContractToSAPSimulation converter = new ContractToSAPSimulation(aContract.Id, positions);
		
		List<SimulationPosition> result = converter.applyReceivedPrices(responsePositions);
		
		System.assertEquals(positions.size(), result.size());
		System.assertEquals(expectedPrice, result[0].noIvaPrice);
		System.assertEquals(expectedIVA, result[0].priceIVA);
	}
	
	@isTest
	private static void ifTheIvaConditionWasNotReceived_TheIvaPriceShouldBeZero() {
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).build();
		insert aContract;
		
		List<SimulationPosition> positions = new List<SimulationPosition>();
		SimulationPosition position = new SimulationPosition();
		position.ivaTreatment = 'BE';
		position.provinceCode = '123';
		position.isInTransit = true;
		position.amount = 3;
		position.productNumber = 'Prod';
		position.productSector = 'Sect';
		
		positions.add(position);
		
		//=================================
		//Server response
		List<WSSAPContratosPedidos.Posiciones_element> responsePositions =
			new List<WSSAPContratosPedidos.Posiciones_element>();
		
		WSSAPContratosPedidos.Posiciones_element respPosition =
			new WSSAPContratosPedidos.Posiciones_element();
		respPosition.Material = position.productNumber;
		respPosition.Posicion = '000100';
		respPosition.Condiciones = new List<WSSAPContratosPedidos.Condicion_IN_element>();
		//=================================
		//Price condition
		WSSAPContratosPedidos.Condicion_IN_element respCondition =
			new WSSAPContratosPedidos.Condicion_IN_element();
		respCondition.Condicion = 'ZPR2';
		respCondition.Importe = '123.00';
		
		respPosition.Condiciones.add(respCondition);
		responsePositions.add(respPosition);
		
		ContractToSAPSimulation converter = new ContractToSAPSimulation(aContract.Id, positions);
		
		List<SimulationPosition> result = converter.applyReceivedPrices(responsePositions);
		
		System.assertEquals(0, result[0].priceIVA);
	}
	
	@isTest
	private static void aDiscountValueAsSentBySapShouldBeInterpretedAsANegative() {
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		Contrato__c aContract = Build.aContract().withUniqueNumber().forAccount(anAccount).build();
		insert aContract;
		
		List<SimulationPosition> positions = new List<SimulationPosition>();
		SimulationPosition position = new SimulationPosition();
		position.ivaTreatment = 'BE';
		position.provinceCode = '123';
		position.isInTransit = true;
		position.amount = 3;
		position.productNumber = 'Prod';
		position.productSector = 'Sect';
		
		positions.add(position);
		
		decimal expectedPrice = 0;
		//=================================
		//Server response
		List<WSSAPContratosPedidos.Posiciones_element> responsePositions =
			new List<WSSAPContratosPedidos.Posiciones_element>();
		
		WSSAPContratosPedidos.Posiciones_element respPosition =
			new WSSAPContratosPedidos.Posiciones_element();
		respPosition.Material = position.productNumber;
		respPosition.Posicion = '000100';
		respPosition.Condiciones = new List<WSSAPContratosPedidos.Condicion_IN_element>();
		//=================================
		//Price condition
		WSSAPContratosPedidos.Condicion_IN_element respCondition =
			new WSSAPContratosPedidos.Condicion_IN_element();
		respCondition.Condicion = 'ZPR2';
		respCondition.Importe = '123.00';
		
		expectedPrice += Decimal.valueOf(respCondition.Importe);
		respPosition.Condiciones.add(respCondition);
		//=================================
		//Discount condition
		decimal discountAmount = 25;
		respCondition = new WSSAPContratosPedidos.Condicion_IN_element();
		respCondition.Condicion = 'ZPR3';
		respCondition.Importe = ContractToSAPConverterBase.formatNumber(discountAmount, 2) + '-';
		
		expectedPrice -= discountAmount;
		respPosition.Condiciones.add(respCondition);
		
		responsePositions.add(respPosition);
		
		ContractToSAPSimulation converter = new ContractToSAPSimulation(aContract.Id, positions);
		
		List<SimulationPosition> result = converter.applyReceivedPrices(responsePositions);
		
		System.assertEquals(expectedPrice, result[0].noIvaPrice);
	}
}
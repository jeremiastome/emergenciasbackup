@isTest
private class SimulationPositionTest {
	@isTest
	private static void itShouldBePosibleToGetTheTotalValueOfAProductFromRecievedConditions() {
		decimal totalPrice = 0;
		List<WSSAPContratosPedidos.Condicion_IN_element> conditions =
			new List<WSSAPContratosPedidos.Condicion_IN_element>();
			
		//=================================
		//Conditions
		WSSAPContratosPedidos.Condicion_IN_element condition =
			new WSSAPContratosPedidos.Condicion_IN_element();
		condition.Condicion = 'zdfw';
		condition.Importe = '101.00 ';
		totalPrice += 101;
		conditions.add(condition);
		//================
		condition = new WSSAPContratosPedidos.Condicion_IN_element();
		condition.Condicion = 'zdfq';
		condition.Importe = '104.20 ';
		totalPrice += 104.2;
		conditions.add(condition);
		//================
		condition = new WSSAPContratosPedidos.Condicion_IN_element();
		condition.Condicion = 'zdfe';
		condition.Importe = '1004.20 ';
		totalPrice += 1004.2;
		conditions.add(condition);
		
		//=================================
		//Execution
		SimulationPosition simulatedPosition = new SimulationPosition();
		simulatedPosition.generatePriceFromConditions(conditions);
		
		//=================================
		//Asserts
		System.assertEquals(totalPrice, simulatedPosition.noIvaPrice);
	}
	
	@isTest
	private static void itShouldBePosibleToIdentifyTheDiscountsFromTheRecharges() {
		decimal totalPrice = 0;
		List<WSSAPContratosPedidos.Condicion_IN_element> conditions =
			new List<WSSAPContratosPedidos.Condicion_IN_element>();
		Set<String> discounts = new Set<String>();
		Set<String> surcharges = new Set<String>();
		//=================================
		//Conditions
		WSSAPContratosPedidos.Condicion_IN_element condition =
			new WSSAPContratosPedidos.Condicion_IN_element();
		condition.Condicion = 'zdfw';
		condition.Importe = '101.00 ';
		totalPrice += 101;
		conditions.add(condition);
		surcharges.add(condition.Condicion);
		//================
		condition = new WSSAPContratosPedidos.Condicion_IN_element();
		condition.Condicion = 'zdfq';
		condition.Importe = '104.20-';
		totalPrice += -104.2;
		conditions.add(condition);
		discounts.add(condition.Condicion);
		//================
		condition = new WSSAPContratosPedidos.Condicion_IN_element();
		condition.Condicion = 'zdfe';
		condition.Importe = '1004.20 ';
		totalPrice += 1004.2;
		conditions.add(condition);
		surcharges.add(condition.Condicion);
		
		//=================================
		//Execution
		SimulationPosition simulatedPosition = new SimulationPosition();
		simulatedPosition.generatePriceFromConditions(conditions);
		
		//=================================
		//Asserts
		System.assertEquals(totalPrice, simulatedPosition.noIvaPrice);
		System.assertEquals(surcharges.size(), simulatedPosition.surcharges.size());
		for(SimulationPosition.SimulationCondition surcharge : simulatedPosition.surcharges) {
			System.assertEquals(true, surcharges.contains(surcharge.code));
		}
		
		System.assertEquals(discounts.size(), simulatedPosition.discounts.size());
		for(SimulationPosition.SimulationCondition discount : simulatedPosition.discounts) {
			System.assertEquals(true, discounts.contains(discount.code));
		}
	}
	
	@isTest
	private static void itShouldBePosibleToGetTheBasePriceOfAProductFromRecievedConditions() {
		decimal totalPrice = 0;
		List<WSSAPContratosPedidos.Condicion_IN_element> conditions =
			new List<WSSAPContratosPedidos.Condicion_IN_element>();
			
		//=================================
		//Conditions
		WSSAPContratosPedidos.Condicion_IN_element condition =
			new WSSAPContratosPedidos.Condicion_IN_element();
		condition.Condicion = 'ZPR0';
		condition.Importe = '101.00 ';
		totalPrice += 101;
		conditions.add(condition);
		//================
		condition = new WSSAPContratosPedidos.Condicion_IN_element();
		condition.Condicion = 'ZPVS';
		condition.Importe = '104.20 ';
		totalPrice += 104.2;
		conditions.add(condition);
		//================
		condition = new WSSAPContratosPedidos.Condicion_IN_element();
		condition.Condicion = 'ZPR2';
		condition.Importe = '1004.20 ';
		totalPrice += 1004.2;
		conditions.add(condition);
		
		//=================================
		//Execution
		SimulationPosition simulatedPosition = new SimulationPosition();
		simulatedPosition.generatePriceFromConditions(conditions);
		
		//=================================
		//Asserts
		System.assertEquals(totalPrice, simulatedPosition.basePrice);
		System.assertEquals(totalPrice, simulatedPosition.noIvaPrice);
	}
	
	@isTest
	private static void itShouldBePosibleToGetTheBaseIVAForAProductFromRecievedConditions() {
		List<WSSAPContratosPedidos.Condicion_IN_element> conditions =
			new List<WSSAPContratosPedidos.Condicion_IN_element>();
			
		//=================================
		//Conditions
		WSSAPContratosPedidos.Condicion_IN_element condition =
			new WSSAPContratosPedidos.Condicion_IN_element();
		condition.Condicion = 'J1AX';
		condition.Importe = '101.00 ';
		decimal ivaPrice = 101;
		conditions.add(condition);
		
		//=================================
		//Execution
		SimulationPosition simulatedPosition = new SimulationPosition();
		simulatedPosition.generatePriceFromConditions(conditions);
		
		//=================================
		//Asserts
		System.assertEquals(ivaPrice, simulatedPosition.priceIVA);
		System.assertEquals(0, simulatedPosition.noIvaPrice);
	}
}
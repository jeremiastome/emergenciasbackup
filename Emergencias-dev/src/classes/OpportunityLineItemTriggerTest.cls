@isTest
private class OpportunityLineItemTriggerTest {
	private static testMethod void whenInsertingAnOpportunityLineItemACoberageObjectShouldMirrorIt() {
		OpportunityLineItem anOpportunityProduct = Build.anOpportunityLineItem()
			.forOpportunity(anOpportunity).forPricebookEntry(aPriceBookEntry)
			.withDescription('A description of the opp line item, it is written in blue.')
			.withQuantity(1).withDiscount(2).withServiceDate(System.today())
			.withUnitPrice(4).build();
		insert anOpportunityProduct;
		
		List<Cobertura__c> coverageObjects = [
			SELECT Id, Cantidad__c, Codigo_de_producto__c, Descripcion_de_partida__c,
				Fecha__c, Precio_de_la_lista__c, Precio_de_venta__c, //Descuento__c,
				Precio_total__c, Producto__c, Subtotal__c
			FROM Cobertura__c
			WHERE Id_Producto_de_Oportunidad__c = :anOpportunityProduct.Id
		];
		
		OpportunityLineItem theOpportunityProductInDB = [
			SELECT Quantity, ProductCode, Description, Discount, ServiceDate, ListPrice,
				UnitPrice, TotalPrice, Product2Id, Subtotal
			FROM OpportunityLineItem
			WHERE Id = :anOpportunityProduct.Id
		];
		
		System.assertEquals(1, coverageObjects.size());
		System.assertEquals(theOpportunityProductInDB.Quantity, coverageObjects[0].Cantidad__c);
		System.assertEquals(theOpportunityProductInDB.ProductCode, coverageObjects[0].Codigo_de_producto__c);
		System.assertEquals(theOpportunityProductInDB.Description, coverageObjects[0].Descripcion_de_partida__c);
		//System.assertEquals(theOpportunityProductInDB.Discount, coverageObjects[0].Descuento__c);
		System.assertEquals(theOpportunityProductInDB.ServiceDate, coverageObjects[0].Fecha__c);
		System.assertEquals(theOpportunityProductInDB.ListPrice, coverageObjects[0].Precio_de_la_lista__c);
		System.assertEquals(theOpportunityProductInDB.UnitPrice, coverageObjects[0].Precio_de_venta__c);
		System.assertEquals(theOpportunityProductInDB.TotalPrice, coverageObjects[0].Precio_total__c);
		System.assertEquals(theOpportunityProductInDB.Product2Id, coverageObjects[0].Producto__c);
		System.assertEquals(theOpportunityProductInDB.Subtotal, coverageObjects[0].Subtotal__c);
	}
	
	private static testMethod void whenUpdatingAnOpportunityLineItemACoberageObjectShouldMirrorIt() {
		OpportunityLineItem anOpportunityProduct = Build.anOpportunityLineItem()
			.forOpportunity(anOpportunity).forPricebookEntry(aPriceBookEntry)
			.withDescription('A description of the opp line item, it is written in blue.')
			.withQuantity(1).withDiscount(2).withServiceDate(System.today())
			.withUnitPrice(4).build();
		insert anOpportunityProduct;
		
		anOpportunityProduct.Description = 'Another description, and I do not really want to write it.';
		anOpportunityProduct.Quantity = 8;
		anOpportunityProduct.Discount = 9;
		anOpportunityProduct.UnitPrice = 10;
		anOpportunityProduct.ServiceDate = System.today().addDays(3);
		update anOpportunityProduct;
		
		List<Cobertura__c> coverageObjects = [
			SELECT Id, Cantidad__c, Codigo_de_producto__c, Descripcion_de_partida__c,
				Fecha__c, Precio_de_la_lista__c, Precio_de_venta__c,
				Precio_total__c, Producto__c, Subtotal__c
			FROM Cobertura__c
			WHERE Id_Producto_de_Oportunidad__c = :anOpportunityProduct.Id
		];
		
		OpportunityLineItem theOpportunityProductInDB = [
			SELECT Quantity, ProductCode, Description, Discount, ServiceDate, ListPrice,
				UnitPrice, TotalPrice, Product2Id, Subtotal
			FROM OpportunityLineItem
			WHERE Id = :anOpportunityProduct.Id
		];
		
		System.assertEquals(1, coverageObjects.size());
		System.assertEquals(theOpportunityProductInDB.Quantity, coverageObjects[0].Cantidad__c);
		System.assertEquals(theOpportunityProductInDB.ProductCode, coverageObjects[0].Codigo_de_producto__c);
		System.assertEquals(theOpportunityProductInDB.Description, coverageObjects[0].Descripcion_de_partida__c);
		//System.assertEquals(theOpportunityProductInDB.Discount, coverageObjects[0].Descuento__c);
		System.assertEquals(theOpportunityProductInDB.ServiceDate, coverageObjects[0].Fecha__c);
		System.assertEquals(theOpportunityProductInDB.ListPrice, coverageObjects[0].Precio_de_la_lista__c);
		System.assertEquals(theOpportunityProductInDB.UnitPrice, coverageObjects[0].Precio_de_venta__c);
		System.assertEquals(theOpportunityProductInDB.TotalPrice, coverageObjects[0].Precio_total__c);
		System.assertEquals(theOpportunityProductInDB.Product2Id, coverageObjects[0].Producto__c);
		System.assertEquals(theOpportunityProductInDB.Subtotal, coverageObjects[0].Subtotal__c);
	}
	
	private static testMethod void whenAnOpportunityLineItemIsDeletedItsCoberageObjectShouldBeDeleted() {
		OpportunityLineItem anOpportunityProduct = Build.anOpportunityLineItem()
			.forOpportunity(anOpportunity).forPricebookEntry(aPriceBookEntry)
			.withDescription('A description of the opp line item, it is written in blue.')
			.withQuantity(1).withDiscount(2).withServiceDate(System.today())
			.withUnitPrice(4).build();
		insert anOpportunityProduct;
		delete anOpportunityProduct;
		
		List<Cobertura__c> coverageObjects = [
			SELECT Id
			FROM Cobertura__c
			WHERE Id_Producto_de_Oportunidad__c = :anOpportunityProduct.Id
		];
		
		System.assertEquals(0, coverageObjects.size());
	}
	
	private static testMethod void whenAnOpportunityLineItemIsCreatedForAnOpportunityWithoutContractThereShouldntBeAnError() {
		Opportunity opportunityWithoutContract = Build.anOpportunity().withDischargeTypeNew().saleWithoutContract().build();
		insert opportunityWithoutContract;
		
		OpportunityLineItem anOpportunityProduct = Build.anOpportunityLineItem()
			.forOpportunity(opportunityWithoutContract).forPricebookEntry(aPriceBookEntry)
			.withDescription('A description of the opp line item, it is written in blue.')
			.withQuantity(1).withDiscount(2).withServiceDate(System.today())
			.withUnitPrice(4).build();
		
		boolean failed = false;
		String exceptionMessage = '';
		
		try {
			insert anOpportunityProduct;
		}
		catch(Exception ex) {
			failed = true;
			exceptionMessage = ex.getMessage();
		}
		
		System.assert(!failed, 'The insertion should not fail. ' + exceptionMessage);
	}
	
	//==========================================================================
	static Opportunity anOpportunity;
	static Product2 aProduct;
	static PricebookEntry aPriceBookEntry;
	
	static {
		anOpportunity = Build.anOpportunity().withDischargeTypeNew().build();
		insert anOpportunity;
		aProduct = Build.aProduct()
			.withDescription('The description of this test product, it has red slime.')
			.withProductCode('TSTP1').build();
		insert aProduct;
		aPriceBookEntry = Build.aPriceBookEntry().forProduct(aProduct).withUnitPrice(4).build();
		insert aPriceBookEntry;
	}
}
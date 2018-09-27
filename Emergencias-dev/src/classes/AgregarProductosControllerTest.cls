@isTest
private class AgregarProductosControllerTest {

	private static testMethod void itShouldBePosibleToApplyMoreThanOneDiscountOfTheSameTypeForDiferentDates() {
		
	}


	private static testMethod void itShouldBePosibleToGetTheAdditionalsForAProduct() {
		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		System.assertEquals('', controller.ProductToAdd);
		System.assertEquals(products[0].Id, controller.Products[0].MainProduct.Id);

		System.assertEquals(products[0].Id, controller.Products[0].Coverage.Producto__c);

		System.assertEquals(additionalsByProduct.get(products[0].Id).size(), controller.Products[0].AvailableAdditionals.size());

		System.assertEquals(additionalsByProduct.get(products[0].Id).size(), controller.Products[0].AdditionalsSelectOptions.size());
		for(SelectOption option : controller.Products[0].AdditionalsSelectOptions) {
			System.assertEquals(controller.Products[0].AvailableAdditionals.get(option.getValue()).Numero__c, option.getLabel());
		}
	}

	private static testMethod void itShouldBePosibleToSelectAdditionalsForAProduct() {
		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();
		controller.Products[0].Coverage.Adicionales__c = null;

		System.assertEquals(0, controller.Products[0].SelectedAdditionals.size());
		List<String> selectedAdditionals = new List<String>();
		selectedAdditionals.add(controller.Products[0].AdditionalsSelectOptions[0].getValue());
		selectedAdditionals.add(controller.Products[0].AdditionalsSelectOptions[1].getValue());
		selectedAdditionals.add(controller.Products[0].AdditionalsSelectOptions[2].getValue());
		String expectedAdditionalsValue = '';
		for(String value : selectedAdditionals) {
			expectedAdditionalsValue += value + ';';
		}
		expectedAdditionalsValue = expectedAdditionalsValue.left(expectedAdditionalsValue.length() - 1);

		controller.Products[0].SelectedAdditionals = selectedAdditionals;
		System.assertEquals(expectedAdditionalsValue, controller.Products[0].Coverage.Adicionales__c);

		controller.Products[0].Coverage.Adicionales__c = controller.Products[0].AdditionalsSelectOptions[0].getValue();

		System.assertEquals(1, controller.Products[0].SelectedAdditionals.size());
	}

	private static testMethod void itShouldntBePosibleToAddAProductTwice() {
		AgregarProductosController controller = new AgregarProductosController();
		integer amountOfAvailableProducts = controller.AvailableProductsNames.size();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		System.assertEquals(amountOfAvailableProducts - 1, controller.AvailableProductsNames.size());

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		System.assertEquals(1, controller.Products.size());
		System.assertEquals(products[0].Id, controller.Products[0].MainProduct.Id);
	}

	private static testMethod void itShouldBePosibleToRemoveAProduct() {
		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		integer amountOfAvailableProducts = controller.AvailableProductsNames.size();

		controller.ProductToRemove = controller.Products[0].Index;
		controller.removeProduct();

		System.assertEquals(0, controller.Products.size());
		System.assertEquals(amountOfAvailableProducts + 1, controller.AvailableProductsNames.size());
	}

	private static testMethod void itShouldBePosibleToGetTheServicesOfAProduct() {
		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		System.assertEquals('', controller.ProductToAdd);
		System.assertEquals(products[0].Id, controller.Products[0].MainProduct.Id);
		System.assertEquals(servicesByProduct.get(products[0].Id).size(), controller.Products[0].Services.size());
	}

	private static testMethod void itShouldBePosibleToSaveTheSelectedProducts() {
		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		PageReference result = controller.save();

		System.assertEquals('/' + anOpportunity.Id, result.getUrl());

		List<Cobertura__c> coverages = [
			SELECT Id, Producto__c, Cantidad_de_menores__c
			FROM Cobertura__c
			WHERE Contrato__c = :aContract.Id
		];

		System.assertEquals(1, coverages.size());
		System.assertEquals(products[0].Id, coverages[0].Producto__c);
	}


	/* Ya los descuentos no son cargador inicialmente.
	private static testMethod void initiallyPreviousCoveragesShouldBeLoaded() {
		Descuento_Recargo__c aDiscount = createADiscount(products[0]);
		integer minorAmount = 1;

		Cobertura__c coverage = Build.aCoverage().forContract(aContract)
			.forProduct(products[0]).withMinorAmount(minorAmount).build();
		insert coverage;

		AgregarProductosController controller = new AgregarProductosController();
		controller.regenerateOpportunityLineItems();

		System.assertEquals(1, controller.Products.size());
		System.assertEquals(products[0].Id, controller.Products[0].MainProduct.Id);
		System.assertEquals(products[0].Id, controller.Products[0].Coverage.Producto__c);
		System.assertEquals(servicesByProduct.get(products[0].Id).size(), controller.Products[0].Services.size());
		System.assertEquals(additionalsByProduct.get(products[0].Id).size(), controller.Products[0].AvailableAdditionals.size());
		System.assertEquals(1, controller.Products[0].Discounts.size());
		System.assertEquals(aDiscount.Id, controller.Products[0].Discounts[0].Discount.Id);
		System.assertEquals(false, controller.AvailableProductsNames.contains(products[0].Numero__c));
	}*/


	private static testMethod void anExistingCoverageShouldOnlyBeDeletedAfterSaving() {
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract).forProduct(products[0]).build();
		insert aCoverage;

		AgregarProductosController controller = new AgregarProductosController();
		controller.regenerateOpportunityLineItems();

		controller.ProductToRemove = controller.Products[0].Index;
		controller.removeProduct();

		List<Cobertura__c> coveragesInDB = [
			SELECT Id
			FROM Cobertura__c
			WHERE Id = :aCoverage.Id
		];
		System.assertEquals(1, coveragesInDB.size());

		controller.save();

		coveragesInDB = [
			SELECT Id
			FROM Cobertura__c
			WHERE Id = :aCoverage.Id
		];
		System.assertEquals(0, coveragesInDB.size());
	}

	private static testMethod void whenLoadingAProductWithoutServices_AdditionalsOrDiscountsItShouldntFail() {
		Product2 aProduct = additionalsByProduct.values()[0][0];

		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract).forProduct(aProduct).build();
		insert aCoverage;

		AgregarProductosController controller = new AgregarProductosController();
		boolean failed = false;

		try {
			controller.regenerateOpportunityLineItems();
		}
		catch(Exception e) {
			failed = true;
		}

		System.assertEquals(false, failed);
	}

	private static testMethod void itShouldBePosibleToObtainTheDiscountsForAProduct() {
		List<Schema.PicklistEntry> SalespersonGroupValues = User.Grupo_de_Vendedores__c.getDescribe().getPicklistValues();

		List<Descuento_Recargo__c> discounts = new List<Descuento_Recargo__c>();
		for(Integer i = 0; i < SalespersonGroupValues.size(); i++) {
			discounts.add(Build.aDiscount().build());
		}
		insert discounts;

		Descuento_Recargo__c expectedDiscount;
		List<Descuento_Recargo_de_Producto__c> discountProductRelations = new List<Descuento_Recargo_de_Producto__c>();
		for(Integer i = 0; i < SalespersonGroupValues.size(); i++) {
			Descuento_Recargo_de_Producto__c aRelation = Build.aDiscountProductRelation()
				.forProduct(products[0]).forDiscount(discounts[i])
				.withSalespersonGroup(SalespersonGroupValues[i].getValue()).build();
			discountProductRelations.add(aRelation);
			if(aSalesperson.Grupo_de_Vendedores__c == SalespersonGroupValues[i].getValue()) {
				expectedDiscount = discounts[i];
			}
		}
		insert discountProductRelations;

		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		System.assertEquals(1, controller.Products[0].AvailableDiscounts.size());
		System.assertEquals(expectedDiscount.Id, controller.Products[0].AvailableDiscounts.get(expectedDiscount.Id).id);
	}

	private static testMethod void theCustomDiscountShouldBeObtainableforEveryProduct() {
		Descuento_Recargo__c theCustomDiscount = Build.aDiscount().withDiscountCode('ZDV0').build();
		insert theCustomDiscount;

		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();
		controller.Products[0].selectedDiscountType = controller.Products[0].AvailableDiscountOptions[0].getValue();
		controller.Products[0].addDiscount();

		System.assertEquals(1, controller.Products[0].Discounts.size());
		System.assertEquals(theCustomDiscount.Id, controller.Products[0].Discounts[0].Discount.Id);

	}
		/*   Ya los descuentos no crean solos si no que deben agregarse.
	private static testMethod void theCustomDiscountShouldAlwaysBeTheLastDiscountListedInSelectedList() {

		List<Descuento_Recargo__c> discounts = new List<Descuento_Recargo__c>();
		for(Integer i = 0; i < 5; i++) {
			discounts.add(Build.aDiscount().build());
		}
		insert discounts;

		Descuento_Recargo__c theCustomDiscount = Build.aDiscount().withDiscountCode('ZDV0').build();
		insert theCustomDiscount;

		List<Descuento_Recargo__c> moreDiscounts = new List<Descuento_Recargo__c>();
		for(Integer i = 0; i < 5; i++) {
			moreDiscounts.add(Build.aDiscount().build());
		}
		insert moreDiscounts;
		discounts.addAll(moreDiscounts);
		
		List<Descuento_Recargo_de_Producto__c> discountProductRelations = new List<Descuento_Recargo_de_Producto__c>();
		for(Integer i = 0; i < discounts.size(); i++) {
			Descuento_Recargo_de_Producto__c aRelation = Build.aDiscountProductRelation().
				forDiscount(discounts[i]).forProduct(products[0])
				.withSalespersonGroup(aSalesperson.Grupo_de_Vendedores__c).build();
			discountProductRelations.add(aRelation);
		}
		insert discountProductRelations;

		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();
		
		System.assertEquals(discounts.size() + 1, controller.Products[0].AvailableDiscountOptions.size());
		System.assertEquals(
			theCustomDiscount.Id,
			controller.Products[0].AvailableDiscountOptions[controller.Products[0].AvailableDiscountOptions.size() - 1].getValue()
		);
	}

	private static testMethod void aDiscountShouldOnlyLoadForContractsOfTheAppropiateAccountType() {
		Descuento_Recargo__c aPersonDiscount = Build.aDiscount().build();
		Descuento_Recargo__c anEnterpriseDiscount = Build.aDiscount().build();
		insert new List<Descuento_Recargo__c> {aPersonDiscount, anEnterpriseDiscount};

		Descuento_Recargo_de_Producto__c aPersonDiscountProductRelation =
		 	Build.aDiscountProductRelation().forProduct(products[0]).forDiscount(aPersonDiscount)
			.forPersonAccounts().withSalespersonGroup(aSalesperson.Grupo_de_Vendedores__c).build();
		Descuento_Recargo_de_Producto__c anEnterpriseDiscountProductRelation =
		 	Build.aDiscountProductRelation().forProduct(products[0]).forDiscount(anEnterpriseDiscount)
			.forEnterpriseAccounts().withSalespersonGroup(aSalesperson.Grupo_de_Vendedores__c).build();
		insert new List<Descuento_Recargo_de_Producto__c> {aPersonDiscountProductRelation, anEnterpriseDiscountProductRelation};

		//===================================================
		AgregarProductosController controller = new AgregarProductosController();
		controller.regenerateOpportunityLineItems();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		System.assertEquals(1, controller.Products[0].Discounts.size());
		System.assertEquals(anEnterpriseDiscount.Id, controller.Products[0].Discounts[0].Discount.Id);

		//===================================================
		Account aPersonAccount = Build.anAccount().isPersonAccount().withCUILCUIT('20987654324').build();
		insert aPersonAccount;
		Contrato__c aPersonContract = Build.aContract().forAccount(aPersonAccount)
			.withSalesperson(aSalesperson).build();
		insert aPersonContract;
		ApexPages.currentPage().getParameters().put('Id', aPersonContract.Id);

		controller = new AgregarProductosController();
		controller.regenerateOpportunityLineItems();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		System.assertEquals(1, controller.Products[0].Discounts.size());
		System.assertEquals(aPersonDiscount.Id, controller.Products[0].Discounts[0].Discount.Id);
	}*/

	private static testMethod void itShouldBePosibleToSaveDiscountsForAProduct() {
		//Using the custom discount code so that i don't need to create the discount-product relation </lazy>
		Descuento_Recargo__c aDiscount = Build.aDiscount().withDiscountCode('ZDV0').build();
		insert aDiscount;

		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		controller.Products[0].selectedDiscountType = controller.Products[0].AvailableDiscountOptions[0].getValue();
		controller.Products[0].addDiscount();

		controller.Products[0].Discounts[0].IsActive = true;
		controller.Products[0].Discounts[0].Relation.Fecha_inicio__c = System.today();
		controller.Products[0].Discounts[0].Relation.fecha_fin__c = System.today().addDays(1);
		controller.Products[0].Discounts[0].Relation.Valor__c = 5;

		controller.save();

		List<Descuento_Recargo_Aplicado__c> appliedDiscounts = [
			SELECT Id, Descuento_o_Recargo__c
			FROM Descuento_Recargo_Aplicado__c
			WHERE Producto_de_Contrato__c = :controller.Products[0].Coverage.Id
		];

		System.assertEquals(1, appliedDiscounts.size());
		System.assertEquals(
			controller.Products[0].Discounts[0].Discount.Id,
			appliedDiscounts[0].Descuento_o_Recargo__c
		);
	}

	private static testMethod void ifTheCustomDiscountDoesNotHaveTheValueSet_AnErrorShouldBeShown() {
		Descuento_Recargo__c aDiscount = Build.aDiscount().withDiscountCode('ZDV0').build();
		insert aDiscount;

		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();
		
		
		controller.Products[0].selectedDiscountType = controller.Products[0].AvailableDiscountOptions[0].getValue();
		controller.Products[0].addDiscount();

		controller.Products[0].Discounts[0].IsActive = true;
		controller.Products[0].Discounts[0].Relation.Fecha_inicio__c = System.today();
		controller.Products[0].Discounts[0].Relation.Fecha_fin__c = System.today().addDays(123456);

		controller.save();

		List<Descuento_Recargo_Aplicado__c> appliedDiscounts = [
			SELECT Id, Descuento_o_Recargo__c
			FROM Descuento_Recargo_Aplicado__c
			WHERE Producto_de_Contrato__c = :controller.Products[0].Coverage.Id
		];

		System.assertEquals(0, appliedDiscounts.size());
		System.assertEquals(1, ApexPages.getMessages().size());
	}

	
	private static testMethod void ifTheCustomDiscountDoesNotHaveTheEndDateSet_AnErrorShouldBeShown() {
		Descuento_Recargo__c aDiscount = Build.aDiscount().withDiscountCode('ZDV0').build();
		insert aDiscount;

		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();
		
		
		controller.Products[0].selectedDiscountType = controller.Products[0].AvailableDiscountOptions[0].getValue();
		controller.Products[0].addDiscount();

		controller.Products[0].Discounts[0].IsActive = true;
		controller.Products[0].Discounts[0].Relation.Valor__c = 10;
		controller.Products[0].Discounts[0].Relation.Fecha_inicio__c = System.today();

		controller.save();

		List<Descuento_Recargo_Aplicado__c> appliedDiscounts = [
			SELECT Id, Descuento_o_Recargo__c
			FROM Descuento_Recargo_Aplicado__c
			WHERE Producto_de_Contrato__c = :controller.Products[0].Coverage.Id
		];

		System.assertEquals(0, appliedDiscounts.size());
		System.assertEquals(1, ApexPages.getMessages().size());
	}

	private static testMethod void ifADiscountWouldBeSavedWithoutAStartDate_AnErrorShouldBeShown() {
		Descuento_Recargo__c aDiscount = Build.aDiscount().build();
		insert aDiscount;

		Descuento_Recargo_de_Producto__c discountProductRelation = Build.aDiscountProductRelation()
				.forProduct(products[0]).forDiscount(aDiscount)
				.withSalespersonGroup(aSalesperson.Grupo_de_Vendedores__c).build();
		insert discountProductRelation;

		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();
		controller.Products[0].selectedDiscountType = controller.Products[0].AvailableDiscountOptions[0].getValue();
		controller.Products[0].addDiscount();

		controller.Products[0].Discounts[0].IsActive = true;
		controller.Products[0].Discounts[0].Relation.Valor__c = 10;
		controller.Products[0].Discounts[0].Relation.Fecha_fin__c = System.today().addDays(123456);

		controller.save();

		List<Descuento_Recargo_Aplicado__c> appliedDiscounts = [
			SELECT Id, Descuento_o_Recargo__c
			FROM Descuento_Recargo_Aplicado__c
			WHERE Producto_de_Contrato__c = :controller.Products[0].Coverage.Id
		];

		System.assertEquals(0, appliedDiscounts.size());
		System.assertEquals(1, ApexPages.getMessages().size());
	}
	private static testMethod void ifTheCustomDiscountDoesHaveTheValueMoreThan100Set_AnErrorShouldBeShown() {
		//Using the custom discount code so that i don't need to create the discount-product relation </lazy>
		Descuento_Recargo__c aDiscount = Build.aDiscount().withDiscountCode('ZDV0').build();
		insert aDiscount;

		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		controller.Products[0].selectedDiscountType = controller.Products[0].AvailableDiscountOptions[0].getValue();
		controller.Products[0].addDiscount();

		controller.Products[0].Discounts[0].IsActive = true;
		controller.Products[0].Discounts[0].Relation.Fecha_inicio__c = System.today();
		controller.Products[0].Discounts[0].Relation.fecha_fin__c = System.today().addDays(1);
		controller.Products[0].Discounts[0].Relation.Valor__c = 101;


		controller.save();

		List<Descuento_Recargo_Aplicado__c> appliedDiscounts = [
			SELECT Id, Descuento_o_Recargo__c
			FROM Descuento_Recargo_Aplicado__c
			WHERE Producto_de_Contrato__c = :controller.Products[0].Coverage.Id
		];

		System.assertEquals(0, appliedDiscounts.size());
		System.assertEquals(1, ApexPages.getMessages().size());
	}

	private static testMethod void itShouldBePosibleToLoadTheAppliedDiscountsForASavedCoverage() {
		//Using the custom discount code so that i don't need to create the discount-product relation </lazy>
		Descuento_Recargo__c aDiscount = Build.aDiscount().withDiscountCode('ZDV0').build();
		insert aDiscount;

		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract)
			.forProduct(products[0]).withAmount(20).build();
		insert aCoverage;

		Descuento_Recargo_Aplicado__c anAppliedDiscount = Build.anAppliedDiscount().forCoverage(aCoverage)
			.forDiscount(aDiscount).build();
		insert anAppliedDiscount;

		AgregarProductosController controller = new AgregarProductosController();
		controller.regenerateOpportunityLineItems();

		System.assertEquals(true, controller.Products[0].Discounts[0].IsActive);
	}

	private static testMethod void aSavedAppliedDiscountShouldBeDeletedWhenSaving() {
		//Using the custom discount code so that i don't need to create the discount-product relation </lazy>
		Descuento_Recargo__c aDiscount = Build.aDiscount().withDiscountCode('ZDV0').build();
		insert aDiscount;

		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract)
			.forProduct(products[0]).withAmount(12).build();
		insert aCoverage;

		Descuento_Recargo_Aplicado__c anAppliedDiscount = Build.anAppliedDiscount().forCoverage(aCoverage)
			.forDiscount(aDiscount).build();
		insert anAppliedDiscount;

		AgregarProductosController controller = new AgregarProductosController();
		controller.regenerateOpportunityLineItems();
		controller.Products[0].discountToRemove = 0;
		controller.Products[0].removeDiscount();

		controller.save();

		List<Descuento_Recargo_Aplicado__c> theAppliedDiscountInDB = [
			SELECT Id
			FROM Descuento_Recargo_Aplicado__c
			WHERE Id = :anAppliedDiscount.Id
		];

		System.assertEquals(0, theAppliedDiscountInDB.size());
	}

	private static testMethod void initiallyAListWithThePosibleSelectableProductsNamesShouldBeObtainable() {
		AgregarProductosController controller = new AgregarProductosController();
		System.assertEquals(products.size() - 1, controller.AvailableProductsNames.size());
	}

	private static testMethod void theListThePosibleSelectableProductsNamesWillNotContainTheNameAREA_PROTEGIDA_TRA() {
		AgregarProductosController controller = new AgregarProductosController();
		Set<String> productsNames = new Set<String>();
		productsNames.addAll(controller.AvailableProductsNames);
		
		System.assertEquals(products.size() - 1, productsNames.size());
		System.assert(productsNames.contains('PRD0'));
		System.assert(!productsNames.contains('AREA PROTEGIDA TRA'));
	}

	private static testMethod void ifTheUserTriesToAddAProductThatIsntAvailableItShouldntFail() {
		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = 'Potatoes';

		try {
			controller.getProductToAddDetails();
		}
		catch(Exception e) {
			System.assert(false, e.getMessage());
		}

		System.assertEquals('Potatoes', controller.ProductToAdd);
	}

	private static testMethod void ifTheIdPassedAsAParameterIsAContract_WhenSavingItShouldReturnToTheContract() {
		ApexPages.currentPage().getParameters().put('Id', aContract.Id);
		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		PageReference result = controller.save();

		System.assertEquals(aContract.Id, controller.ReturnRecord);
		System.assertEquals('/' + aContract.Id, result.getUrl());
	}

	private static testMethod void initiallyItShouldBePosibleToKnowIfItsPosibleToEditOnlyTheDiscounts() {
		AgregarProductosController controller = new AgregarProductosController();

		System.assertEquals(false, controller.AllowOnlyDiscounts);

		ApexPages.currentPage().getParameters().put('onlyDisc', 'T');
		controller = new AgregarProductosController();

		System.assertEquals(true, controller.AllowOnlyDiscounts);
	}

	private static testMethod void itShouldBePosibleToSpecifyAReturnRecordAsParameter() {
		AgregarProductosController controller = new AgregarProductosController();

		System.assertEquals(anOpportunity.Id, controller.ReturnRecord);

		ApexPages.currentPage().getParameters().put('retId', anAccount.Id);
		controller = new AgregarProductosController();

		PageReference result = controller.save();

		System.assertEquals(anAccount.Id, controller.ReturnRecord);
		System.assertEquals('/' + anAccount.Id, result.getUrl());
	}

	private static testMethod void itShouldBePosibleToGetMoreThanOneAppliedDiscountOfTheSameType() {
		Descuento_Recargo__c aDiscount = Build.aDiscount().withDiscountCode('ZDV0').build();
		insert aDiscount;

		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract)
			.forProduct(products[0]).withAmount(20).build();
		insert aCoverage;

		Descuento_Recargo_Aplicado__c anAppliedDiscount = Build.anAppliedDiscount().forCoverage(aCoverage)
			.forDiscount(aDiscount).build();
		insert anAppliedDiscount;
		
		Descuento_Recargo_Aplicado__c anAppliedDiscount2 = Build.anAppliedDiscount().forCoverage(aCoverage)
			.forDiscount(aDiscount).build();
		insert anAppliedDiscount2;

		AgregarProductosController controller = new AgregarProductosController();
		controller.regenerateOpportunityLineItems();

		System.assertEquals(2, controller.Products[0].Discounts.size());
		System.assertEquals(true, controller.Products[0].Discounts[0].IsActive);
	}

	//==========================================================================
	//Post sale discounts
	private static testMethod void aPostSaleDiscountShouldNotAppearWhenTheReturnRecordIsAnOpportunity() {
		Descuento_Recargo__c postSaleDiscount = createADiscount(products[0]);
		postSaleDiscount.Descuento_de_pos_venta__c = true;
		update postSaleDiscount;

		ApexPages.currentPage().getParameters().put('retId', anOpportunity.Id);
		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		System.assertEquals(0, controller.Products[0].AvailableDiscounts.size());
	}

	private static testMethod void onlyPostSaleDiscountShouldAppearWhenTheReturnRecordIsNotAnOpportunity() {
		Descuento_Recargo__c postSaleDiscount = createADiscount(products[0]);
		postSaleDiscount.Descuento_de_pos_venta__c = true;
		update postSaleDiscount;
		Descuento_Recargo__c aDiscount = createADiscount(products[0]);

		ApexPages.currentPage().getParameters().put('Id', aContract.Id);
		ApexPages.currentPage().getParameters().put('retId', aContract.Id);
		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();
		
		System.assertEquals(1, controller.Products[0].AvailableDiscountOptions.size());
		System.assertEquals(postSaleDiscount.Id, controller.Products[0].AvailableDiscountOptions[0].getValue());
	}

	private static testMethod void theCustomPostSaleDiscountShouldBeObtainableforEveryProductWhenTheReturnRecordIsNotAnOpportunity() {
		Descuento_Recargo__c theCustomDiscount = Build.aDiscount().withDiscountCode('ZDV0').build();
		Descuento_Recargo__c theCustomPostSaleDiscount = Build.aDiscount().withDiscountCode('ZDR0').isPostSaleDiscount().build();
		insert theCustomDiscount;
		insert theCustomPostSaleDiscount;

		ApexPages.currentPage().getParameters().put('Id', aContract.Id);
		ApexPages.currentPage().getParameters().put('retId', aContract.Id);
		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();
		
		System.assertEquals(1, controller.Products[0].AvailableDiscountOptions.size());
		System.assertEquals(theCustomPostSaleDiscount.Id, controller.Products[0].AvailableDiscountOptions[0].getValue());

	}

	//==========================================================================
	//Addition case
	private static testMethod void ifTheReturnRecordIsAnAdditionCase_OnlyDiscountsShouldBeChanged() {
		ApexPages.currentPage().getParameters().put('retId', aCase.Id);

		Descuento_Recargo__c aDiscount = createADiscount(products[0]);
		aDiscount.Descuento_de_pos_venta__c = true;
		update aDiscount;

		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract)
			.forProduct(products[0]).build();
		insert aCoverage;

		AgregarProductosController controller = new AgregarProductosController();
		controller.regenerateOpportunityLineItems();

		System.assertEquals(true, controller.AllowOnlyDiscounts);
	}

	private static testMethod void ifTheReturnRecordIsAnAdditionCase_ItShouldNotBePosibleToChangeOldAppliedDiscounts() {
		ApexPages.currentPage().getParameters().put('retId', aCase.Id);

		Descuento_Recargo__c aDiscount = createADiscount(products[0]);
		aDiscount.Descuento_de_pos_venta__c = true;
		update aDiscount;

		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract)
			.forProduct(products[0]).build();
		insert aCoverage;
		Descuento_Recargo_Aplicado__c anAppliedDiscount = Build.anAppliedDiscount().forCoverage(aCoverage)
			.forDiscount(aDiscount).build();
		insert anAppliedDiscount;

		AgregarProductosController controller = new AgregarProductosController();
		controller.regenerateOpportunityLineItems();

		System.assertEquals(1, controller.Products.size());
		System.assertEquals(false, controller.Products[0].Discounts[0].CanBeChanged);
	}

	private static testMethod void ifTheReturnRecordIsAnAdditionCase_ItShouldBePosibleToChangeOldAppliedDiscountsForTheCase() {
		ApexPages.currentPage().getParameters().put('retId', aCase.Id);

		Descuento_Recargo__c aDiscount = createADiscount(products[0]);
		aDiscount.Descuento_de_pos_venta__c = true;
		update aDiscount;

		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract)
			.forProduct(products[0]).build();
		insert aCoverage;
		Descuento_Recargo_Aplicado__c anAppliedDiscount = Build.anAppliedDiscount().forCoverage(aCoverage)
			.forDiscount(aDiscount).forCase(aCase).build();
		insert anAppliedDiscount;

		AgregarProductosController controller = new AgregarProductosController();
		controller.regenerateOpportunityLineItems();


		System.assertEquals(1, controller.Products.size());
		System.assertEquals(true, controller.Products[0].Discounts[0].CanBeChanged);
	}

	private static testMethod void ifTheReturnRecordIsAnAdditionCase_CreatedDiscountsShouldBeCreatedForTheCase() {
		ApexPages.currentPage().getParameters().put('retId', aCase.Id);
		Descuento_Recargo__c aDiscount = createADiscount(products[0]);
		aDiscount.Descuento_de_pos_venta__c = true;
		update aDiscount;

		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract)
			.forProduct(products[0]).build();
		insert aCoverage;

		AgregarProductosController controller = new AgregarProductosController();
		controller.regenerateOpportunityLineItems();

		controller.Products[0].selectedDiscountType = controller.Products[0].AvailableDiscountOptions[0].getValue();
		controller.Products[0].addDiscount();

		System.assertEquals(true, controller.Products[0].Discounts[0].CanBeChanged);

		controller.Products[0].Discounts[0].IsActive = true;
		controller.Products[0].Discounts[0].Relation.Fecha_inicio__c = System.today();
		controller.Products[0].Discounts[0].Relation.fecha_fin__c = System.today().addDays(1);

		controller.save();

		System.debug(Controller.Products[0].Coverage.Id);

		List<Descuento_Recargo_Aplicado__c> appliedDiscounts = [
			SELECT Id, Caso__c
			FROM Descuento_Recargo_Aplicado__c
			WHERE Producto_de_Contrato__c = :controller.Products[0].Coverage.Id
		];

		System.debug('Cantidad lista ' + appliedDiscounts.size());

		System.assertEquals(aCase.Id, appliedDiscounts[0].Caso__c);
	}

	//==========================================================================
	//SAP Price simulation
	private static testMethod void initiallyTheIvaTreatmentsForSimulationPositionsShouldBeObtained() {
		AgregarProductosController controller = new AgregarProductosController();

		Map<String, String> ivaTreatments = new Map<String, String>();
		for(Schema.PicklistEntry ivaTreatment :
			Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()
		) {
			ivaTreatments.put(ivaTreatment.getValue(), ivaTreatment.getLabel());
		}

		System.assertEquals(ivaTreatments.size(), controller.ivaTreatments.size());
		System.assertEquals(ivaTreatments.size(), controller.ivaTreatmentMap.size());

		for(SelectOption ivaOption : controller.ivaTreatments) {
			System.assertEquals(ivaTreatments.get(ivaOption.getValue()), ivaOption.getLabel());
			System.assertEquals(controller.ivaTreatmentMap.get(ivaOption.getValue()), ivaOption.getLabel());
		}
	}

	private static testMethod void initiallyTheProvincesForSimulationPositionsShouldBeObtained() {
		Interlocutor_Provincia__c aProvinceSetting = new Interlocutor_Provincia__c(
			Name = 'province name',
			Codigo_SAP__c = '9767ikfoe'
		);
		insert aProvinceSetting;

		AgregarProductosController controller = new AgregarProductosController();
		System.assertEquals(1, controller.provinceOptions.size());
		System.assertEquals(1, controller.provinceMap.size());

		System.assertEquals(aProvinceSetting.Name, controller.provinceOptions[0].getLabel());
		System.assertEquals(aProvinceSetting.Codigo_SAP__c, controller.provinceOptions[0].getValue());
		System.assertEquals(aProvinceSetting.Name, controller.provinceMap.get(aProvinceSetting.Codigo_SAP__c));
	}

	private static testMethod void itShouldBePosibleToAddAPositionForSimulation() {
		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		System.assertEquals(0, controller.Products[0].Positions.size());

		String ivaTreatment = 'BE';
		String provinceCode = '56789o0';
		Boolean isInTransit = true;

		controller.Products[0].nextPosition.ivaTreatment = ivaTreatment;
		controller.Products[0].nextPosition.provinceCode = provinceCode;
		controller.Products[0].nextPosition.isInTransit = isInTransit;
		controller.Products[0].addPosition();

		System.assertEquals(1, controller.Products[0].Positions.size());
		System.assertEquals(ivaTreatment, controller.Products[0].Positions[0].ivaTreatment);
		System.assertEquals(provinceCode, controller.Products[0].Positions[0].provinceCode);
		System.assertEquals(isInTransit, controller.Products[0].Positions[0].isInTransit);
		System.assertEquals(0, controller.Products[0].Positions[0].index);
		System.assertEquals(null, controller.Products[0].Positions[0].productNumber);
		System.assertEquals(null, controller.Products[0].Positions[0].productSector);
	}

	private static testMethod void itShouldBePosibleToRemoveAPositionForSimulation() {
		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		String ivaTreatment = 'BE';
		String provinceCode = '56789o0';
		Boolean isInTransit = true;

		controller.Products[0].addPosition();

		controller.Products[0].setPositionToRemove(controller.Products[0].Positions[0].index);
		controller.Products[0].removePosition();

		System.assertEquals(0, controller.Products[0].Positions.size());
	}

	private static testMethod void itShouldBePosibleToSimulateAPriceInSAP() {
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);

		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		//=======================================================
		// Server response
		decimal expectedPrice = 123;

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
		//=======================================================
		// Controller setup
		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		controller.Products[0].nextPosition.ivaTreatment = 'BE';
		controller.Products[0].nextPosition.provinceCode = '56789o0';
		controller.Products[0].nextPosition.isInTransit = true;
		controller.Products[0].addPosition();

		integer positionAmount = 3;
		controller.Products[0].Positions[0].amount = positionAmount;

		//=======================================================
		// Execution
		Test.startTest();
		controller.simulatePrice();
		Test.stopTest();

		//=======================================================
		// Assertions
		System.assertEquals(1, serverMock.receivedRequests);

		System.assertEquals(1, controller.simulation.positions.size());
		System.assertEquals(products[0].Numero__c, controller.simulation.positions[0].productNumber);
		System.assertEquals(positionAmount, controller.simulation.positions[0].amount);
		System.assertEquals(expectedPrice, controller.simulation.positions[0].noIvaPrice);
	}

	private static testMethod void afterThePriceSimulationIsDone_TheTotalPriceShouldBeObtainable() {
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);

		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		//=======================================================
		// Server response
		decimal expectedTotal = 0;
		decimal price = 150;
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In response =
			new WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In();
		response.Msg = new List<WSSAPContratosPedidos.Msg_element>();
		WSSAPContratosPedidos.Msg_element message = new WSSAPContratosPedidos.Msg_element();
		message.Tipo = 'S';
		response.Msg.add(message);
		response.Documento = new WSSAPContratosPedidos.Documento_element();
		response.Documento.Posiciones = new List<WSSAPContratosPedidos.Posiciones_element>();
		//==============================
		// Position 100
		WSSAPContratosPedidos.Posiciones_element respPostion =
			new WSSAPContratosPedidos.Posiciones_element();
		respPostion.Material = '';
		respPostion.Posicion = '000100';
		respPostion.Condiciones = new List<WSSAPContratosPedidos.Condicion_IN_element>();
		WSSAPContratosPedidos.Condicion_IN_element respCondition =
			new WSSAPContratosPedidos.Condicion_IN_element();
		respCondition.Condicion = 'ZPR2';
		respCondition.Importe = ContractToSAPConverterBase.formatNumber(price, 2);
		expectedTotal += price;
		respPostion.Condiciones.add(respCondition);
		response.Documento.Posiciones.add(respPostion);
		//==============================
		// Position 200
		respPostion = new WSSAPContratosPedidos.Posiciones_element();
		respPostion.Material = '';
		respPostion.Posicion = '000200';
		respPostion.Condiciones = new List<WSSAPContratosPedidos.Condicion_IN_element>();
		respCondition = new WSSAPContratosPedidos.Condicion_IN_element();
		respCondition.Condicion = 'ZPR2';
		respCondition.Importe = ContractToSAPConverterBase.formatNumber(price, 2);
		expectedTotal += price;
		respPostion.Condiciones.add(respCondition);
		response.Documento.Posiciones.add(respPostion);

		serverMock.responseObjs.add(response);
		//=======================================================
		// Controller setup
		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		controller.Products[0].nextPosition.ivaTreatment = 'BE';
		controller.Products[0].nextPosition.provinceCode = '56789o0';
		controller.Products[0].nextPosition.isInTransit = true;
		controller.Products[0].addPosition();

		controller.Products[0].nextPosition.ivaTreatment = 'BE';
		controller.Products[0].nextPosition.provinceCode = '56789o1';
		controller.Products[0].nextPosition.isInTransit = true;
		controller.Products[0].addPosition();

		controller.Products[0].Positions[0].amount = 3;
		controller.Products[0].Positions[1].amount = 3;

		//=======================================================
		// Execution
		Test.startTest();
		controller.simulatePrice();
		Test.stopTest();

		//=======================================================
		// Assertions
		System.assertEquals(expectedTotal, controller.simulation.totalPrice);
	}

	private static testMethod void ifTheSimulationReturnsAnError_ItShouldBePosibleToShowItToTheUser() {
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		serverMock.simulateNetworkError = true;

		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		//=======================================================
		// Server response
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In response =
			new WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In();
		response.Msg = new List<WSSAPContratosPedidos.Msg_element>();
		WSSAPContratosPedidos.Msg_element message = new WSSAPContratosPedidos.Msg_element();
		message.Tipo = 'E';
		response.Msg.add(message);
		serverMock.responseObjs.add(response);
		//=======================================================
		// Controller setup
		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		controller.Products[0].nextPosition.ivaTreatment = 'BE';
		controller.Products[0].nextPosition.provinceCode = '56789o0';
		controller.Products[0].nextPosition.isInTransit = true;
		controller.Products[0].addPosition();

		integer positionAmount = 3;
		controller.Products[0].Positions[0].amount = positionAmount;

		//=======================================================
		// Execution
		Test.startTest();
		controller.simulatePrice();
		Test.stopTest();

		//=======================================================
		// Assertions
		System.assertEquals(true, controller.simulation.failed);
		System.assertNotEquals(null, controller.simulation.errorMessage);
		System.assertEquals(null, controller.simulation.positions);
	}

	private static testMethod void ifADiscountIsNotValidWhenSendingForSimulation_AnErrorShouldBeShown() {
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		serverMock.simulateNetworkError = true;

		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;

		//Using the custom discount code so that i don't need to create the discount-product relation </lazy>
		Descuento_Recargo__c aDiscount = Build.aDiscount().withDiscountCode('ZDV0').build();
		insert aDiscount;

		AgregarProductosController controller = new AgregarProductosController();

		controller.ProductToAdd = products[0].Numero__c;
		controller.getProductToAddDetails();

		//Discount the product
		controller.Products[0].selectedDiscountType = controller.Products[0].AvailableDiscountOptions[0].getValue();
		controller.Products[0].addDiscount();

		controller.Products[0].Discounts[0].IsActive = true;
		controller.Products[0].Discounts[0].Relation.Fecha_inicio__c = System.today();
		controller.Products[0].Discounts[0].Relation.Fecha_inicio__c = System.today().addDays(123456);

		//Create position
		controller.Products[0].nextPosition.ivaTreatment = 'BE';
		controller.Products[0].nextPosition.provinceCode = '56789o0';
		controller.Products[0].nextPosition.isInTransit = true;
		controller.Products[0].addPosition();

		controller.Products[0].Positions[0].amount = 3;

		Test.startTest();
		controller.simulatePrice();
		Test.stopTest();

		System.assertEquals(1, ApexPages.getMessages().size());
		System.assertEquals(null, controller.simulation);
		System.assertEquals(0, serverMock.receivedRequests);
	}

	//==========================================================================
	private static Descuento_Recargo__c createADiscount(Product2 theProduct) {
		if(String.isBlank(aSalesperson.Grupo_de_Vendedores__c)) {
			List<Schema.PicklistEntry> SalespersonGroupValues = User.Grupo_de_Vendedores__c.getDescribe().getPicklistValues();
			aSalesperson.Grupo_de_Vendedores__c = SalespersonGroupValues[0].getValue();
			update aSalesperson;
		}
		Descuento_Recargo__c aDiscount = Build.aDiscount().build();
		insert aDiscount;
		Descuento_Recargo_de_Producto__c aDiscountProductRelation =
		 	Build.aDiscountProductRelation().forProduct(theProduct).forDiscount(aDiscount)
			.withSalespersonGroup(aSalesperson.Grupo_de_Vendedores__c).build();
		insert aDiscountProductRelation;

		return aDiscount;
	}

	//==========================================================================
	static Account anAccount;
	static Opportunity anOpportunity;
	static Contrato__c aContract;
	static List<Product2> products;
	static Map<Id, List<Product2>> additionalsByProduct;
	static Map<Id, PricebookEntry> priceBookEntryByProduct;
	static Map<Id, List<Servicio__c>> servicesByProduct;
	static User aSalesperson;
	static Case aCase;

	static {
		List<Schema.PicklistEntry> SalesOrganizationValues = User.Organizacion_de_Venta__c.getDescribe().getPicklistValues();
		List<Schema.PicklistEntry> SalespersonGroupValues = User.Grupo_de_Vendedores__c.getDescribe().getPicklistValues();

		aSalesperson = Build.anUser().withSalesOrganization(SalesOrganizationValues[0].getValue())
			.withSalespersonGroup(SalespersonGroupValues[0].getValue()).build();
		insert aSalesperson;

		anAccount = Build.anAccount().isPersonAccount().build();
		insert anAccount;
		anOpportunity = Build.anOpportunity().forAccount(anAccount).withSalesperson(aSalesperson).withDischargeTypeNew().build();
		insert anOpportunity;

		aContract = [
			SELECT Id, Vendedor__c
			FROM Contrato__c
			WHERE Id IN (SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		];
		if(aContract.Vendedor__c == null) {
			aContract.Vendedor__c = aSalesperson.Id;
			update aContract;
		}
		createProducts();
		createServices();
		Test.setCurrentPage(new PageReference('Page.AsignacionDeBeneficios'));
		ApexPages.currentPage().getParameters().put('Id', anOpportunity.Id);

		//============================================
		RecordType caseRecordType = [
			SELECT Id, DeveloperName
			FROM RecordType
			WHERE SObjectType = 'Case'
				AND DeveloperName = 'Cambio_de_Cobertura'
			LIMIT 1
		];
		Casos_Beneficiarios_Descuentos__c additionSettings = Build.someAdditionCaseSettings()
			.forCaseRecordType(caseRecordType).withCloseReasonCorrect('Procesado')
			.withCloseReasonIncorrect('Rechazado').build();
		insert additionSettings;
		aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
		insert aCase;
	}

	private static void createProducts() {
		products = new List<Product2>();
		for(Integer i = 0; i < 5; i++) {
			products.add(Build.aProduct().withName('Prod ' + i).withNumber('PRD' + i).withDistributionChannel('10').build());
		}
		insert products;

		additionalsByProduct = new Map<Id, List<Product2>>();
		List<Product2> allAdditionals = new List<Product2>();
		for(Product2 mainProduct : products) {
			List<Product2> additionals = new List<Product2>();
			for(Integer i = 0; i < 3; i++) {
				additionals.add(
					Build.aProduct().withName(mainProduct.Name + '-' + i)
						.withNumber('s' + mainProduct.Numero__c + '-' + i)
						.withDistributionChannel('10').build()
				);
			}

			additionalsByProduct.put(mainProduct.Id, additionals);
			allAdditionals.addAll(additionals);
		}
		allAdditionals.add(Build.aProduct().withName('AREA PROTEGIDA TRA').withNumber('AREA PROTEGIDA TRA').withDistributionChannel('10').build());
		insert allAdditionals;


		List<Adicional_de_producto__c> additionalRelations = new List<Adicional_de_producto__c>();
		for(Product2 mainProduct : products) {
			List<Product2> additionals = additionalsByProduct.get(mainProduct.Id);
			for(Product2 additional : additionals) {
				additionalRelations.add(
					Build.anAdditionalProductRelation().forMainProduct(mainProduct).forAdditionalProduct(additional).build()
				);
			}
		}
		insert additionalRelations;
		products.addAll(allAdditionals);
	}

	private static void createServices() {
		servicesByProduct = new Map<Id, List<Servicio__c>>();
		List<Servicio__c> allServices = new List<Servicio__c>();
		for(Product2 mainProduct : products) {
			List<Servicio__c> services = new List<Servicio__c>();
			for(Integer i = 0; i < 5; i++) {
				Servicio__c aService = Build.aService()
					.withName('Service ' + mainProduct.Name + ' ' + i)
					.withNumber('Service ' + mainProduct.Name + ' ' + i).build();
				services.add(aService);
				allServices.add(aService);
			}
			servicesByProduct.put(mainProduct.Id, services);
		}
		insert allServices;
		List<Servicio_de_Producto__c> productServiceRelation = new List<Servicio_de_Producto__c>();
		for(Product2 mainProduct : products) {
			List<Servicio__c> services = servicesByProduct.get(mainProduct.Id);
			for(Servicio__c aService : services) {
				productServiceRelation.add(
					Build.aServiceProductRelation().forProduct(mainProduct).forService(aService).build()
				);
			}
		}
		insert productServiceRelation;
	}
}
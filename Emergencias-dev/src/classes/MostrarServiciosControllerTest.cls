@isTest
private class MostrarServiciosControllerTest {
	
    static testMethod void canGetTheProductsOfAContract() {
        PageReference pageRef = Page.MostrarServicios;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', aContract.id);
        
        MostrarServiciosController controller = new MostrarServiciosController();
		controller.regenerateOpportunityLineItems();

				
        List<Cobertura__c> additionals = controller.Products[0].getAdditionals();
        controller.Products[0].SelectedAdditionals = new List<String>();

        System.assertEquals(5, controller.Products.size() );
        System.assertEquals(products[0].id, controller.Products[0].MainProduct.id );
        System.assertEquals(products[1].id, controller.Products[1].MainProduct.id );
        System.assertEquals(products[2].id, controller.Products[2].MainProduct.id );
        System.assertEquals(products[3].id, controller.Products[3].MainProduct.id );
        System.assertEquals(products[4].id, controller.Products[4].MainProduct.id );
    }
    static testMethod void canGetTheProductsOfAContractAndHisDiscountsAndServices()  {
        PageReference pageRef = Page.MostrarServicios;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', aContract.id);
        
        MostrarServiciosController controller = new MostrarServiciosController();
		controller.regenerateOpportunityLineItems();

        
        System.assertEquals(5, controller.Products[0].Discounts.size() );
        System.assertEquals(5, controller.Products[1].Discounts.size() );
        System.assertEquals(5, controller.Products[2].Discounts.size() );
        System.assertEquals(5, controller.Products[3].Discounts.size() );
        System.assertEquals(5, controller.Products[4].Discounts.size() );
        
        System.assertEquals(5, controller.Products[0].Services.size() );
        System.assertEquals(5, controller.Products[1].Services.size() );
        System.assertEquals(5, controller.Products[2].Services.size() );
        System.assertEquals(5, controller.Products[3].Services.size() );
        System.assertEquals(5, controller.Products[4].Services.size() );
	}
	
	static testMethod void canGetTheProductsOfARecipient() {
		Titular__c aHolder = Build.aHolder().forAccount(anAccount).forContract(aContract).build();
		insert aHolder;

		Beneficiario__c aRecipient = Build.aRecipient().forAccount(anAccount)
									.forContract(aContract).forHolder(aHolder).build();

		insert aRecipient;

		List<Cobertura_de_Beneficiario__c> recipientCoverageRelation = new List<Cobertura_de_Beneficiario__c>();
		for (Cobertura__c coverage : coverages.values()) {
			recipientCoverageRelation.add(
				Build.aCoverageRecipientRelation().forCoverage(coverage).forRecipient(aRecipient).build()
			);
		}
		insert recipientCoverageRelation;

		PageReference pageRef = Page.MostrarServicios;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('id', aRecipient.id);

		MostrarServiciosController controller = new MostrarServiciosController();
		controller.regenerateOpportunityLineItems();

		System.assertEquals(5, controller.Products.size() );
		System.assertEquals(products[0].id, controller.Products[0].MainProduct.id );
		System.assertEquals(products[1].id, controller.Products[1].MainProduct.id );
		System.assertEquals(products[2].id, controller.Products[2].MainProduct.id );
		System.assertEquals(products[3].id, controller.Products[3].MainProduct.id );
		System.assertEquals(products[4].id, controller.Products[4].MainProduct.id );
	}
	//==========================================================================
	static Account anAccount;
	static Opportunity anOpportunity;
	static Contrato__c aContract;
	static List<Product2> products;
    static Map<id, Cobertura__c> coverages;
	static Map<Id, List<Product2>> additionalsByProduct;
	static Map<Id, List<Servicio__c>> servicesByProduct;
	static Map<Id, List<Descuento_Recargo__c>> discountsByProduct;
	static Map<Id, List<Descuento_Recargo_Aplicado__c>> appliedDiscountsByProduct;
	static User aSalesperson;
	
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
        createcoverages();
        createDiscounts();
        
		       
		
	}
	
	private static void createProducts() {
		products = new List<Product2>();
		for(Integer i = 0; i < 5; i++) {
			products.add(Build.aProduct().withName('Prod ' + i).withNumber('PRD' + i).build());
		}
		insert products;
		
		additionalsByProduct = new Map<Id, List<Product2>>();
		List<Product2> allAdditionals = new List<Product2>();
		for(Product2 mainProduct : products) {
			List<Product2> additionals = new List<Product2>();
			for(Integer i = 0; i < 3; i++) {
				additionals.add(
					Build.aProduct().withName(mainProduct.Name + '-' + i)
						.withNumber('s' + mainProduct.Numero__c + '-' + i).build()
				);
			}
			
			additionalsByProduct.put(mainProduct.Id, additionals);
			allAdditionals.addAll(additionals);
		}
		insert allAdditionals;
		
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
    
    
	private static void createcoverages() {
        coverages = new Map<Id, Cobertura__c>();
        for (Product2 mainProduct : products) {
            Cobertura__c coverage = build.aCoverage()
                			.forContract(aContract)
                			.forProduct(mainProduct)
                			.withName('Coverage: '+mainProduct.name)
                			.build();
            
            coverages.put(coverage.Producto__c, coverage);
            
        }
        insert coverages.values();
    }
    
	private static void createDiscounts() {
    	discountsByProduct = new Map<Id, List<Descuento_Recargo__c> >();
		List<Descuento_Recargo__c> allDiscounts = new List<Descuento_Recargo__c>();
        
        for(Product2 mainProduct : products) {
			List<Descuento_Recargo__c> discounts = new List<Descuento_Recargo__c>();
			for(Integer i = 0; i < 5; i++) {
				Descuento_Recargo__c aDiscounts = build.aDiscount()
					.withName('Discount ' + mainProduct.Name + ' ' + i).build();
				discounts.add(aDiscounts);
				allDiscounts.add(aDiscounts);
			}
			discountsByProduct.put(mainProduct.Id, discounts);
		}
        insert allDiscounts;
        
        
		List<Descuento_Recargo_Aplicado__c> allAppliedDiscounts = new List<Descuento_Recargo_Aplicado__c>();
		for(Product2 mainProduct : products) {
			Cobertura__c coverage = coverages.get(mainProduct.Id);
            List<Descuento_recargo__c> discounts = discountsByProduct.get(mainProduct.Id);
			for(Descuento_recargo__c discount : discounts) {
				allAppliedDiscounts.add(
                	build.anAppliedDiscount()
                    	.forDiscount(discount)
                    	.forCoverage(coverage)
                    	.build()
                );
			}
		}
		insert allAppliedDiscounts;
        
		
        
        
    }
    
    

}
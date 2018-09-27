@isTest
private class ClonarContratoTest  {
	private static testMethod void itShouldBePosibleToCloneAContract() {
		Contrato__c cloneContract = ClonarContrato.clonar(aContract.Id);
		
		System.assertNotEquals(aContract.Id, cloneContract.Id);
		System.assertNotEquals(null, cloneContract.Id);
		
		System.assertEquals(anAccount.Id, cloneContract.Cliente__c);
		System.assertEquals(aContract.Numero_Unico_de_Contrato__c, cloneContract.Numero_Unico_de_Contrato__c);
		System.assertEquals('En proceso de venta', cloneContract.Estado__c);
		System.assertEquals(aContract.Sufijo__c + 1, cloneContract.Sufijo__c);
	}
	
	private static testMethod void theClonedContractShouldHaveAClonedHolder() {
		Contrato__c clonContract = ClonarContrato.clonar(aContract.Id);
		
		Titular__c cloneHolder = [
			SELECT Id, Cliente__c
			FROM Titular__c
			WHERE Contrato__c= :clonContract.Id
		];
		
		System.assertNotEquals(aHolder.Id, cloneHolder.Id);
		System.assertEquals(aHolder.Cliente__c, cloneHolder.Cliente__c);
	}
	
	private static testMethod void theClonedContractShouldHaveClonedRecipients() {
		delete aRecipient;
		List<Beneficiario__c> recipients = new List<Beneficiario__c>();
		Map<Id, RecordType> recipientTypes = new Map<Id, RecordType>([
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Beneficiario__c'
				AND IsActive = true
		]);
		for(Id recordTypeId : recipientTypes.keySet()) {
			recipients.add(
				Build.aRecipient().forContract(aContract).forHolder(aHolder)
					.withRecordTypeId(recordTypeId).build()
			);
		}
		insert recipients;
		
		Contrato__c clone = ClonarContrato.clonar(aContract.Id);
		
		List<Beneficiario__c> cloneRecipients = [
			SELECT Id, RecordTypeId
			FROM Beneficiario__c
			WHERE Contrato__c = :clone.Id
		];
		
		System.assertEquals(recipients.size(), cloneRecipients.size());
		for(Beneficiario__c cloneRecipient : cloneRecipients) {
			System.assert(recipientTypes.containsKey(cloneRecipient.RecordTypeId));
			recipientTypes.remove(cloneRecipient.RecordTypeId);
		}
	}
	
	private static testMethod void theClonedContractShouldHaveItsCoveragesCloned() {
		List<Cobertura__c> coverages = new List<Cobertura__c>();
		for(Integer i = 0; i < 3; i++) {
			coverages.add(Build.aCoverage().forProduct(aProduct).forContract(aContract).build());
		}
		insert coverages;
		coverages.add(aCoverage);
		
		Contrato__c clone = ClonarContrato.clonar(aContract.Id);
		
		List<Cobertura__c> clonedCoverages = [
			SELECT Id, Producto__c
			FROM Cobertura__c
			WHERE Contrato__c = :clone.Id
		];
		
		System.assertEquals(coverages.size(), clonedCoverages.size());
	}
	
	private static testMethod void theClonedContractShouldHaveTheRecipientsCoveragesCloned() {
		Contrato__c cloneContract = ClonarContrato.clonar(aContract.Id);
		
		Beneficiario__c clonedRecipient = [
			SELECT Id, RecordTypeId
			FROM Beneficiario__c
			WHERE Contrato__c = :cloneContract.Id
		];
		
		Cobertura__c clonedCoverage = [
			SELECT Id, Producto__c
			FROM Cobertura__c
			WHERE Contrato__c = :cloneContract.Id
		];
		
		Cobertura_de_Beneficiario__c clonedRecipientCoverage = [
			SELECT Id, Beneficiario__c, Cobertura__c
			FROM Cobertura_de_Beneficiario__c
			WHERE NOT Id = :aRecipientCoberage.Id
		];
		
		System.assertEquals(clonedCoverage.Id, clonedRecipientCoverage.Cobertura__c);
		System.assertEquals(clonedRecipient.Id, clonedRecipientCoverage.Beneficiario__c);
	}
	
	private static testMethod void theClonedContractShouldHaveItsDiscountsCloned() {
		Contrato__c cloneContract = ClonarContrato.clonar(aContract.Id);
		
		Cobertura__c clonedCoverage = [
			SELECT Id
			FROM Cobertura__c
			WHERE Contrato__c = :cloneContract.Id
		];
		
		List<Descuento_Recargo_Aplicado__c> clonedDiscounts = [
			SELECT Id, Descuento_o_Recargo__c
			FROM Descuento_Recargo_Aplicado__c
			WHERE Producto_de_Contrato__c = :clonedCoverage.Id
		];
		
		System.assertEquals(1, clonedDiscounts.size());
		System.assertEquals(anAppliedDiscount.Descuento_o_Recargo__c, clonedDiscounts[0].Descuento_o_Recargo__c);
	}
	
	private static testMethod void theClonedContractShouldHaveItsAplicationsCloned() {
		Aplicante__c anApplication = Build.anApplicant().forAppliedDiscount(anAppliedDiscount)
			.forRecipientCoverage(aRecipientCoberage).withEndDate(System.today().addYears(3)).build();
		insert anApplication;
		
		Contrato__c cloneContract = ClonarContrato.clonar(aContract.Id);
		
		Cobertura__c clonedCoverage = [
			SELECT Id
			FROM Cobertura__c
			WHERE Contrato__c = :cloneContract.Id
		];
		
		Cobertura_de_Beneficiario__c clonedRecipientCoverage = [
			SELECT Id
			FROM Cobertura_de_Beneficiario__c
			WHERE Cobertura__c = :clonedCoverage.Id
		];
		
		Descuento_Recargo_Aplicado__c clonedDiscount = [
			SELECT Id
			FROM Descuento_Recargo_Aplicado__c
			WHERE Producto_de_Contrato__c = :clonedCoverage.Id
		];
		
		Aplicante__c clonedAplication = [
			SELECT Id, Cobertura__c
			FROM Aplicante__c
			WHERE Descuento_Recargo_Aplicado__c = :clonedDiscount.Id
		];
		
		System.assertEquals(clonedRecipientCoverage.Id, clonedAplication.Cobertura__c);
	}
	
	private static testMethod void aContractWithCreditCardShouldKeepItsCardNumber() {
		Contrato__c anotherContract = Build.aContract().withUniqueNumber().forAccount(anAccount)
			.withValidCardNumber().build();
		insert anotherContract;
		
		Contrato__c clonedContract = ClonarContrato.clonar(anotherContract.Id);
		
		List<Contrato__c> contractsInDb = [
			SELECT Id, Tarjeta_sin_cifrar__c, Numero_de_tarjeta__c
			FROM Contrato__c
			WHERE Id = :clonedContract.Id
				OR Id = :anotherContract.Id
		];
		if(contractsInDb[0].Id == clonedContract.Id) {
			clonedContract = contractsInDb[0];
			anotherContract = contractsInDb[1];
		}
		else {
			anotherContract = contractsInDb[0];
			clonedContract = contractsInDb[1];
		}
		
		System.assertEquals(
			anotherContract.Tarjeta_sin_cifrar__c,
			clonedContract.Tarjeta_sin_cifrar__c
		);
		System.assertEquals(
			anotherContract.Numero_de_tarjeta__c,
			clonedContract.Numero_de_tarjeta__c
		);
	}
	
	private static testMethod void itShouldBePosibleToCloneMultipleContracts() {
		List<Contrato__c> contracts = new List<Contrato__c>();
		for(Integer i = 0; i < 5; i++) {
			contracts.add(
				Build.aContract().withUniqueNumber().forAccount(anAccount)
				.withValidCardNumber().build()
			);
		}
		insert contracts;
		Set<Id> contractIds = new Set<Id>();
		for(Contrato__c contract : contracts) {
			contractIds.add(contract.Id);
		}
		contractIds.add(aContract.Id);
		
		Map<Id, Contrato__c> clonedContracts = ClonarContrato.clonar(contractIds);
		
		System.assertEquals(contractIds.size(), clonedContracts.size());
		for(Id originalId : contractIds) {
			Contrato__c clone = clonedContracts.get(originalId);
			System.assertNotEquals(null, clone.Id);
			System.assertNotEquals(originalId, clone.Id);
		}
	}
	
	private static testMethod void whenCloningAContractTheSufixShouldAlwaysBeIncrementedByOne() {
		Contrato__c lastContract = aContract;
		for(Integer i = 0; i < 5; i++) {
			Contrato__c cloneContract = ClonarContrato.clonar(lastContract.Id);
			
			System.assertEquals(lastContract.Sufijo__c + 1, cloneContract.Sufijo__c);
			
			lastContract = cloneContract;
		}
	}
	
	private static testMethod void theClonedContractShouldHaveTheActiveRecipientCoverageAmountDetailsCloned() {
		Cantidad_de_producto_de_beneficiaro__c activeAmountDetail = Build.anAmountDetail()
			.forRecipientCoverageRelation(aRecipientCoberage).withAmount(3).withTransitAmount(2)
			.isActive().build();
		Cantidad_de_producto_de_beneficiaro__c inactiveAmountDetail = Build.anAmountDetail()
			.forRecipientCoverageRelation(aRecipientCoberage).withAmount(5).withTransitAmount(4)
			.build();
		insert new List<Cantidad_de_producto_de_beneficiaro__c> {
			activeAmountDetail,
			inactiveAmountDetail
		};
		Set<Id> originalAmountDetailsIds = new Set<Id>();
		originalAmountDetailsIds.add(activeAmountDetail.Id);
		originalAmountDetailsIds.add(inactiveAmountDetail.Id);
		
		Contrato__c cloneContract = ClonarContrato.clonar(aContract.Id);
		
		Beneficiario__c clonedRecipient = [
			SELECT Id, RecordTypeId
			FROM Beneficiario__c
			WHERE Contrato__c = :cloneContract.Id
		];
		
		Cobertura__c clonedCoverage = [
			SELECT Id, Producto__c
			FROM Cobertura__c
			WHERE Contrato__c = :cloneContract.Id
		];
		
		Cobertura_de_Beneficiario__c clonedRecipientCoverage = [
			SELECT Id
			FROM Cobertura_de_Beneficiario__c
			WHERE Cobertura__c = :clonedCoverage.Id
				AND Beneficiario__c = :clonedRecipient.Id
		];
		
		Cantidad_de_producto_de_beneficiaro__c clonedAmountDetail = [
			SELECT Id, Cantidad__c, Cantidad_en_transito__c, Activo__c
			FROM Cantidad_de_producto_de_beneficiaro__c
			WHERE Id NOT IN :originalAmountDetailsIds
				AND Cobertura_de_Beneficiario__c = :clonedRecipientCoverage.Id
		];
		
		System.assertEquals(activeAmountDetail.Cantidad__c, clonedAmountDetail.Cantidad__c);
		System.assertEquals(
			activeAmountDetail.Cantidad_en_transito__c,
			clonedAmountDetail.Cantidad_en_transito__c
		);
		System.assertEquals(true, clonedAmountDetail.Activo__c);
	}
	
	//==========================================================================
	static Account anAccount;
	static Opportunity anOpportunity; //Not needed
	static Contrato__c aContract;
	static Titular__c aHolder;
	static Beneficiario__c aRecipient;
	static Cobertura__c aCoverage;
	static Product2 aProduct;
	static Cobertura_de_Beneficiario__c aRecipientCoberage;
	static Descuento_Recargo_Aplicado__c anAppliedDiscount;
	
	static {
		Id opportunityType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Opportunity'
				AND IsActive = true
            	AND DeveloperName = 'Venta_Consumidor_Final'
			LIMIT 1
		].Id;
		
		anAccount = Build.anAccount().isPersonAccount().build();
		insert anAccount;
		
		anOpportunity = Build.anOpportunity().forAccount(anAccount).withDischargeTypeNew()
			.withRecordTypeId(opportunityType).build();
		insert anOpportunity;
		
		//Created by a trigger
		aContract = [
			SELECT Id, Estado__c, Cliente__c, Numero_Unico_de_Contrato__c, Sufijo__c
			FROM Contrato__c
			WHERE Id IN (
					SELECT Contrato__c
				  	FROM Opportunity
				  	WHERE Id = :anOpportunity.Id
				)
		];
		aContract.Estado__c = 'Activo';
		
		//Created by a process
		aHolder = [
			SELECT Id, Numero_de_Titular__c, Ult_Numero_de_beneficiario__c, Cliente__c
			FROM Titular__c
			WHERE Contrato__c = :aContract.Id
		];
		
		Account adhered = Build.anAccount().withCUILCUIT('20987654324').build();
		insert adhered;
		aRecipient = Build.aRecipient().forContract(aContract)
			.forAccount(adhered).forHolder(aHolder).forOpportunity(anOpportunity).build();
		insert aRecipient;
		
		aProduct = Build.aProduct().withName('Prod').build();
		insert aProduct;
		aCoverage = Build.aCoverage().forProduct(aProduct).forContract(aContract).build();
		insert aCoverage;
		
		aRecipientCoberage = Build.aCoverageRecipientRelation().forCoverage(aCoverage).forRecipient(aRecipient).build();
		insert aRecipientCoberage;
		
		Descuento_Recargo__c aDiscount = Build.aDiscount().build();
		insert aDiscount;
		
		anAppliedDiscount = Build.anAppliedDiscount().forCoverage(aCoverage).forDiscount(aDiscount).build();
		insert anAppliedDiscount;
	}
}
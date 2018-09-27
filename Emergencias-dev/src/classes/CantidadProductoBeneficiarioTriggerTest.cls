@isTest
private class CantidadProductoBeneficiarioTriggerTest {
	@isTest
	private static void whenAnAmountDetailIsInsertedAsActiveTheAmountsShouldBeCopiedToTheCoverageRecipientRelation() {
		Product2 aProduct = Build.aProduct().withName('Prod 1').withNumber('Prod 1')
			.withSector(Product2.Sector__c.getDescribe().getPicklistValues()[0].getValue()).build();
		insert aProduct;
		
		//=================================================
		Account anAccount = Build.anAccount().withCUILCUIT('23456789234').build();
		insert anAccount;
		
		String cardType = Contrato__c.Tipo_de_Tarjeta__c.getDescribe().getPicklistValues()[0].getValue();
		Contrato__c aContract = Build.aContract().forAccount(anAccount).withPaymentCondition('C010')
			.withUniqueNumber().withSalesOrganization('0010').withDistributionChannel('30')
			.withCardType(cardType).withPaymentMethod('A').withValidCardNumber().withSkipSend(200)
			.withSalesOffice().withSalesGroup()
			.withSapDocumentType('C0').build();
		insert aContract;
		
		Titular__c aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		
		Cobertura__c aCoverage = Build.aCoverage().forProduct(aProduct).forContract(aContract)
			.build();
		insert aCoverage;
		
		//Create recipient
		RecordType addressRecipientType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Beneficiario__c'
				AND DeveloperName = 'Domicilio'
				AND IsActive = true
		];
		String addressCategory = Beneficiario__c.Rubro_del_domicilio__c.getDescribe()
			.getPicklistValues()[0].getValue();
		String province = Beneficiario__c.Provincia1__c.getDescribe()
			.getPicklistValues()[0].getValue();
		Beneficiario__c recipient = Build.aRecipient().forContract(aContract)
			.forHolder(aHolder).withUniqueCode('123wad3241').withProvince(province)
			.withIVATreatment('BE').withAddressCategory(addressCategory)
			.withRecordType(addressRecipientType).build();
		insert recipient;
		
		Cobertura_de_Beneficiario__c recipientCoverage = Build.aCoverageRecipientRelation()
			.forRecipient(recipient).forCoverage(aCoverage).Build();
		insert recipientCoverage;
		
		Cantidad_de_producto_de_beneficiaro__c amountDetail = Build.anAmountDetail()
			.forRecipientCoverageRelation(recipientCoverage).withAmount(3).withTransitAmount(2)
			.isActive().build();
		
		//================================
		//Execution
		insert amountDetail;
		
		//================================
		//Asserts
		Cobertura_de_Beneficiario__c recipientCoverageInDb = [
			SELECT Id, Cantidad_domicilio__c, Cantidad_domicilio_en_transito__c
			FROM Cobertura_de_Beneficiario__c
			WHERE Id = :recipientCoverage.Id
		];
		
		System.assertEquals(
			amountDetail.Cantidad__c,
			recipientCoverageInDb.Cantidad_domicilio__c
		);
		System.assertEquals(
			amountDetail.Cantidad_en_transito__c,
			recipientCoverageInDb.Cantidad_domicilio_en_transito__c
		);
	}
	
	@isTest
	private static void whenAnAmountDetailIsUpdatedAsActiveTheAmountsShouldBeCopiedToTheCoverageRecipientRelation() {
		Product2 aProduct = Build.aProduct().withName('Prod 1').withNumber('Prod 1')
			.withSector(Product2.Sector__c.getDescribe().getPicklistValues()[0].getValue()).build();
		insert aProduct;
		
		//=================================================
		Account anAccount = Build.anAccount().withCUILCUIT('23456789234').build();
		insert anAccount;
		
		String cardType = Contrato__c.Tipo_de_Tarjeta__c.getDescribe().getPicklistValues()[0].getValue();
		Contrato__c aContract = Build.aContract().forAccount(anAccount).withPaymentCondition('C010')
			.withUniqueNumber().withSalesOrganization('0010').withDistributionChannel('30')
			.withCardType(cardType).withPaymentMethod('A').withValidCardNumber().withSkipSend(200)
			.withSalesOffice().withSalesGroup()
			.withSapDocumentType('C0').build();
		insert aContract;
		
		Titular__c aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		
		Cobertura__c aCoverage = Build.aCoverage().forProduct(aProduct).forContract(aContract)
			.build();
		insert aCoverage;
		
		//Create recipient
		RecordType addressRecipientType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Beneficiario__c'
				AND DeveloperName = 'Domicilio'
				AND IsActive = true
		];
		String addressCategory = Beneficiario__c.Rubro_del_domicilio__c.getDescribe()
			.getPicklistValues()[0].getValue();
		String province = Beneficiario__c.Provincia1__c.getDescribe()
			.getPicklistValues()[0].getValue();
		Beneficiario__c recipient = Build.aRecipient().forContract(aContract)
			.forHolder(aHolder).withUniqueCode('123wad3241').withProvince(province)
			.withIVATreatment('BE').withAddressCategory(addressCategory)
			.withRecordType(addressRecipientType).build();
		insert recipient;
		
		Cobertura_de_Beneficiario__c recipientCoverage = Build.aCoverageRecipientRelation()
			.forRecipient(recipient).forCoverage(aCoverage).Build();
		insert recipientCoverage;
		
		Cantidad_de_producto_de_beneficiaro__c amountDetail = Build.anAmountDetail()
			.forRecipientCoverageRelation(recipientCoverage).withAmount(3).withTransitAmount(2)
			.build();
		insert amountDetail;
		
		//================================
		//Execution
		amountDetail.Activo__c = true;
		update amountDetail;
		
		//================================
		//Asserts
		Cobertura_de_Beneficiario__c recipientCoverageInDb = [
			SELECT Id, Cantidad_domicilio__c, Cantidad_domicilio_en_transito__c
			FROM Cobertura_de_Beneficiario__c
			WHERE Id = :recipientCoverage.Id
		];
		
		System.assertEquals(
			amountDetail.Cantidad__c,
			recipientCoverageInDb.Cantidad_domicilio__c
		);
		System.assertEquals(
			amountDetail.Cantidad_en_transito__c,
			recipientCoverageInDb.Cantidad_domicilio_en_transito__c
		);
	}
	
	@isTest
	private static void whenAnAmountDetailIsInsertedAsActiveAndThereAlreadyIsAnActiveDetailTheOldOneShouldBeDeactivated() {
		Product2 aProduct = Build.aProduct().withName('Prod 1').withNumber('Prod 1')
			.withSector(Product2.Sector__c.getDescribe().getPicklistValues()[0].getValue()).build();
		insert aProduct;
		
		//=================================================
		Account anAccount = Build.anAccount().withCUILCUIT('23456789234').build();
		insert anAccount;
		
		String cardType = Contrato__c.Tipo_de_Tarjeta__c.getDescribe().getPicklistValues()[0].getValue();
		Contrato__c aContract = Build.aContract().forAccount(anAccount).withPaymentCondition('C010')
			.withUniqueNumber().withSalesOrganization('0010').withDistributionChannel('30')
			.withCardType(cardType).withPaymentMethod('A').withValidCardNumber().withSkipSend(200)
			.withSalesOffice().withSalesGroup()
			.withSapDocumentType('C0').build();
		insert aContract;
		
		Titular__c aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		
		Cobertura__c aCoverage = Build.aCoverage().forProduct(aProduct).forContract(aContract)
			.build();
		insert aCoverage;
		
		//Create recipient
		RecordType addressRecipientType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Beneficiario__c'
				AND DeveloperName = 'Domicilio'
				AND IsActive = true
		];
		String addressCategory = Beneficiario__c.Rubro_del_domicilio__c.getDescribe()
			.getPicklistValues()[0].getValue();
		String province = Beneficiario__c.Provincia1__c.getDescribe()
			.getPicklistValues()[0].getValue();
		Beneficiario__c recipient = Build.aRecipient().forContract(aContract)
			.forHolder(aHolder).withUniqueCode('123wad3241').withProvince(province)
			.withIVATreatment('BE').withAddressCategory(addressCategory)
			.withRecordType(addressRecipientType).build();
		insert recipient;
		
		Cobertura_de_Beneficiario__c recipientCoverage = Build.aCoverageRecipientRelation()
			.forRecipient(recipient).forCoverage(aCoverage).Build();
		insert recipientCoverage;
		
		Cantidad_de_producto_de_beneficiaro__c amountDetail = Build.anAmountDetail()
			.forRecipientCoverageRelation(recipientCoverage).withAmount(3).withTransitAmount(2)
			.isActive().build();
		insert amountDetail;
		//================================
		//Execution
		Cantidad_de_producto_de_beneficiaro__c nextAmountDetail = Build.anAmountDetail()
			.forRecipientCoverageRelation(recipientCoverage).withAmount(3).withTransitAmount(2)
			.isActive().build();
		insert nextAmountDetail;
		
		//================================
		//Asserts
		List<Cantidad_de_producto_de_beneficiaro__c> detailsInDb = [
			SELECT Id, Activo__c
			FROM Cantidad_de_producto_de_beneficiaro__c
			WHERE Cobertura_de_Beneficiario__c = :recipientCoverage.Id
		];
		
		for(Cantidad_de_producto_de_beneficiaro__c detail : detailsInDb) {
			System.assertEquals(detail.Id == nextAmountDetail.Id, detail.Activo__c);
		}
		
	}
}
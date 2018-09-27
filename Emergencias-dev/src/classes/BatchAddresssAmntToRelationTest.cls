@isTest
private class BatchAddresssAmntToRelationTest {
	@isTest
	private static void itShouldBePosibleToCopyTheAmountsFromAddressRecipientsToTheProductRelation() {
		integer batchSize = 500;
		Id opportunityType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Opportunity'
				AND IsActive = true
				AND DeveloperName = 'Venta_Consumidor_Final'
			LIMIT 1
		].Id;
		Account anAccount = Build.anAccount().isPersonAccount().build();
		insert anAccount;
		Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount)
			.withDischargeTypeNew().withRecordTypeId(opportunityType).build();
		insert anOpportunity;
		Contrato__c aContract = [
			SELECT Id
			FROM Contrato__c
			WHERE Id IN (SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		];
		
		List<Titular__c> holders = [
			SELECT Id
			FROM Titular__c
			WHERE Contrato__c = :aContract.Id
		];
		
		Product2 aProduct = Build.aProduct().withName('Prod 1').build();
		insert aProduct;
		
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract).forProduct(aProduct).build();
		insert aCoverage;
		
		RecordType addressType = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Domicilio'
				AND sObjectType = 'Beneficiario__c'
				AND IsActive = true
			LIMIT 1
		];
		List<Beneficiario__c> recipients = new List<Beneficiario__c>();
		for(Integer i = 0; i < batchSize; i++) {
			recipients.add(
				Build.aRecipient().forContract(aContract)
					.forAccount(anAccount).forHolder(holders[0]).forOpportunity(anOpportunity)
					.withRecordType(addressType).withFixedPersonAmount(i + 1)
					.withInTransitPersonAmount(i + 2).build()
			);
		}
		insert recipients;
		
		List<Cobertura_de_Beneficiario__c> coverageRelations = new List<Cobertura_de_Beneficiario__c>();
		for(Beneficiario__c recipient : recipients) {
			coverageRelations.add(
				Build.aCoverageRecipientRelation()
					.forRecipient(recipient).forCoverage(aCoverage).build()
			);
		}
		insert coverageRelations;
		
		//========================================
		Test.startTest();
		BatchAddresssAmntToRelation batch = new BatchAddresssAmntToRelation();
		Database.executeBatch(batch, batchSize);
		Test.stopTest();
		
		//========================================
		//Gather results
		Set<Id> coverageRelationIds = new Set<Id>();
		for(Cobertura_de_Beneficiario__c relation : coverageRelations) {
			coverageRelationIds.add(relation.Id);
		}
		Map<Id, Cobertura_de_Beneficiario__c> coverageRelationsInDb =
			new Map<Id, Cobertura_de_Beneficiario__c>([
				SELECT Id, Cantidad_domicilio__c, Cantidad_domicilio_en_transito__c,
					Beneficiario__r.Cantidad_de_Personas_Fijas__c,
					Beneficiario__r.Cantidad_de_personas_en_transito__c
				FROM Cobertura_de_Beneficiario__c
				WHERE Id IN :coverageRelationIds
			]
		);
		List<Cantidad_de_producto_de_beneficiaro__c> amountDetails = [
			SELECT Id, Activo__c, Cobertura_de_Beneficiario__c,
				Cantidad__c, Cantidad_en_transito__c
			FROM Cantidad_de_producto_de_beneficiaro__c
			WHERE Cobertura_de_Beneficiario__c IN :coverageRelationIds
		];
		//========================================
		//asserts
		System.assertEquals(coverageRelationsInDb.size(), amountDetails.size());
		for(Cantidad_de_producto_de_beneficiaro__c amountDetail : amountDetails) {
			Cobertura_de_Beneficiario__c relation =
				coverageRelationsInDb.get(amountDetail.Cobertura_de_Beneficiario__c);
			
			System.assertEquals(
				relation.Beneficiario__r.Cantidad_de_Personas_Fijas__c,
				relation.Cantidad_domicilio__c
			);
			System.assertEquals(
				relation.Beneficiario__r.Cantidad_de_personas_en_transito__c,
				relation.Cantidad_domicilio_en_transito__c
			);
			
			System.assertEquals(
				relation.Cantidad_domicilio__c,
				amountDetail.Cantidad__c
			);
			System.assertEquals(
				relation.Cantidad_domicilio_en_transito__c,
				amountDetail.Cantidad_en_transito__c
			);
			System.assertEquals(true, amountDetail.Activo__c);
		}
	}
}
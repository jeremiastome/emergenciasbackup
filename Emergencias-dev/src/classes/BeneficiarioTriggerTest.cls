@isTest
private class BeneficiarioTriggerTest {
	private static testMethod void whenARecipientIsCreatedItShouldHaveAUniqueNumberBasedOnItsHolder() {
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract)
			.forAccount(anAccount).forHolder(aHolder).forOpportunity(anOpportunity).build();
		
		insert aRecipient;
		
		Beneficiario__c theRecipientInDB = [
			SELECT Id, N_mero_nico_de_Beneficiario__c
			FROM Beneficiario__c
			WHERE Id = :aRecipient.Id
		];
		
		System.assertEquals(
			aHolder.Numero_de_Titular__c + '/' + (
				'00' + String.valueOf(Integer.valueOf(aHolder.Ult_Numero_de_beneficiario__c) + 1)
			).right(3),
			theRecipientInDB.N_mero_nico_de_Beneficiario__c
		);
	}
	
	private static testMethod void whenARecipientIsCreatedItsHolderShouldHaveItsLastRecipientNumberUpdated() {
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract)
			.forAccount(anAccount).forHolder(aHolder).forOpportunity(anOpportunity).build();
		
		insert aRecipient;
		
		Titular__c theHolderInDB = [
			SELECT Id, Ult_Numero_de_beneficiario__c
			FROM Titular__c
			WHERE Id = :aHolder.Id
		];
		
		System.assertEquals(
			('00' + String.valueOf(Integer.valueOf(aHolder.Ult_Numero_de_beneficiario__c) + 1)).right(3),
			theHolderInDB.Ult_Numero_de_beneficiario__c
		);
	}
	
	private static testMethod void whenMultipleRecipientsAreInsertedTheirUniqueNumberShouldBeDifferent() {
		List<Beneficiario__c> recipients = new List<Beneficiario__c>();
		for(Integer i = 0; i < 100; i++) {
			recipients.add(
				Build.aRecipient().forContract(aContract).forAccount(anAccount)
					.forHolder(aHolder).forOpportunity(anOpportunity).build()
			);
		}
		
		insert recipients;
		
		List<Beneficiario__c> theRecipientsInDB = [
			SELECT Id, N_mero_nico_de_Beneficiario__c
			FROM Beneficiario__c
		];
		
		Set<String> uniqueNumbers = new Set<String>();
		for(Beneficiario__c recipient : theRecipientsInDB) {
			System.assert(
				!uniqueNumbers.contains(recipient.N_mero_nico_de_Beneficiario__c),
				'The number ' + recipient.N_mero_nico_de_Beneficiario__c + ' was duplicated'
			);
			uniqueNumbers.add(recipient.N_mero_nico_de_Beneficiario__c);
		}
		
		Titular__c theHolderInDB = [
			SELECT Id, Ult_Numero_de_beneficiario__c
			FROM Titular__c
			WHERE Id = :aHolder.Id
		];
		System.assertEquals('100', theHolderInDB.Ult_Numero_de_beneficiario__c);
	}
	
	private static testMethod void theUpdatesToLastRecipientNumberInTheHolderShouldBeCummulative() {
		List<Beneficiario__c> recipients = new List<Beneficiario__c>();
		for(Integer i = 0; i < 50; i++) {
			recipients.add(
				Build.aRecipient().forContract(aContract).forAccount(anAccount)
					.forHolder(aHolder).forOpportunity(anOpportunity).build()
			);
		}
		
		insert recipients;
		
		recipients = new List<Beneficiario__c>();
		for(Integer i = 0; i < 50; i++) {
			recipients.add(
				Build.aRecipient().forContract(aContract).forAccount(anAccount)
					.forHolder(aHolder).forOpportunity(anOpportunity).build()
			);
		}
		
		insert recipients;
		
		Titular__c theHolderInDB = [
			SELECT Id, Ult_Numero_de_beneficiario__c
			FROM Titular__c
			WHERE Id = :aHolder.Id
		];
		System.assertEquals('100', theHolderInDB.Ult_Numero_de_beneficiario__c);
	}

	//==========================================================================
	static testMethod void cuandoSeHaceUnaModificacionEnUnBeneficiarioSinTenerUnCasoAdjuntoSeEnviaSuContratoComoModificacionASAP () {
		//TODO
	}
	
	//==========================================================================
	static Account anAccount;
	static Opportunity anOpportunity;
	static Contrato__c aContract;
	static Titular__c aHolder;
	static Cobertura__c cobertura;
	
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
		anOpportunity = Build.anOpportunity().forAccount(anAccount)
			.withDischargeTypeNew().withRecordTypeId(opportunityType).build();
		insert anOpportunity;
		aContract = [//Created by a trigger
			SELECT Id
			FROM Contrato__c
			WHERE Id IN (SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		];
		
		aHolder = [//Created by a process
			SELECT Id, Numero_de_Titular__c, Ult_Numero_de_beneficiario__c
			FROM Titular__c
			WHERE Contrato__c = :aContract.Id
		];

		Product2 producto = Build.aProduct()
			.needsCredential()
			.build();
		insert producto;

		cobertura = Build.aCoverage()
			.forProduct(producto)
			.forContract(aContract)
			.build();
		insert cobertura;
	}
}
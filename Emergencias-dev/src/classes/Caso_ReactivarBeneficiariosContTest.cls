@isTest
private class Caso_ReactivarBeneficiariosContTest {
	private static testMethod void itShouldBePosibleToGetTheInactiveRecipientsAssociatedToACase() {
		List<Beneficiario__c> result = Caso_ReactivarBeneficiariosController.getRecipients(aCase.Id);
		
		System.assertEquals(1, result.size());
		System.assertEquals(aRecipient.Id, result[0].Id);
		System.assertEquals(1, result[0].Coberturas__r.size());
		System.assertEquals(aRecipientCoverage.Id, result[0].Coberturas__r[0].Id);
	}
	
	private static testMethod void itShouldBePosibleToSaveAListOfRecipientsWithCoverageRelations() {
		List<Beneficiario__c> recipients = Caso_ReactivarBeneficiariosController.getRecipients(aCase.Id);
		
		recipients[0].Caso__c = aCase.Id;
		recipients[0].Coberturas__r[0].Caso__c = aCase.Id;
		
		List<Cobertura_de_Beneficiario__c> coverageRelations = new List<Cobertura_de_Beneficiario__c>();
		for(Beneficiario__c recipient : recipients) {
			coverageRelations.addAll(recipient.Coberturas__r);
		}
		
		Caso_ReactivarBeneficiariosController.saveRecipients(recipients, coverageRelations);
		
		List<Beneficiario__c> recipientsInDb = [
			SELECT Id, Caso__c, (
					SELECT Id, Caso__c
					FROM Coberturas__r
				)
			FROM Beneficiario__c
			WHERE Id = :recipients[0].Id
		];
		
		System.assertEquals(aCase.Id, recipientsInDb[0].Caso__c);
		System.assertEquals(aCase.Id, recipientsInDb[0].Coberturas__r[0].Caso__c);
	}
	
	//==========================================================================
	static Product2 aProduct;
	static Account anAccount;
	static Contrato__c aContract;
	static Titular__c aHolder;
	static Beneficiario__c aRecipient;
	static Beneficiario__c anActiveRecipient;
	static Cobertura__c aCoverage;
	static Cobertura_de_Beneficiario__c aRecipientCoverage;
	static Case aCase;
	
	static {
		aProduct = Build.aProduct().build();
		insert aProduct;
		anAccount = Build.anAccount().build();
		insert anAccount;
		aContract = Build.aContract().forAccount(anAccount).build();
		insert aContract;
		aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		aRecipient = Build.aRecipient().forContract(aContract).forHolder(aHolder).withInactiveStatus().build();
		anActiveRecipient = Build.aRecipient().forContract(aContract).forHolder(aHolder).build();
		insert new List<Beneficiario__c> {aRecipient, anActiveRecipient};
		aCoverage =  Build.aCoverage().forContract(aContract).forProduct(aProduct).build();
		insert aCoverage;
		aRecipientCoverage = Build.aCoverageRecipientRelation().forCoverage(aCoverage).forRecipient(aRecipient).build();
		insert aRecipientCoverage;
		aCase = Build.aCase().forAccount(anAccount).forContract(aContract).build();
		insert aCase;
		
	}
}
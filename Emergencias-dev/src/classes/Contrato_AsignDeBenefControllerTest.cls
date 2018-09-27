@isTest
private class Contrato_AsignDeBenefControllerTest {
	private static testMethod void itShouldBePosibleToObtainIfAContractIsForMasiveRecipients() {
		boolean result = Contrato_AsignDeBenefController.isForMasiveRecipients(aContract.Id);
		
		System.assertEquals(result, aContract.Contrato_de_Padrones__c);
		aContract.Contrato_de_Padrones__c = !aContract.Contrato_de_Padrones__c;
		update aContract;
		
		result = Contrato_AsignDeBenefController.isForMasiveRecipients(aContract.Id);
		
		System.assertEquals(result, aContract.Contrato_de_Padrones__c);
	}
	
	private static testMethod void itShouldBePosibleToKnowIfAContractHasNoProducts() {
		boolean result = Contrato_AsignDeBenefController.contractHasProducts(aContract.Id);
		
		System.assertEquals(false, result);
		
		Product2 aProduct = Build.aProduct().withName('prod').build();
		insert aProduct;
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract).forProduct(aProduct).build();
		insert aCoverage;
		
		result = Contrato_AsignDeBenefController.contractHasProducts(aContract.Id);
		
		System.assertEquals(true, result);
	}
	
	//==========================================================================
	static Account anAccount;
	static Contrato__c aContract;
	
	static {
		anAccount = Build.anAccount().build();
		insert anAccount;
		aContract = Build.aContract().forAccount(anAccount).build();
		insert aContract;
	}
}
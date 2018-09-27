@isTest
private class Opp_AsignacionDeBeneficiosControllerTest {
	private static testMethod void ifTheContractHasProductsAssociated_ItShouldBePosibleToObtainTheContractId() {
		Contrato__c aContract = [
			SELECT Id
			FROM Contrato__c
			WHERE Id = :anOpportunity.Contrato__c
		];
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract).forProduct(aProduct).build();
		insert aCoverage;
		
		Id contractId = Opp_AsignacionDeBeneficiosController.getContractId(anOpportunity.Id);
		
		System.assertEquals(anOpportunity.Contrato__c, contractId);
	}
	
	private static testMethod void ifTheOpportunityDoesntHaveProductsAssociated_TheContractIdShouldNotBeReturned() {
		Id result = Opp_AsignacionDeBeneficiosController.getContractId(anOpportunity.Id);
		
		System.assertEquals(null, result);
	}
	
	//==========================================================================
	static Account anAccount;
	static Opportunity anOpportunity;
	static Product2 aProduct;
	static PricebookEntry aPriceBookEntry;
	
	static {
		aProduct = Build.aProduct().withName('Prod').build();
		insert aProduct;
		aPriceBookEntry = Build.aPriceBookEntry().forProduct(aProduct).withUnitPrice(4).build();
		insert aPriceBookEntry;
		anAccount = Build.anAccount().build();
		insert anAccount;
		anOpportunity = Build.anOpportunity().forAccount(anAccount).withDischargeTypeNew().build();
		insert anOpportunity;
		anOpportunity = [
			SELECT Id, Contrato__c
			FROM Opportunity
			WHERE Id = :anOpportunity.Id
		];
	}
}
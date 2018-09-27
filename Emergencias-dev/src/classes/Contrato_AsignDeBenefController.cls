public class Contrato_AsignDeBenefController {
	@AuraEnabled
	public static boolean isForMasiveRecipients(Id contractId) {
		Contrato__c c = [
			SELECT Contrato_de_Padrones__c
			FROM Contrato__c
			WHERE Id = :contractId
		];
		return c.Contrato_de_Padrones__c;
	}
	
	@AuraEnabled
	public static boolean contractHasProducts(Id contractId) {
		List<Cobertura__c> covs = [
			SELECT Id
			FROM Cobertura__c
			WHERE Contrato__c = :contractId
		];
		
		return covs.size() != 0;
	}
}
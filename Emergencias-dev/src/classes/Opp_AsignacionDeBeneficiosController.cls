public class Opp_AsignacionDeBeneficiosController {
	@AuraEnabled
	public static Id getContractId(Id oppId) {
		Opportunity opp = [
			SELECT Id, Contrato__c
			FROM Opportunity
			WHERE Id = :oppId
		];
		
		List<Cobertura__c> covs = new List<Cobertura__c>();
		if(opp.Contrato__c != null) {
			covs = [
				SELECT Id
				FROM Cobertura__c
				WHERE Contrato__c = :opp.Contrato__c
			];
		}
		
		if(covs.size() > 0) {
			return opp.Contrato__c;
		}
		else {
			return null;
		}
	}
}
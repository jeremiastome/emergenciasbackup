public class Caso_IrBajaParcialController {
	@AuraEnabled
	public static Id getContract(Id caseId) {
		Case c = [
			SELECT Id, Contrato__c
			FROM Case
			WHERE Id = :caseId
		];
		return c.Contrato__c;
	}
}
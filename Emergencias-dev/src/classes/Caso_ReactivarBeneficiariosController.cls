public class Caso_ReactivarBeneficiariosController {
	@AuraEnabled
	public static List<Beneficiario__c> getRecipients(Id caseId) {
		Case c = [
			SELECT Id, Contrato__c
			FROM Case
			WHERE Id = :caseId
		];
		
		return [
			SELECT Id, Caso__c, Apellido__c, Nombre__c, (
					SELECT Id, Caso__c, Cobertura__r.Producto__r.Numero__c
					FROM Coberturas__r
				)
			FROM Beneficiario__c
			WHERE Contrato__c = :c.Contrato__c
				AND Estado__c = 'Baja'
		];
	} 
	
	@AuraEnabled
	public static void saveRecipients(List<Beneficiario__c> recipients, List<Cobertura_de_Beneficiario__c> coverages) {
		update recipients;
		
		update coverages;
	}
}
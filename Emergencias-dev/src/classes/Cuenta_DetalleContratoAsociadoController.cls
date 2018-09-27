public class Cuenta_DetalleContratoAsociadoController {
	@AuraEnabled
	public static List<Contrato__c> getContracts(Id accId) {
		return [
			SELECT Id, Numero_Unico_de_Contrato__c
			FROM Contrato__c
			WHERE Cliente__c = :accId
		];
	}
	
	@AuraEnabled
	public static Map<Id, List<Titular__c>> getHoldersAndRecipients(List<Id> contractIds) {
		List<Titular__c> holders = [
			SELECT Id, Contrato__c, Cliente__r.Name, (
					SELECT Id, Nombre__c, Apellido__c
					FROM Beneficiarios__r
				)
			FROM Titular__c
			WHERE Contrato__c IN :contractIds
		];
		
		Map<Id, List<Titular__c>> result = new Map<Id, List<Titular__c>>();
		for(Titular__c h : holders) {
			if(!result.containsKey(h.Contrato__c)) {
				result.put(h.Contrato__c, new List<Titular__c>());
			}
			result.get(h.Contrato__c).add(h);
		}
		return result;
	}
}
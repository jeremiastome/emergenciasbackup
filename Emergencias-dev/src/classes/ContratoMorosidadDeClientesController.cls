public class ContratoMorosidadDeClientesController {
	@AuraEnabled
	public static List<Contrato__c> getContractsWithSamePaymentMethod(Id contractId) {
		Contrato__c con = [
			SELECT Id, Forma_de_Pago__c, CBU__c, Tarjeta_sin_cifrar__c
			FROM Contrato__c
			WHERE Id = :contractId
		];
		
		List<Contrato__c> otherContracts;
		
		if(con.Forma_de_Pago__c == 'S' && con.CBU__c != NULL) {
			return [
				SELECT Id, Name, Cliente__c, Cliente__r.Name, Cliente__r.Morosidad_SAP__c
				FROM Contrato__c
				WHERE CBU__c = :con.CBU__c
					AND Id != :con.Id
			];
		}
		else if(con.Forma_de_Pago__c == 'A' && con.Tarjeta_sin_cifrar__c != NULL) {
			return [
				SELECT Id, Name, Cliente__c, Cliente__r.Name, Cliente__r.Morosidad_SAP__c
				FROM Contrato__c
				WHERE Tarjeta_sin_cifrar__c = :con.Tarjeta_sin_cifrar__c
					AND Id != :con.Id
			];
		}
		else {
			return new List<Contrato__c>();
		}
	}
}
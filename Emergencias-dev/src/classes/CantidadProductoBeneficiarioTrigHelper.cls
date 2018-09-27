public class CantidadProductoBeneficiarioTrigHelper {
	public static void updateCoverageRecipientRelations(
		List<Cantidad_de_producto_de_beneficiaro__c> amountDetails
	) {
		Set<Id> relIds = new Set<Id>();
		for(Cantidad_de_producto_de_beneficiaro__c c : amountDetails) {
			relIds.add(c.Cobertura_de_Beneficiario__c);
		}
		
		Map<Id, Cobertura_de_Beneficiario__c> relations = new Map<Id, Cobertura_de_Beneficiario__c>([
			SELECT Id, Cantidad_domicilio__c, Cantidad_domicilio_en_transito__c
			FROM Cobertura_de_Beneficiario__c
			WHERE Id IN :relIds
		]);
		
		for(Cantidad_de_producto_de_beneficiaro__c c : amountDetails) {
			Cobertura_de_Beneficiario__c rel = relations.get(c.Cobertura_de_Beneficiario__c);
			
			rel.Cantidad_domicilio__c = c.Cantidad__c;
			rel.Cantidad_domicilio_en_transito__c = c.Cantidad_en_transito__c;
		}
		update relations.values();
	}
	
	public static void deactivateOldAmountDetails(
		List<Cantidad_de_producto_de_beneficiaro__c> amountDetails
	) {
		Set<Id> relationIds = new Set<Id>();
		Set<Id> detailIds = new Set<Id>();
		for(Cantidad_de_producto_de_beneficiaro__c c : amountDetails) {
			relationIds.add(c.Cobertura_de_Beneficiario__c);
			detailIds.add(c.Id);
		}
		
		List<Cantidad_de_producto_de_beneficiaro__c> previousActiveDetails = [
			SELECT Id, Activo__c
			FROM Cantidad_de_producto_de_beneficiaro__c
			WHERE Activo__c = true
				AND Cobertura_de_Beneficiario__c IN :relationIds
				AND Id NOT IN :detailIds
		];
		
		for(Cantidad_de_producto_de_beneficiaro__c prev : previousActiveDetails) {
			prev.Activo__c = false;
		}
		
		update previousActiveDetails;
	}
}
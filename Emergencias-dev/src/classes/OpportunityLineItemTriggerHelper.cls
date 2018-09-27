public class OpportunityLineItemTriggerHelper {
	public static void upsertCoverageObjects(List<OpportunityLineItem> olis) {
		List<Cobertura__c> coveragesToInsert = createCoverages(olis);
		
		upsert coveragesToInsert Id_Producto_de_Oportunidad__c;
	}
	
	public static void deleteCoverage(Set<Id> olisIds) {
		delete [SELECT Id FROM Cobertura__c WHERE Id_Producto_de_Oportunidad__c IN :olisIds];
	}
	
	private static List<Cobertura__c> createCoverages(List<OpportunityLineItem> olis) {
		Set<Id> oppIds = new Set<Id>();
		for(OpportunityLineItem oli : olis) {
			oppIds.add(oli.OpportunityId);
		}
		Map<Id, Opportunity> oppsById = new Map<Id, Opportunity> ([
			SELECT Contrato__c
			FROM Opportunity
			WHERE Id IN :oppIds
		]);
		
		List<Cobertura__c> result = new List<Cobertura__c>();
		for(OpportunityLineItem oli : olis) {
			if(oppsById.get(oli.OpportunityId).Contrato__c != null) {
				Cobertura__c cob = new Cobertura__c();
				
				cob.Cantidad__c = oli.Quantity;
				cob.Codigo_de_producto__c = oli.ProductCode;
				cob.Descripcion_de_partida__c = oli.Description;
				//cob.Descuento__c = oli.Discount;
				cob.Fecha__c = oli.ServiceDate;
				cob.Precio_de_la_lista__c = oli.ListPrice;
				cob.Precio_de_venta__c = oli.UnitPrice;
				cob.Precio_total__c = oli.TotalPrice;
				cob.Producto__c = oli.Product2Id;
				cob.Subtotal__c = oli.Subtotal;
				cob.Id_Producto_de_Oportunidad__c = oli.Id;
				cob.Contrato__c = oppsById.get(oli.OpportunityId).Contrato__c;
				
				result.add(cob);
			}
		}
		return result;
	}
}
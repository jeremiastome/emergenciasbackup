public class Contrato_AsignarContactosController {
	@AuraEnabled
	public static List<AccountContactRelation> getContacts(Id accId) {
        
		 List<AccountContactRelation> accountContactRelations = [
			SELECT Id, Contact.Name, ContactId
			FROM AccountContactRelation
			WHERE AccountId = :accId
		];
            
        return accountContactRelations;
	}
    
    @AuraEnabled
	public static Contrato__c getContractFields(Id contractId) {
        Contrato__c contract = [SELECT Id, 
                                Cliente__c, 
                				Contacto_Cobranza__c, 
               					Contacto_Facturacion__c, 
                				Contacto_de_delivery__c
                				FROM Contrato__c
                				WHERE Id=:contractId
                                LIMIT 1];
        
        return contract;
        
	}
    
    @AuraEnabled
	public static String saveContacts(Contrato__c contract) {
		try {
			update contract;
		} catch (Exception ex) {
			if(ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') && ex.getMessage().contains('[Contacto_de_delivery__c]')) {
				return 'Debe completar el código postal en la dirección del contacto de delivery.';
			}
			return  ex.getMessage();
		} 
        return 'Se han guardado correctamente los cambios.';
	}
}
public class Caso_ModificarContratoController  {
	@AuraEnabled
	public static Contrato__c getClonedContract(Id caseId) {
		Case c = [
			SELECT Id, Contrato_clonado__c, Contrato__c,
				Caso_maestro__r.Contrato_clonado__c, Caso_maestro__r.Contrato__c,
				RecordType.DeveloperName
			FROM Case
			WHERE Id = :caseId
		];
		
		String contractToGet;
		if(Caso_generador__c.getValues(c.RecordType.DeveloperName) != null) {
			contractToGet = 'Contrato_clonado__c';
		}
		else if(Casos_Beneficiarios_Descuentos__c.getValues(c.RecordType.DeveloperName) != null) {
			contractToGet = 'Contrato__c';
		}
		else {
			return null;
		}
		
		Case masterCase;
		if(c.Caso_maestro__r != null && c.Caso_maestro__r.Contrato_clonado__c != null) {
			masterCase = c.Caso_maestro__r;
		}
		else {
			masterCase = c;
		}
		
		Id contractId = (Id)masterCase.get(contractToGet);
		if(contractId != null) {
			return [
				SELECT Id, Contrato_de_Padrones__c, Canal_de_Distribucion__c, (
						SELECT Id, Cliente__r.Name
						FROM Titulares__r
                    	ORDER BY Cliente__r.Name
					)
				FROM Contrato__c
				WHERE Id = :contractId
			];
		}
		else {
			return null;
		}
	}
	
	@AuraEnabled
	public static String getSettingsType(Id caseId) {
		Case c = [
			SELECT Id, RecordType.DeveloperName
			FROM Case
			WHERE Id = :caseId
		];
		
		if(Caso_generador__c.getValues(c.RecordType.DeveloperName) != null) {
			return 'Cloning';
		}
		else if(Casos_Beneficiarios_Descuentos__c.getValues(c.RecordType.DeveloperName) != null) {
			return 'Addition';
		}
		else {
			return 'None';
		}
	}
}
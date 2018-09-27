@isTest
private class Titular_CrearBeneficiarioControllerTest {
	private static testMethod void itShouldBePosibleToGetTheRecordTypesForRecipient() {
		Map<Id, RecordType> recipientTypes = new Map<Id, RecordType>([
			SELECT Id, Name
			FROM RecordType
			WHERE SobjectType = 'Beneficiario__c'
				AND IsActive = true
				AND DeveloperName != 'Padron'
		]);
		
		List<String> result = Titular_CrearBeneficiarioController.getRecipientTypes();
		
		System.assertEquals(recipientTypes.size(), result.size());
		for(String typeString : result) {
			List<String> typeParts = typeString.split(Titular_CrearBeneficiarioController.SEPARATOR);
			System.assertEquals(recipientTypes.get(typeParts[0]).Name, typeParts[1]);
		}
	}
}
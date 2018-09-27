public class Titular_CrearBeneficiarioController {
	public static String SEPARATOR = ';';
	
	@AuraEnabled
	public static List<String> getRecipientTypes() {
		List<String> result = new List<String>();
		for(RecordType rt : [
			SELECT Id, Name
			FROM RecordType
			WHERE SobjectType = 'Beneficiario__c'
				AND IsActive = true
				AND DeveloperName != 'Padron'
		]) {
			result.add(rt.Id + SEPARATOR + rt.Name);
		}
		
		return result;
	}
}
public class Caso_CrearCasoHijoController {
	
	Public static String SEPARATOR = ';';

	@AuraEnabled
	public static List<String> getRecordTypes(){

		List<String> result = new List<String>();

		for(RecordType rt :[
			SELECT Id, Name
			FROM RecordType 
			WHERE SobjectType = 'Case' 
			AND IsActive = true
		]) {
			result.add(rt.id + SEPARATOR + rt.Name);
		}
		return result;
		
	}

}
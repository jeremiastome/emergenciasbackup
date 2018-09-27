@IsTest
private class Caso_CrearCasoHijoControllerTest {
	
	private static testmethod void itShouldBePossibleToGetRecordTypesForCases(){
		Map<Id, RecordType> recordTypes = new Map<Id, RecordType>([
			SELECT Id, Name
			FROM RecordType
			WHERE SobjectType = 'Case'
			AND IsActive = true				
		]);
		
		List<String> result = Caso_CrearCasoHijoController.getRecordTypes();
		
		System.assertEquals(recordTypes.size(), result.size());
		for(String typeString : result) {
			List<String> typeParts = typeString.split(Caso_CrearCasoHijoController.SEPARATOR);
			System.assertEquals(recordTypes.get(typeParts[0]).Name, typeParts[1]);
		}
	}

}
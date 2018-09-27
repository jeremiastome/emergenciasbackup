@isTest
public class WSEmergenciasRequestStringTest {
	private static testMethod void itShoudConvertAListStringToString() {
		String[] keys = new String[] {'V 10102', 'V 10103'};
		String keysToString = WSEmergenciasRequestString.keysToString(keys);

		System.assertEquals('["V 10102","V 10103"]', keysToString);
	}

	private static testMethod void givenAListOfKeysAndTwoDates_TheyShouldBeAbleToBeParsedToJSONFormat() {
		String[] keys = new String[] {'V 10102', 'V 10103'};
		DateTime dateFrom = DateTime.newInstance(2017, 2, 1, 0, 0, 0);
		DateTime dateTo = DateTime.newInstance(2017, 2, 2, 3, 5, 12);
		String dateToStr = '/Date('+dateTo.getTime()+'-0300)/';
		String dateFromStr = '/Date('+dateFrom.getTime()+'-0300)/';

		String jSONExpected = '{"ListaClaveSistema":["V 10102","V 10103"],'+
								+'"InstanteDesde":"'+dateFromStr+'",'+
								+'"InstanteHasta":"'+dateToStr+'"'+								
								+'}';

		String request = WSEmergenciasRequestString.wsEmergenciasRequestToJSON(keys, dateFromStr, dateToStr);

		System.assertEquals(jSONExpected, request);
	}
}
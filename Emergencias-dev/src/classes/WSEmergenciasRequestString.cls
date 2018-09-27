public class WSEmergenciasRequestString {
  public static string wsEmergenciasRequestToJSON(String[] keys, String dateFrom, String dateTo) {
	return '{"ListaClaveSistema":'+ keysToString(keys) +','+
		+'"InstanteDesde":"'+dateFrom+'",'+
		+'"InstanteHasta":"'+dateTo+'"'+
		+'}';
  }

  public static String keysToString(String[] keys) {
	String keysString = '[';
	for(Integer i = 0; i < keys.size(); i++) {
		if(i < keys.size() - 1) {
			keysString = keysString +'"'+keys[i]+'",';
		}
		else {
			keysString = keysString +'"'+keys[i]+'"]';
		}
	}
	return keysString;
  }
}
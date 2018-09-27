public class Cuenta_ValidarZonasController {
	public static String SEPARATOR = '|';
	
	@AuraEnabled
	public static String getZoneForAccount(Id accountId) {
		integer result = WSGetContractZone.getAccountZoneData(accountId);
		
		if(result == WSGetContractZone.RESULT_OK) {
			return 'success' + SEPARATOR + Label.Zona_de_cuenta_actualizada;
		}
		else if(result == WSGetContractZone.RESULT_OK_NO_DATA) {
			return 'success' + SEPARATOR + Label.CVZ_No_esta_en_zona;
		}
		else {
			String res = 'error' + SEPARATOR;
			
			if(result == WSGetContractZone.RESULT_NO_ZONE_ERROR) {
				res += Label.Error_no_se_recibio_zona;
			}
			else {//WSGetContractZone.RESULT_POSITION_ERROR
				res += Label.Error_no_se_obtuvo_posicion;
			}
			
			return res;
		}
	}
}
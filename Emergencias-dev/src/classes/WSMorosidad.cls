global class WSMorosidad {
	webService static Response updateMorosidad(List<DataMorosidad> morosidad) {
		Response res = new Response();
		system.debug(morosidad);
		Set<String> accountNumbers = new Set<String>();
		Map<String, String> defaultByContractNumber = new Map<String, String>();
   		Map<String, String> blockByContractNumber = new Map<String, String>();
        
		for(DataMorosidad mor : morosidad) {
			String defVal;
			if(String.isBlank(mor.Dias_vencimiento)) {
				defVal = '90';
			}
			else {
				defVal = mor.Dias_vencimiento;
			}
            system.debug(mor.Contrato);
            system.debug(defVal);
			defaultByContractNumber.put(mor.Contrato, defVal);
            blockByContractNumber.put(mor.Contrato, mor.Bloqueo_contrato);
			accountNumbers.add(mor.Cliente);
		}
		
		try {
            system.debug(defaultByContractNumber);
			BatchMorosidadUpdate updater = new BatchMorosidadUpdate(defaultByContractNumber, accountNumbers, blockByContractNumber);
            
			Database.executeBatch(updater);
            
            
			res.Status = 'OK';
			res.ErrorCode = 0;
		}
		catch(Exception e) {
			res.Status = e.getMessage();
			res.ErrorCode = e.getLineNumber();
		}
		return res;
	}
	
	global class Response {
		webService String Status {get; set;}
		webService Integer ErrorCode {get;set;}
	}
	
	global class DataMorosidad {
		webService String Cliente {get; set;}
		webService String Contrato {get; set;}
		webService String Dias_vencimiento {get; set;}
		webService String Bloqueo_contrato {get; set;}
		webService String Bloqueo_cliente {get; set;}
	}
}
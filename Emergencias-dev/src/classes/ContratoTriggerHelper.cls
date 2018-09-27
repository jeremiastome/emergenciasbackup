public class ContratoTriggerHelper {
	public static integer testPasses = 0;
	
	public static List<Contrato__c> checkCardNumbers(List<Contrato__c> contracts) {
		List<Contrato__c> validContracts = new List<Contrato__c>();
		
		for(Contrato__c con : contracts) {
			if(Validate.cardNumberWithType(con.Numero_de_Tarjeta__c,con.Tipo_de_Tarjeta__c)) {
				validContracts.add(con);
			}
			else {
				con.Numero_de_Tarjeta__c.addError(Label.Tarjeta_invalida);
			}
		}
		
		return validContracts;
	}


	public static void moveCardNumbers(List<Contrato__c> contracts) {
		for(Contrato__c con : contracts) {
			con.Tarjeta_sin_cifrar__c = con.Numero_de_Tarjeta__c;
			con.Numero_de_Tarjeta__c = '************' + con.Numero_de_Tarjeta__c.right(4);
			
			//con.CBU_sin_cifrar__c = con.CBU__c;
			//con.CBU__c = con.CBU__c.left(6) + '**********' + con.CBU__c.right(4);		
		}
	}
    public static void moveCBUNumbers(List<Contrato__c> contracts){
        for(Contrato__c con :contracts){
            con.CBU__c = con.cbu_cifrado__C;
            con.cbu_cifrado__c = con.CBU_cifrado__c.left(6) + '**********' + con.Cbu_cifrado__c.right(4);
        }
    }
	public static void sendContractToSAP(Id contractId, String operation) {
        ContractSenderQueable csq = new ContractSenderQueable(contractId, operation);
        System.enqueueJob(csq);
	}
	
	public static void getContractZoneData(Id contractId) {
		WSGetContractZone wscz = new WSGetContractZone(contractId);
        System.enqueueJob(wscz);
	}
	
	public static void checkContractNumbers(List<Contrato__c> contracts) {
		Map<String, Numeros_de_contratos__c> numberSettings = new Map<String, Numeros_de_contratos__c>();
		for(Numeros_de_contratos__c numSettings : [
			SELECT Name, Numero_maximo__c
			FROM Numeros_de_contratos__c
		]) {
			numberSettings.put(numSettings.Name, numSettings);
		}
		
		boolean settingsChanged = false;
		for(Contrato__c con : contracts) {
			if(con.Numero_Unico_de_Contrato__c != null) {
				con.Numero_unico_de_contrato_letra__c = con.Numero_Unico_de_Contrato__c.left(1).toUpperCase();
				if(con.Numero_Unico_de_Contrato_Con_Sufijo__c == null && con.Sufijo__c != null) {
					con.Numero_Unico_de_Contrato_Con_Sufijo__c =
						con.Numero_Unico_de_Contrato__c
						+ String.valueOf(con.Sufijo__c).leftPad(2, '0');
				}


				/// Esta linea se borraron puesto a que esto es un checkeo viejo
				// La numeracion de hoy ya no se inserta si no que esta puesta 
				// en la configuracion personalizada.

				//Numeros_de_contratos__c numSettings = numberSettings.get(con.Numero_unico_de_contrato_letra__c);
				/*
				if(con.Sufijo__c == 0 || con.Sufijo__c == null) {
					if(numSettings == null) {
						numSettings = new Numeros_de_contratos__c(
							Name = con.Numero_unico_de_contrato_letra__c,
							Numero_maximo__c = decimal.valueOf(con.Numero_Unico_de_Contrato__c.right(6))
						);
						numberSettings.put(numSettings.Name, numSettings);
						settingsChanged = true;
					}
					else {
						decimal conNum = decimal.valueOf(con.Numero_Unico_de_Contrato__c.right(6));
						if(numSettings.Numero_maximo__c < conNum) {
							numSettings.Numero_maximo__c = conNum;
							settingsChanged = true;
						}
					}
				}*/
			}
		}
		
		/*if(settingsChanged) {
			upsert numberSettings.values();
		}*/
	}
	
    /*
    @NOT_A_FUTURE_future(callout=true)
	public static void sendContractToSAPFuture(Id contractId, String operation) {
		ContratosPedidos_EnviarSAP.sendContract(contractId, operation);
	}
	*/
}
public class TitularTriggerHelper {
	public static void prepareUniqueNumber(List<Titular__c> holders) {
		Map<Id, Contrato__c> contractById = getContracts(holders);
		Map<String, String> holderLetterByContractLetter = getHolderLetterByContractLetter();
		Map<String, Numeros_de_Titulares__c> holderNumberSettings = new Map<String, Numeros_de_Titulares__c>();
		for(Numeros_de_Titulares__c numSettings : [
			SELECT Name, Numero_maximo__c
			FROM Numeros_de_Titulares__c
		]) {
			holderNumberSettings.put(numSettings.Name, numSettings);
		}
		
		Boolean settingsChanged = false;
		for(Titular__c h : holders) {
			Contrato__c contract = contractById.get(h.Contrato__c);
			String hLetter = holderLetterByContractLetter.get(
				contract.Numero_unico_de_contrato_letra__c
			);
			
			if(contract.Canal_de_Distribucion__c == 'Pymes y Comercios'
				|| contract.Canal_de_Distribucion__c == 'Consumidor Final'
				|| String.isBlank(hLetter)
			) {
				h.Numero_de_titular__c = contract.Numero_unico_de_contrato__c;
				h.Numero_de_titular_Letra__c = contract.Numero_unico_de_contrato_letra__c;
			}
			else {
				settingsChanged = true;
				Numeros_de_Titulares__c hnSetting = holderNumberSettings.get(hLetter);
				if(hnSetting == null) {
					hnSetting = new Numeros_de_Titulares__c(
						Name = hLetter,
						Numero_maximo__c = 0
					);
					holderNumberSettings.put(hLetter, hnSetting);
				}
				hnSetting.Numero_maximo__c++;
				h.Numero_de_titular__c = hLetter
					+ String.valueOf(hnSetting.Numero_maximo__c).leftPad(6, '0');
				h.Numero_de_titular_Letra__c = hLetter;
			}
		}
		
		if(settingsChanged) {
			upsert holderNumberSettings.values();
		}
	}
	
	private static Map<String, String> getHolderLetterByContractLetter() {
		List<Letra_de_Contrato_a_Titular__mdt> contractToHolderLetterSettings = [
			SELECT DeveloperName, Letra_de_titular__c
			FROM Letra_de_Contrato_a_Titular__mdt
		];
		Map<String, String> result = new Map<String, String>();
		for(Letra_de_Contrato_a_Titular__mdt letterSettings : contractToHolderLetterSettings) {
			for(String contractLetter : letterSettings.DeveloperName.split('')) {
				result.put(contractLetter, letterSettings.Letra_de_titular__c);
			}
		}
		
		return result;
	}
	
	private static Map<Id, Contrato__c> getContracts(List<Titular__c> holders) {
		Set<Id> contractIds = new Set<Id>();
		for(Titular__c h : holders) {
			contractIds.add(h.Contrato__c);
		}
		
		return new Map<Id, Contrato__c>([
			SELECT Id, Numero_unico_de_contrato_letra__c, Numero_unico_de_contrato__c,
				TOLABEL(Canal_de_Distribucion__c)
			FROM Contrato__c
			WHERE Id IN :contractIds
		]);
	}
}
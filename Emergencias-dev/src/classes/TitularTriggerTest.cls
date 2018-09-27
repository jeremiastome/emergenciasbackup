@isTest
private class TitularTriggerTest {
	private static testMethod void whenCreatingAHolderForCertainContractsItShouldHaveANumberDependingOnTheContractLetter() {
		//Prepare contract to holder letter conversion
		List<Letra_de_Contrato_a_Titular__mdt> contractToHolderLetterSettings = [
			SELECT DeveloperName, Letra_de_titular__c
			FROM Letra_de_Contrato_a_Titular__mdt
		];
		Map<String, String> holderLetterByContractLetter = new Map<String, String>();
		Map<String, Integer> amountOfContractForHolderLetter = new Map<String, Integer>();
		for(Letra_de_Contrato_a_Titular__mdt letterSettings : contractToHolderLetterSettings) {
			for(String contractLetter : letterSettings.DeveloperName.split('')) {
				holderLetterByContractLetter.put(contractLetter, letterSettings.Letra_de_titular__c);
				
				if(amountOfContractForHolderLetter.containsKey(letterSettings.Letra_de_titular__c)) {
					amountOfContractForHolderLetter.put(
						letterSettings.Letra_de_titular__c,
						amountOfContractForHolderLetter.get(letterSettings.Letra_de_titular__c) + 1
					);
				}
				else {
					amountOfContractForHolderLetter.put(letterSettings.Letra_de_titular__c, 1);
				}
			}
		}
		
		//Prepare contracts and holder number settings
		List<Contrato__c> contracts = new List<Contrato__c>();
		Map<String, Numeros_de_Titulares__c> holderNumberSettings = new Map<String, Numeros_de_Titulares__c>();
		for(String contractLetter : holderLetterByContractLetter.keySet()) {
			contracts.add(
				Build.aContract().forAccount(anAccount).withUniqueNumber(contractLetter + '000001').build()
			);
			String holderLetter = holderLetterByContractLetter.get(contractLetter);
			holderNumberSettings.put(
				holderLetter,
				Build.aHolderNumberSetting().withMaxNumber(0).withLetter(holderLetter).build()
			);
		}
		insert holderNumberSettings.values();
		insert contracts;
		
		//=======================================================
		// Execution
		List<Titular__c> holders = new List<Titular__c>();
		for(Contrato__c aContract : contracts) {
			holders.add(Build.aHolder().forContract(aContract).forAccount(anAccount).build());
		}
		insert holders;
		
		//=======================================================
		// Assertion
		//Check holder number settings numbers
		holderNumberSettings = Numeros_de_Titulares__c.getAll();
		for(Numeros_de_Titulares__c holderNumberSetting : holderNumberSettings.values()) {
			System.assertEquals(
				amountOfContractForHolderLetter.get(holderNumberSetting.Name),
				holderNumberSetting.Numero_maximo__c
				);
			}
		
		//Check holder numbers
		List<Titular__c> holdersInDb = [
			SELECT Id, Numero_de_titular__c, Numero_de_titular_Letra__c, Numero_de_titular_Numero__c,
				Contrato__r.Numero_unico_de_contrato_letra__c
			FROM Titular__c
			WHERE Id IN :holders
		];
		for(Titular__c aHolder : holdersInDb) {
			System.assert(
				aHolder.Numero_de_titular__c.startsWith(
					holderLetterByContractLetter.get(aHolder.Contrato__r.Numero_unico_de_contrato_letra__c)
						+ '0000'
				),
				'Holder number (' + aHolder.Numero_de_titular__c + ') does not conform to expected number format ('
					+ holderLetterByContractLetter.get(aHolder.Contrato__r.Numero_unico_de_contrato_letra__c)
						+ '0000)'
			);
			System.assertEquals(
				holderLetterByContractLetter.get(aHolder.Contrato__r.Numero_unico_de_contrato_letra__c),
				aHolder.Numero_de_titular_Letra__c
			);
			System.assert(
				aHolder.Numero_de_titular_Numero__c <= holderNumberSettings
					.get(aHolder.Numero_de_titular_Letra__c).Numero_maximo__c
			);
		}
		
	}
	
	private static testMethod void whenAHolderIsInsertedForOtherContractsItsNumberShouldBeTheSameAsTheContract() {
		integer i = 0;
		List<Schema.PicklistEntry> distributionChannels = Contrato__c.Canal_de_Distribucion__c
			.getDescribe().getPicklistValues();
		while(distributionChannels[i].getLabel() != 'Pymes y Comercios'
			&& distributionChannels[i].getLabel() != 'Consumidor Final'
		) {
			i++;
		}
		aContract.Canal_de_Distribucion__c = distributionChannels[i].getValue();
		update aContract;
		
		Titular__c aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		
		Titular__c theHolderInDb = [
			SELECT Id, Numero_de_titular__c, Numero_de_titular_Letra__c, Numero_de_titular_Numero__c,
				Contrato__r.Numero_unico_de_contrato__c
			FROM Titular__c
			WHERE Id = :aHolder.Id
		];
		
		System.assertEquals(
			theHolderInDb.Contrato__r.Numero_unico_de_contrato__c,
			theHolderInDb.Numero_de_titular__c
		);
	}
	
	//==========================================================================
	static Account anAccount;
	static Contrato__c aContract;
	
	static {
		anAccount = Build.anAccount().build();
		insert anAccount;
		
		aContract = Build.aContract().forAccount(anAccount).withUniqueNumber('A000001').build();
		insert aContract;
	}
}
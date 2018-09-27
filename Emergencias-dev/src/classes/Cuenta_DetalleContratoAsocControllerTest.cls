@isTest
private class Cuenta_DetalleContratoAsocControllerTest {
	private static testMethod void itShouldBePosibleToGetAnAccountsContracts() {
		Set<Id> contractIds = new Set<Id>();
		for(Contrato__c contract : contracts) {
			contractIds.add(contract.Id);
		}
		
		List<Contrato__c> result = Cuenta_DetalleContratoAsociadoController.getContracts(anAccount.Id);
		
		System.assertEquals(contracts.size(), result.size());
		for(Contrato__c contract : result) {
			System.assert(contractIds.contains(contract.Id));
		}
	}
	
	private static testMethod void itShouldBePosibleToGetTheHoldersAndRecipientsForASeriesOfContracts() {
		List<Id> contractIds = new List<Id>();
		for(Contrato__c contract : contracts) {
			contractIds.add(contract.Id);
		}
		
		Map<Id, List<Titular__c>> result = Cuenta_DetalleContratoAsociadoController.getHoldersAndRecipients(contractIds);
		
		
		for(Id contractId : contractIds) {
			System.assert(result.containsKey(contractId));
			System.assertEquals(1, result.get(contractId).size());
			System.assertEquals(
				recipientsByHolder.get(result.get(contractId)[0].Id).size(),
				result.get(contractId)[0].Beneficiarios__r.size()
			);
		}
	}
	
	//==========================================================================
	static Account anAccount;
	static List<Contrato__c> contracts;
	static Map<Id, Titular__c> holdersByContract;
	static Map<Id, List<Beneficiario__c>> recipientsByHolder;
	
	static {
		anAccount = Build.anAccount().build();
		insert anAccount;
		//==============================
		contracts = new List<Contrato__c> {
			Build.aContract().forAccount(anAccount).withUniqueNumber().build(),
			Build.aContract().forAccount(anAccount).withUniqueNumber().build()
		};
		insert contracts;
		Set<Id> contractIds = new Set<Id>();
		for(Contrato__c contract : contracts) {
			contractIds.add(contract.Id);
		}
		//==============================
		List<Titular__c> holders = [
			SELECT Id, Contrato__c, Ult_Numero_de_beneficiario__c
			FROM Titular__c
			WHERE Contrato__c IN :contractIds
		];
		if(holders.size() != 0) {
			delete holders;
		}
		holders = new List<Titular__c>();
		for(Contrato__c contract : contracts) {
			holders.add(Build.aHolder().forContract(contract).forAccount(anAccount).build());
		}
		insert holders;
		holdersByContract = new Map<Id, Titular__c>();
		for(Titular__c holder : holders) {
			holdersByContract.put(holder.Contrato__c, holder);
		}
		//==============================
		recipientsByHolder = new Map<Id, List<Beneficiario__c>>();
		List<Beneficiario__c> allRecipients = new List<Beneficiario__c>();
		for(Titular__c holder : holders) {
			List<Beneficiario__c> recipients = new List<Beneficiario__c>();
			for(Integer i = 0; i < 2; i++) {
				Beneficiario__c recipient = Build.aRecipient().withContractId(holder.Contrato__c).forHolder(holder).build();
				recipients.add(recipient);
				allRecipients.add(recipient);
			}
			recipientsByHolder.put(holder.Id, recipients);
		}
		insert allRecipients;
	}
}
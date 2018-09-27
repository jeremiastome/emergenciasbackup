@isTest
private class ContratoMorosidadDeClientesContTest {
	private static testMethod void itShouldBePosibleToGetTheContractsWithTheSameCBUWhenThePaymentMethodIsDebit() {
		List<Contrato__c> otherContractsWithTheCBU = new List<Contrato__c> {
			Build.aContract().forAccount(anAccount).withCBU(aContractWithDebit.CBU__c).withDebitPaymentMethod().build(),
			Build.aContract().forAccount(anAccount).withCBU(aContractWithDebit.CBU__c).withDebitPaymentMethod().build(),
			Build.aContract().forAccount(anotherAccount).withCBU(aContractWithDebit.CBU__c).withDebitPaymentMethod().build(),
			Build.aContract().forAccount(anotherAccount).withCBU(aContractWithDebit.CBU__c).withDebitPaymentMethod().build(),
			Build.aContract().forAccount(anAccount).withCBU(aContractWithDebit.CBU__c).withDebitPaymentMethod().build()
		};
		insert otherContractsWithTheCBU;
		
		Set<Id> contractsWithSameCBUIds = new Set<Id>();
		for(Contrato__c contract : otherContractsWithTheCBU) {
			contractsWithSameCBUIds.add(contract.Id);
		}
		
		List<Contrato__c> differentCBUContracts = new List<Contrato__c> {
			Build.aContract().forAccount(anotherAccount).withAnotherValidCBU().withDebitPaymentMethod().build(),
			Build.aContract().forAccount(anotherAccount).withAnotherValidCBU().withDebitPaymentMethod().build(),
			Build.aContract().forAccount(anAccount).withAnotherValidCBU().withDebitPaymentMethod().build(),
			Build.aContract().forAccount(anotherAccount).withAnotherValidCBU().withDebitPaymentMethod().build(),
			Build.aContract().forAccount(anAccount).withAnotherValidCBU().withDebitPaymentMethod().build()
		};
		insert differentCBUContracts;
		
		List<Contrato__c> result = ContratoMorosidadDeClientesController.getContractsWithSamePaymentMethod(aContractWithDebit.Id);
		
		System.assertEquals(otherContractsWithTheCBU.size(), result.size());
		for(Contrato__c contract : result) {
			System.assert(contractsWithSameCBUIds.contains(contract.Id));
		}
	}
	
	private static testMethod void itShouldBePosibleToGetTheContractsWithTheSameCardNumberWhenThePaymentMethodIsCredit() {
		List<Contrato__c> otherContractsWithTheCard = new List<Contrato__c> {
			Build.aContract().forAccount(anAccount).withCardNumber(aContractWithCredit.Numero_de_tarjeta__c)
				.withCardName().withCreditPaymentMethod().build(),
			Build.aContract().forAccount(anAccount).withCardNumber(aContractWithCredit.Numero_de_tarjeta__c)
				.withCardName().withCreditPaymentMethod().build(),
			Build.aContract().forAccount(anotherAccount).withCardNumber(aContractWithCredit.Numero_de_tarjeta__c)
				.withCardName().withCreditPaymentMethod().build(),
			Build.aContract().forAccount(anotherAccount).withCardNumber(aContractWithCredit.Numero_de_tarjeta__c)
				.withCardName().withCreditPaymentMethod().build(),
			Build.aContract().forAccount(anAccount).withCardNumber(aContractWithCredit.Numero_de_tarjeta__c)
				.withCardName().withCreditPaymentMethod().build()
		};
		insert otherContractsWithTheCard;
		
		Set<Id> contractsWithSameCardIds = new Set<Id>();
		for(Contrato__c contract : otherContractsWithTheCard) {
			contractsWithSameCardIds.add(contract.Id);
		}
		
		List<Contrato__c> differentCardContracts = new List<Contrato__c> {
			Build.aContract().forAccount(anotherAccount).withAnotherValidCardNumber()
				.withCardName().withCreditPaymentMethod().build(),
			Build.aContract().forAccount(anotherAccount).withAnotherValidCardNumber()
				.withCardName().withCreditPaymentMethod().build(),
			Build.aContract().forAccount(anAccount).withValidCBU().withDebitPaymentMethod().build(),
			Build.aContract().forAccount(anotherAccount).withValidCBU().withDebitPaymentMethod().build(),
			Build.aContract().forAccount(anAccount).withValidCBU().withDebitPaymentMethod().build()
		};
		insert differentCardContracts;
		
		List<Contrato__c> result = ContratoMorosidadDeClientesController.getContractsWithSamePaymentMethod(aContractWithCredit.Id);
		
		System.assertEquals(otherContractsWithTheCard.size(), result.size());
		for(Contrato__c contract : result) {
			System.assert(contractsWithSameCardIds.contains(contract.Id));
		}
	}
	
	private static testMethod void ifThePaymentMethodIsNotCreditNorDebit_TheResultShouldBeEmpty() {
		Contrato__c anotherContract = Build.aContract().withCardNumber(aContractWithCredit.Numero_de_tarjeta__c)
			.withCBU(aContractWithDebit.CBU__c).forAccount(anAccount).build();
		insert anotherContract;
		
		List<Contrato__c> result = ContratoMorosidadDeClientesController.getContractsWithSamePaymentMethod(anotherContract.Id);
		
		System.assertEquals(0, result.size());
	}
	
	//==========================================================================
	static Account anAccount;
	static Account anotherAccount;
	static Contrato__c aContractWithCredit;
	static Contrato__c aContractWithDebit;
	
	static {
		anAccount = Build.anAccount().build();
		anotherAccount = Build.anAccount().build();
		insert new List<Account> {anAccount, anotherAccount};
		
		aContractWithCredit = Build.aContract().forAccount(anAccount).withValidCardNumber().withCreditPaymentMethod().build();
		aContractWithDebit = Build.aContract().forAccount(anAccount).withValidCBU().withDebitPaymentMethod().build();
		insert new List<Contrato__c> {aContractWithCredit, aContractWithDebit};
	}
}
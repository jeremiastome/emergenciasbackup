@isTest
private class Contrato_AsignarContactosControllerTest {
	private static testMethod void itShouldBePosibleToGetTheContractsForAContractsAccount() {
		List<AccountContactRelation> result = Contrato_AsignarContactosController.getContacts(anAccount.Id);
		
		System.assertEquals(1, result.size());
		System.assertEquals(aContact.Id, result[0].ContactId);
	}
	
	private static testMethod void itShouldBePosibleToGetAssociatedContactsForAPersonAccount() {
		AccountContactRelation anAccountContactRelation = Build.anAccountContactRelation()
			.forAccount(aPersonAccount).forContact(anotherContact).build();
		insert anAccountContactRelation;
		
		List<AccountContactRelation> result = Contrato_AsignarContactosController.getContacts(aPersonAccount.Id);
		System.assertEquals(1, result.size());
		System.assertEquals(anotherContact.Id, result[0].ContactId);
	}
    
   	private static testMethod void itShouldBePosibleToGetTheContractsFields() {
		Contrato__c contract = Contrato_AsignarContactosController.getContractFields(aContract.Id);
		System.assertNotEquals(null, contract);
	}
    
    private static testMethod void itShouldBePosibleToSaveContractContacs() {
        System.assertNotEquals(aContract.Contacto_Facturacion__c, aContact.id);
		aContract.Contacto_Facturacion__c= aContact.id;
        Contrato_AsignarContactosController.saveContacts(aContract);
        System.assertEquals(aContract.Contacto_Facturacion__c, aContact.id);
	}
    
    private static testMethod void ifADeliveryValidationIsThrowInSaveThenTheMethodResponseAMessage() {
		aContract.Contacto_de_delivery__c= aContact.id;
        System.assertEquals(Contrato_AsignarContactosController.saveContacts(aContract),
                            'Debe completar el código postal en la dirección del contacto de delivery.');
	}
	
	//==========================================================================
	static Account anAccount;
	static Account anotherAccount;
	static Account aPersonAccount;
	static Contact aContact;
	static Contact anotherContact;
	static Contrato__c aContract;
	
	static {
		anAccount = Build.anAccount().build();
		anotherAccount = Build.anAccount().build();
		aPersonAccount = Build.anAccount().isPersonAccount().build();
		insert new List<Account> {anAccount, anotherAccount, aPersonAccount};
		
		aContact = Build.aContact().forAccount(anAccount).withSkipSend(200).build();
		anotherContact = Build.aContact().forAccount(anotherAccount).withSkipSend(200).build();
		insert new List<Contact> {aContact, anotherContact};
		
		aContract = Build.aContract().forAccount(anAccount).build();
		insert aContract;
	}
}
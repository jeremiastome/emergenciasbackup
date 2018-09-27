@isTest
private class Caso_IrBajaParcialControllerTest {
	private static testMethod void itShouldBePosibleToObtainTheContractAssociatedToACase() {
		Id result = Caso_IrBajaParcialController.getContract(aCase.Id);
		
		System.assertEquals(aContract.Id, result);
	}
	
	//==========================================================================
	static Account anAccount;
	static Contrato__c aContract;
	static Case aCase;
	
	static {
		anAccount = Build.anAccount().build();
		insert anAccount;
		aContract = Build.aContract().forAccount(anAccount).withUniqueNumber().build();
		insert aContract;
		aCase = Build.aCase().forAccount(anAccount).forContract(aContract).build();
		insert aCase;
	}
}
@isTest
private class CBUTriggerTest {
	private static testMethod void ifAnInvalidCBUIsInserted_AnErrorShouldBeAdded() {
		CBU__c aCBU = Build.aCBU().withName('1233rdsfds23').build();
		
		boolean failed = false;
		try {
			insert aCBU;
		}
		catch (Exception ex) {
			failed = true;
			System.assert(
				ex.getMessage().contains(Label.CBU_invalido),
				'The error message "' + ex.getMessage() + '" '
				+ 'did not contain "' + Label.CBU_invalido + '"'
			);
		}
		System.assert(failed, 'The insertion did not fail.');
	}
	
	private static testMethod void ifAnInvalidCBUIsUpdated_AnErrorShouldBeAdded() {
		CBU__c aCBU = Build.aCBU().build();
		insert aCBU;
		
		aCBU.Name = '1233rdsfds23';
		boolean failed = false;
		try {
			update aCBU;
		}
		catch (Exception ex) {
			failed = true;
			System.assert(
				ex.getMessage().contains(Label.CBU_invalido),
				'The error message "' + ex.getMessage() + '" '
				+ 'did not contain "' + Label.CBU_invalido + '"'
			);
		}
		System.assert(failed, 'The insertion did not fail.');
	}
}
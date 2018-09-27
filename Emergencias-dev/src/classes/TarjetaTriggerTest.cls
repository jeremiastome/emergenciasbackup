@isTest
private class TarjetaTriggerTest {
	private static testMethod void ifAnInvalidCardNumberIsInserted_AnErrorShouldBeAdded() {
		Tarjeta__c aCreditCard = Build.aCreditCard().withCardNumber('1233rdsfds23').build();
		
		boolean failed = false;
		try {
			insert aCreditCard;
		}
		catch (Exception ex) {
			failed = true;
			System.assert(
				ex.getMessage().contains(Label.Tarjeta_invalida),
				'The error message "' + ex.getMessage() + '" '
				+ 'did not contain "' + Label.Tarjeta_invalida + '"'
			);
		}
		System.assert(failed, 'The insertion did not fail.');
	}
	
	private static testMethod void ifAnInvalidCardNumberIsUpdated_AnErrorShouldBeAdded() {
		Tarjeta__c aCreditCard = Build.aCreditCard().build();
		insert aCreditCard;
		aCreditCard.Numero_de_tarjeta__c = '45678789on2313';
		
		boolean failed = false;
		try {
			update aCreditCard;
		}
		catch (Exception ex) {
			failed = true;
			System.assert(
				ex.getMessage().contains(Label.Tarjeta_invalida),
				'The error message "' + ex.getMessage() + '" '
				+ 'did not contain "' + Label.Tarjeta_invalida + '"'
			);
		}
		System.assert(failed, 'The insertion did not fail.');
	}
}
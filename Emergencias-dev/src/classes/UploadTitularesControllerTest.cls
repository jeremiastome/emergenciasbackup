@isTest
public class UploadTitularesControllerTest {

	@isTest
	private static void itShouldBePossibleToCreateHoldersAndAccountsFromDataInAText() {
		UploadTitularesController.uploadFile('', bodyLines, '', aContract.id, 'Business_Account', 0, '');

		List<Account> accountsSaved = [
			SELECT id,
			Name,
			Numero_de_Documento__c,
			RecordType.DeveloperName,
			Provincia_de_facturacion__c,
			Phone,
			CUIL_CUIT__c
			FROM Account
		];
		List<Titular__c> titulares = [
			SELECT id,
			Cliente__c,
			Contrato__c
			FROM Titular__c
		];

		System.assertEquals(3, accountsSaved.size());
		System.assertEquals(2, titulares.size());
		System.assertEquals('LastName test 1', accountsSaved[1].Name);
		System.assertEquals('11111111', accountsSaved[1].Numero_de_Documento__c);
		System.assertEquals('Business_Account', accountsSaved[1].RecordType.DeveloperName);
		System.assertEquals('Capital Federal', accountsSaved[1].Provincia_de_facturacion__c);
		System.assertEquals('12324', accountsSaved[1].Phone);
		System.assertEquals('20111111111', accountsSaved[1].CUIL_CUIT__c);
		System.assertEquals('LastName test 2', accountsSaved[2].Name);
		System.assertEquals('11111112', accountsSaved[2].Numero_de_Documento__c);
		System.assertEquals('Business_Account', accountsSaved[2].RecordType.DeveloperName);
		System.assertEquals('Capital Federal', accountsSaved[2].Provincia_de_facturacion__c);
		System.assertEquals('12325', accountsSaved[2].Phone);
		System.assertEquals('20111111112', accountsSaved[2].CUIL_CUIT__c);

		System.assertEquals(accountsSaved[1].id, titulares[0].Cliente__c);
		System.assertEquals(aContract.id, titulares[0].Contrato__c);
		System.assertEquals(accountsSaved[2].id, titulares[1].Cliente__c);
		System.assertEquals(aContract.id, titulares[1].Contrato__c);
	}

	@isTest
	private static void whenItIsTriedToCreateHoldersAndAccountsFromDataInATextWithSameValues_TheHoldersDoNotDuplicate () {
		UploadTitularesController.uploadFile('', bodyLines, '', aContract.id, 'PersonAccount', 0, '');
		UploadTitularesController.uploadFile('', bodyLines, '', aContract.id, 'PersonAccount', 0, '');

		List<Account> accountsSaved = [
			SELECT id,
			LastName,
			Numero_de_Documento__c,
			Provincia_de_facturacion__c,
			Phone,
			CUIL_CUIT__c
			FROM Account
		];
		List<Titular__c> titulares = [
			SELECT id,
			Cliente__c,
			Contrato__c
			FROM Titular__c
		];

		System.assertEquals(3, accountsSaved.size());
		System.assertEquals(2, titulares.size());
	}

	@isTest
	private static void whenItIsTriedToCreateHoldersAndAccountsFromDataInATextWithTheOtherValues_TheAccountsAreUpdated () {
		UploadTitularesController.uploadFile('', bodyLines, '', aContract.id, 'PersonAccount', 0, '');
		List<String> newValues = new List<String>();
		newValues.add('LastName test 1; 11111111 ; Catamarca; 12324; 20111111111');
		newValues.add('New name; 11111112 ; La Pampa; 123123; 20111111112');

		UploadTitularesController.uploadFile('', newValues, '', aContract.id, 'PersonAccount', 0, '');

		List<Account> accountsSaved = [
			SELECT id,
			LastName,
			Numero_de_Documento__c,
			Provincia_de_facturacion__c,
			RecordType.DeveloperName,
			Phone,
			CUIL_CUIT__c
			FROM Account
		];
		List<Titular__c> titulares = [
			SELECT id,
			Cliente__c,
			Contrato__c
			FROM Titular__c
		];

		System.assertEquals(3, accountsSaved.size());
		System.assertEquals(2, titulares.size());
		System.assertEquals(3, accountsSaved.size());
		System.assertEquals(2, titulares.size());
		System.assertEquals('LastName test 1', accountsSaved[1].LastName);
		System.assertEquals('11111111', accountsSaved[1].Numero_de_Documento__c);
		System.assertEquals('Catamarca', accountsSaved[1].Provincia_de_facturacion__c);
		System.assertEquals('PersonAccount', accountsSaved[1].RecordType.DeveloperName);
		System.assertEquals('12324', accountsSaved[1].Phone);
		System.assertEquals('20111111111', accountsSaved[1].CUIL_CUIT__c);
		System.assertEquals('New name', accountsSaved[2].LastName);
		System.assertEquals('11111112', accountsSaved[2].Numero_de_Documento__c);
		System.assertEquals('PersonAccount', accountsSaved[2].RecordType.DeveloperName);
		System.assertEquals('La Pampa', accountsSaved[2].Provincia_de_facturacion__c);
		System.assertEquals('123123', accountsSaved[2].Phone);
		System.assertEquals('20111111112', accountsSaved[2].CUIL_CUIT__c);

		System.assertEquals(accountsSaved[1].id, titulares[0].Cliente__c);
		System.assertEquals(aContract.id, titulares[0].Contrato__c);
		System.assertEquals(accountsSaved[2].id, titulares[1].Cliente__c);
		System.assertEquals(aContract.id, titulares[1].Contrato__c);
	}

	@isTest
	private static void whenItIsTriedToCreateHoldersAndAccountsFromDataInATextWithTheOtherValues_onlyTheHoldersForTheNewAccountsAreCreated () {
		UploadTitularesController.uploadFile('', bodyLines, '', aContract.id, 'PersonAccount', 0, '');
		List<String> newValues = new List<String>();
		newValues.add('LastName test 1; 11111111 ; Catamarca; 12324; 20111111111');
		newValues.add('New name; 11111112 ; La Pampa; 123123; 20111111113');

		UploadTitularesController.uploadFile('', newValues, '', aContract.id, 'PersonAccount', 0, '');

		List<Account> accountsSaved = [
			SELECT id,
			LastName,
			Numero_de_Documento__c,
			Provincia_de_facturacion__c,
			RecordType.DeveloperName,
			Phone,
			CUIL_CUIT__c
			FROM Account
		];
		List<Titular__c> titulares = [
			SELECT id,
			Cliente__c,
			Contrato__c
			FROM Titular__c
		];

		System.assertEquals(4, accountsSaved.size());
		System.assertEquals(3, titulares.size());
		System.assertEquals('LastName test 1', accountsSaved[1].LastName);
		System.assertEquals('11111111', accountsSaved[1].Numero_de_Documento__c);
		System.assertEquals('Catamarca', accountsSaved[1].Provincia_de_facturacion__c);
		System.assertEquals('PersonAccount', accountsSaved[1].RecordType.DeveloperName);
		System.assertEquals('12324', accountsSaved[1].Phone);
		System.assertEquals('20111111111', accountsSaved[1].CUIL_CUIT__c);
		System.assertEquals('LastName test 2', accountsSaved[2].LastName);
		System.assertEquals('PersonAccount', accountsSaved[2].RecordType.DeveloperName);
		System.assertEquals('11111112', accountsSaved[2].Numero_de_Documento__c);
		System.assertEquals('Capital Federal', accountsSaved[2].Provincia_de_facturacion__c);
		System.assertEquals('12325', accountsSaved[2].Phone);
		System.assertEquals('20111111112', accountsSaved[2].CUIL_CUIT__c);
		System.assertEquals('New name', accountsSaved[3].LastName);
		System.assertEquals('11111112', accountsSaved[3].Numero_de_Documento__c);
		System.assertEquals('PersonAccount', accountsSaved[3].RecordType.DeveloperName);
		System.assertEquals('La Pampa', accountsSaved[3].Provincia_de_facturacion__c);
		System.assertEquals('123123', accountsSaved[3].Phone);
		System.assertEquals('20111111113', accountsSaved[3].CUIL_CUIT__c);

		System.assertEquals(accountsSaved[1].id, titulares[0].Cliente__c);
		System.assertEquals(aContract.id, titulares[0].Contrato__c);
		System.assertEquals(accountsSaved[2].id, titulares[1].Cliente__c);
		System.assertEquals(aContract.id, titulares[1].Contrato__c);
		System.assertEquals(accountsSaved[3].id, titulares[2].Cliente__c);
		System.assertEquals(aContract.id, titulares[2].Contrato__c);
	}

	static Contrato__c aContract;
	static Account anAccount;
	static String[] bodyLines;

	static {
		anAccount = Build.anAccount().build();
		insert anAccount;
		aContract = Build.aContract().withUniqueNumber().withUniqueNumber('H').forAccount(anAccount).build();
		insert aContract;
		bodyLines = new List<String>();
		bodyLines.add('LastName test 1; 11111111 ; Capital Federal; 12324; 20111111111');
		bodyLines.add('LastName test 2; 11111112 ; Capital Federal; 12325; 20111111112');
	}
}
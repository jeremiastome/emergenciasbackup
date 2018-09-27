@isTest
public class UploadBeneficiariosControllerTest {

	@isTest
	private static void itShouldBePossibleTGetAllTheProductsAssociatedWithAHoldersContract() {
		List<UploadBeneficiariosController.CoberturaWrapper> products = UploadBeneficiariosController.getProducts(titular.id);
		System.assertEquals(1, products.size());
	}

	@isTest
	private static void itShouldBePossibleToCreateBeneficiariosFromDataInAText() {
		List<String> productIds = new List<String>();
		productIds.add(aProduct.id);
		ResponseUpload response = UploadBeneficiariosController.uploadFile('', bodyLines, '',
			titular.id, productIds, 'Business_Account', 0, '');

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
		List<Beneficiario__c> beneficiariosSaved = [
			SELECT id,
			Titular__c,
			Contrato__c,
			Provincia1__c,
			Beneficiario__c,
			CUIL_CUIT__c
			FROM Beneficiario__c
		];
		List<Cobertura_de_Beneficiario__c> coberturaDeBeneficiariosSaved = [
			SELECT id,
			Beneficiario__c,
			Cobertura__c,
			Cobertura__r.Nombre_de_Producto__c
			FROM Cobertura_de_Beneficiario__c
		];

		System.assertEquals(3, accountsSaved.size());
		System.assertEquals(2, beneficiariosSaved.size());
		System.assertEquals(2, coberturaDeBeneficiariosSaved.size());
		//Cuentas
		System.assertEquals('LastName test 1', accountsSaved[1].Name);
		System.assertEquals('11111111', accountsSaved[1].Numero_de_Documento__c);
		System.assertEquals('Business_Account', accountsSaved[1].RecordType.DeveloperName);
		System.assertEquals('Capital Federal', accountsSaved[1].Provincia_de_facturacion__c);
		System.assertEquals('12324', accountsSaved[1].Phone);
		System.assertEquals('20111111111', accountsSaved[1].CUIL_CUIT__c);
		System.assertEquals('LastName test 2', accountsSaved[2].Name);
		System.assertEquals('11111112', accountsSaved[2].Numero_de_Documento__c);
		System.assertEquals('Business_Account', accountsSaved[2].RecordType.DeveloperName);
		System.assertEquals('Catamarca', accountsSaved[2].Provincia_de_facturacion__c);
		System.assertEquals('12325', accountsSaved[2].Phone);
		System.assertEquals('20111111112', accountsSaved[2].CUIL_CUIT__c);
		//Beneficiarios
		System.assertEquals(titular.id, beneficiariosSaved[0].Titular__c);
		System.assertEquals(aContract.id, beneficiariosSaved[0].Contrato__c);
		System.assertEquals('Capital Federal', beneficiariosSaved[0].Provincia1__c);
		System.assertEquals(accountsSaved[1].id, beneficiariosSaved[0].Beneficiario__c);
		System.assertEquals(accountsSaved[1].CUIL_CUIT__c, beneficiariosSaved[0].CUIL_CUIT__c);

		System.assertEquals(titular.id, beneficiariosSaved[1].Titular__c);
		System.assertEquals(aContract.id, beneficiariosSaved[1].Contrato__c);
		System.assertEquals('Catamarca', beneficiariosSaved[1].Provincia1__c);
		System.assertEquals(accountsSaved[2].id, beneficiariosSaved[1].Beneficiario__c);
		System.assertEquals(accountsSaved[2].CUIL_CUIT__c, beneficiariosSaved[1].CUIL_CUIT__c);
		//Coberturas de beneficiario
		System.assertEquals(beneficiariosSaved[0].id, coberturaDeBeneficiariosSaved[0].Beneficiario__c);
		System.assertEquals(aProduct.id, coberturaDeBeneficiariosSaved[0].Cobertura__c);
		System.assertEquals(beneficiariosSaved[1].id, coberturaDeBeneficiariosSaved[1].Beneficiario__c);
		System.assertEquals(aProduct.id, coberturaDeBeneficiariosSaved[1].Cobertura__c);
		System.assertEquals('Producto prueba', coberturaDeBeneficiariosSaved[1].Cobertura__r.Nombre_de_Producto__c);
	}

	@isTest
	private static void whenItIsTriedToCreateBeneficiariosFromDataInATextWithSameValues_TheBeneficiariosDoNotDuplicate () {
		List<String> productIds = new List<String>();
		productIds.add(aProduct.id);
		UploadBeneficiariosController.uploadFile('', bodyLines, '',
			titular.id, productIds, 'Business_Account', 0, '');
			UploadBeneficiariosController.uploadFile('', bodyLines, '',
				titular.id, productIds, 'Business_Account', 0, '');

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

		List<Beneficiario__c> beneficiariosSaved = [
			SELECT id,
			Titular__c,
			Contrato__c,
			Provincia1__c,
			Beneficiario__c,
			CUIL_CUIT__c
			FROM Beneficiario__c
		];

		List<Cobertura_de_Beneficiario__c> coberturaDeBeneficiariosSaved = [
			SELECT id,
			Beneficiario__c,
			Cobertura__c,
			Cobertura__r.Nombre_de_Producto__c
			FROM Cobertura_de_Beneficiario__c
		];

		System.assertEquals(3, accountsSaved.size());
		System.assertEquals(2, beneficiariosSaved.size());
		System.assertEquals(2, coberturaDeBeneficiariosSaved.size());
		//Cuentas
		System.assertEquals('LastName test 1', accountsSaved[1].Name);
		System.assertEquals('11111111', accountsSaved[1].Numero_de_Documento__c);
		System.assertEquals('Business_Account', accountsSaved[1].RecordType.DeveloperName);
		System.assertEquals('Capital Federal', accountsSaved[1].Provincia_de_facturacion__c);
		System.assertEquals('12324', accountsSaved[1].Phone);
		System.assertEquals('20111111111', accountsSaved[1].CUIL_CUIT__c);
		System.assertEquals('LastName test 2', accountsSaved[2].Name);
		System.assertEquals('11111112', accountsSaved[2].Numero_de_Documento__c);
		System.assertEquals('Business_Account', accountsSaved[2].RecordType.DeveloperName);
		System.assertEquals('Catamarca', accountsSaved[2].Provincia_de_facturacion__c);
		System.assertEquals('12325', accountsSaved[2].Phone);
		System.assertEquals('20111111112', accountsSaved[2].CUIL_CUIT__c);
		//Beneficiarios
		System.assertEquals(titular.id, beneficiariosSaved[0].Titular__c);
		System.assertEquals(aContract.id, beneficiariosSaved[0].Contrato__c);
		System.assertEquals('Capital Federal', beneficiariosSaved[0].Provincia1__c);
		System.assertEquals(accountsSaved[1].id, beneficiariosSaved[0].Beneficiario__c);
		System.assertEquals(accountsSaved[1].CUIL_CUIT__c, beneficiariosSaved[0].CUIL_CUIT__c);

		System.assertEquals(titular.id, beneficiariosSaved[1].Titular__c);
		System.assertEquals(aContract.id, beneficiariosSaved[1].Contrato__c);
		System.assertEquals('Catamarca', beneficiariosSaved[1].Provincia1__c);
		System.assertEquals(accountsSaved[2].id, beneficiariosSaved[1].Beneficiario__c);
		System.assertEquals(accountsSaved[2].CUIL_CUIT__c, beneficiariosSaved[1].CUIL_CUIT__c);
		//Coberturas de beneficiario
		System.assertEquals(beneficiariosSaved[0].id, coberturaDeBeneficiariosSaved[0].Beneficiario__c);
		System.assertEquals(aProduct.id, coberturaDeBeneficiariosSaved[0].Cobertura__c);
		System.assertEquals('Producto prueba', coberturaDeBeneficiariosSaved[0].Cobertura__r.Nombre_de_Producto__c);
		System.assertEquals(beneficiariosSaved[1].id, coberturaDeBeneficiariosSaved[1].Beneficiario__c);
		System.assertEquals(aProduct.id, coberturaDeBeneficiariosSaved[1].Cobertura__c);
		System.assertEquals('Producto prueba', coberturaDeBeneficiariosSaved[1].Cobertura__r.Nombre_de_Producto__c);
	}

	@isTest
	private static void whenItIsTriedToCreateHoldersAndAccountsFromDataInATextWithTheOtherValues_TheAccountsAreUpdated () {
		List<String> productIds = new List<String>();
		productIds.add(aProduct.id);
		UploadBeneficiariosController.uploadFile('', bodyLines, '',
			titular.id, productIds, 'Business_Account', 0, '');

		List<String> newAccounts = new List<String>();
 		newAccounts.add('New name 2; 11111111 ; La Pampa; 12324; 20111111111');
 		newAccounts.add('New name; 11111112 ; La Pampa; 123123; 20111111112');
		UploadBeneficiariosController.uploadFile('', newAccounts, '',
			titular.id, productIds, 'Business_Account', 0, '');

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

		List<Beneficiario__c> beneficiariosSaved = [
			SELECT id,
			Titular__c,
			Contrato__c,
			Provincia1__c,
			Beneficiario__c,
			CUIL_CUIT__c
			FROM Beneficiario__c
		];

		List<Cobertura_de_Beneficiario__c> coberturaDeBeneficiariosSaved = [
			SELECT id,
			Beneficiario__c,
			Cobertura__c,
			Cobertura__r.Nombre_de_Producto__c
			FROM Cobertura_de_Beneficiario__c
		];

		System.assertEquals(3, accountsSaved.size());
		System.assertEquals(2, beneficiariosSaved.size());
		System.assertEquals(2, coberturaDeBeneficiariosSaved.size());
		//Cuentas
		System.assertEquals('New name 2', accountsSaved[1].Name);
		System.assertEquals('11111111', accountsSaved[1].Numero_de_Documento__c);
		System.assertEquals('Business_Account', accountsSaved[1].RecordType.DeveloperName);
		System.assertEquals('La Pampa', accountsSaved[1].Provincia_de_facturacion__c);
		System.assertEquals('12324', accountsSaved[1].Phone);
		System.assertEquals('20111111111', accountsSaved[1].CUIL_CUIT__c);
		System.assertEquals('New name', accountsSaved[2].Name);
		System.assertEquals('11111112', accountsSaved[2].Numero_de_Documento__c);
		System.assertEquals('Business_Account', accountsSaved[2].RecordType.DeveloperName);
		System.assertEquals('La Pampa', accountsSaved[2].Provincia_de_facturacion__c);
		System.assertEquals('123123', accountsSaved[2].Phone);
		System.assertEquals('20111111112', accountsSaved[2].CUIL_CUIT__c);
		//Beneficiarios
		System.assertEquals(titular.id, beneficiariosSaved[0].Titular__c);
		System.assertEquals(aContract.id, beneficiariosSaved[0].Contrato__c);
		System.assertEquals('Capital Federal', beneficiariosSaved[0].Provincia1__c);
		System.assertEquals(accountsSaved[1].id, beneficiariosSaved[0].Beneficiario__c);
		System.assertEquals(accountsSaved[1].CUIL_CUIT__c, beneficiariosSaved[0].CUIL_CUIT__c);

		System.assertEquals(titular.id, beneficiariosSaved[1].Titular__c);
		System.assertEquals(aContract.id, beneficiariosSaved[1].Contrato__c);
		System.assertEquals('Catamarca', beneficiariosSaved[1].Provincia1__c);
		System.assertEquals(accountsSaved[2].id, beneficiariosSaved[1].Beneficiario__c);
		System.assertEquals(accountsSaved[2].CUIL_CUIT__c, beneficiariosSaved[1].CUIL_CUIT__c);
		//Coberturas de beneficiario
		System.assertEquals(beneficiariosSaved[0].id, coberturaDeBeneficiariosSaved[0].Beneficiario__c);
		System.assertEquals(aProduct.id, coberturaDeBeneficiariosSaved[0].Cobertura__c);
		System.assertEquals(beneficiariosSaved[1].id, coberturaDeBeneficiariosSaved[1].Beneficiario__c);
		System.assertEquals(aProduct.id, coberturaDeBeneficiariosSaved[1].Cobertura__c);
		System.assertEquals('Producto prueba', coberturaDeBeneficiariosSaved[1].Cobertura__r.Nombre_de_Producto__c);
	}

	@isTest
	private static void whenItIsTriedToCreateBeneficiariosFromDataInATextWithTheOtherValues_onlyBeneficiariosForTheNewAccountsAreCreated () {
		List<String> productIds = new List<String>();
		productIds.add(aProduct.id);
		UploadBeneficiariosController.uploadFile('', bodyLines, '',
			titular.id, productIds, 'Business_Account', 0, '');

		List<String> newAccounts = new List<String>();
 		newAccounts.add('LastName test 1; 11111111 ; Capital Federal; 12324; 20111111111');
 		newAccounts.add('New name; 11111112 ; La Pampa; 123123; 20111111113');
		UploadBeneficiariosController.uploadFile('', newAccounts, '',
			titular.id, productIds, 'Business_Account', 0, '');

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

		List<Beneficiario__c> beneficiariosSaved = [
			SELECT id,
			Titular__c,
			Contrato__c,
			Provincia1__c,
			Beneficiario__c,
			CUIL_CUIT__c
			FROM Beneficiario__c
		];

		List<Cobertura_de_Beneficiario__c> coberturaDeBeneficiariosSaved = [
			SELECT id,
			Beneficiario__c,
			Cobertura__c,
			Cobertura__r.Nombre_de_Producto__c
			FROM Cobertura_de_Beneficiario__c
		];

		System.assertEquals(4, accountsSaved.size());
		System.assertEquals(3, beneficiariosSaved.size());
		System.assertEquals(3, coberturaDeBeneficiariosSaved.size());
		//Cuentas
		System.assertEquals('LastName test 1', accountsSaved[1].Name);
		System.assertEquals('11111111', accountsSaved[1].Numero_de_Documento__c);
		System.assertEquals('Business_Account', accountsSaved[1].RecordType.DeveloperName);
		System.assertEquals('Capital Federal', accountsSaved[1].Provincia_de_facturacion__c);
		System.assertEquals('12324', accountsSaved[1].Phone);
		System.assertEquals('20111111111', accountsSaved[1].CUIL_CUIT__c);
		System.assertEquals('LastName test 2', accountsSaved[2].Name);
		System.assertEquals('11111112', accountsSaved[2].Numero_de_Documento__c);
		System.assertEquals('Business_Account', accountsSaved[2].RecordType.DeveloperName);
		System.assertEquals('Catamarca', accountsSaved[2].Provincia_de_facturacion__c);
		System.assertEquals('12325', accountsSaved[2].Phone);
		System.assertEquals('20111111112', accountsSaved[2].CUIL_CUIT__c);
		System.assertEquals('New name', accountsSaved[3].Name);
		System.assertEquals('11111112', accountsSaved[3].Numero_de_Documento__c);
		System.assertEquals('Business_Account', accountsSaved[3].RecordType.DeveloperName);
		System.assertEquals('La Pampa', accountsSaved[3].Provincia_de_facturacion__c);
		System.assertEquals('123123', accountsSaved[3].Phone);
		System.assertEquals('20111111113', accountsSaved[3].CUIL_CUIT__c);
		//Beneficiario
		System.assertEquals(titular.id, beneficiariosSaved[0].Titular__c);
		System.assertEquals(aContract.id, beneficiariosSaved[0].Contrato__c);
		System.assertEquals('Capital Federal', beneficiariosSaved[0].Provincia1__c);
		System.assertEquals(accountsSaved[1].id, beneficiariosSaved[0].Beneficiario__c);
		System.assertEquals(accountsSaved[1].CUIL_CUIT__c, beneficiariosSaved[0].CUIL_CUIT__c);

		System.assertEquals(titular.id, beneficiariosSaved[1].Titular__c);
		System.assertEquals(aContract.id, beneficiariosSaved[1].Contrato__c);
		System.assertEquals('Catamarca', beneficiariosSaved[1].Provincia1__c);
		System.assertEquals(accountsSaved[2].id, beneficiariosSaved[1].Beneficiario__c);
		System.assertEquals(accountsSaved[2].CUIL_CUIT__c, beneficiariosSaved[1].CUIL_CUIT__c);

		System.assertEquals(titular.id, beneficiariosSaved[2].Titular__c);
		System.assertEquals(aContract.id, beneficiariosSaved[2].Contrato__c);
		System.assertEquals('La Pampa', beneficiariosSaved[2].Provincia1__c);
		System.assertEquals(accountsSaved[3].id, beneficiariosSaved[2].Beneficiario__c);
		System.assertEquals(accountsSaved[3].CUIL_CUIT__c, beneficiariosSaved[2].CUIL_CUIT__c);
		//Coberturas de beneficiario
		System.assertEquals(beneficiariosSaved[0].id, coberturaDeBeneficiariosSaved[0].Beneficiario__c);
		System.assertEquals(aProduct.id, coberturaDeBeneficiariosSaved[0].Cobertura__c);
		System.assertEquals('Producto prueba', coberturaDeBeneficiariosSaved[0].Cobertura__r.Nombre_de_Producto__c);
		System.assertEquals(beneficiariosSaved[1].id, coberturaDeBeneficiariosSaved[1].Beneficiario__c);
		System.assertEquals(aProduct.id, coberturaDeBeneficiariosSaved[1].Cobertura__c);
		System.assertEquals('Producto prueba', coberturaDeBeneficiariosSaved[1].Cobertura__r.Nombre_de_Producto__c);
		System.assertEquals(beneficiariosSaved[2].id, coberturaDeBeneficiariosSaved[2].Beneficiario__c);
		System.assertEquals(aProduct.id, coberturaDeBeneficiariosSaved[2].Cobertura__c);
		System.assertEquals('Producto prueba', coberturaDeBeneficiariosSaved[2].Cobertura__r.Nombre_de_Producto__c);
	}

	@isTest
	private static void itShouldBePossibleToCreate100BeneficiariosFromDataInAText() {
		bodyLines = new List<String>();
		for(Integer i = 0; i < 100; i++) {
			String iStr = ''+i;
			if(i<10) {
				iStr = '000'+iStr;
			}
			else if(i<100) {
				iStr = '00'+iStr;
			}
			else if(i<1000) {
				iStr = '0'+iStr;
			}
			String fileString = 'LastName test '+iStr+'; 111111'+iStr+' ; Capital Federal; 12324; 2011111'+iStr+'\n';
			bodyLines.add(fileString);
		}

		List<String> productIds = new List<String>();
		productIds.add(aProduct.id);
		UploadBeneficiariosController.uploadFile('', bodyLines, '',
			titular.id, productIds, 'Business_Account', 0, '');

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
		List<Beneficiario__c> beneficiariosSaved = [
			SELECT id,
			Titular__c,
			Contrato__c,
			Provincia1__c,
			Beneficiario__c,
			N_mero_nico_de_Beneficiario__c,
			CUIL_CUIT__c
			FROM Beneficiario__c
		];
		List<Cobertura_de_Beneficiario__c> coberturaDeBeneficiariosSaved = [
			SELECT id,
			Beneficiario__c,
			Cobertura__c,
			Cobertura__r.Nombre_de_Producto__c
			FROM Cobertura_de_Beneficiario__c
		];

		System.assertEquals(101, accountsSaved.size());
		System.assertEquals(100, beneficiariosSaved.size());
		System.assertEquals(100, coberturaDeBeneficiariosSaved.size());
	}

	@isTest
	private static void when100BeneficiariosAssociatedWith10ProductsAreCreated_1000CoberturasDeBeneficiarioShouldBeCreated() {
		List<String> productIds = new List<String>();

		for(Integer i = 0; i<10; i++) {
			Cobertura__c newProduct = new Cobertura__c(Producto__c = product.id, Contrato__c = aContract.id);
			insert newProduct;
			productIds.add(newProduct.id);
		}

		bodyLines = new List<String>();
		for(Integer i = 0; i < 100; i++) {
			String iStr = ''+i;
			if(i<10) {
				iStr = '000'+iStr;
			}
			else if(i<100) {
				iStr = '00'+iStr;
			}
			else if(i<1000) {
				iStr = '0'+iStr;
			}
			String fileString = 'LastName test '+iStr+'; 111111'+iStr+' ; Capital Federal; 12324; 2011111'+iStr+'\n';
			bodyLines.add(fileString);
		}
		System.debug('*** productIds: ' + productIds);
		UploadBeneficiariosController.uploadFile('', bodyLines, '',
			titular.id, productIds, 'Business_Account', 0, '');

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
		List<Beneficiario__c> beneficiariosSaved = [
			SELECT id,
			Titular__c,
			Contrato__c,
			Provincia1__c,
			Beneficiario__c,
			N_mero_nico_de_Beneficiario__c,
			CUIL_CUIT__c
			FROM Beneficiario__c
		];
		List<Cobertura_de_Beneficiario__c> coberturaDeBeneficiariosSaved = [
			SELECT id,
			Beneficiario__c,
			Cobertura__c,
			Cobertura__r.Nombre_de_Producto__c
			FROM Cobertura_de_Beneficiario__c
		];

		System.assertEquals(101, accountsSaved.size());
		System.assertEquals(100, beneficiariosSaved.size());
		System.assertEquals(1000, coberturaDeBeneficiariosSaved.size());
	}

	@isTest
	private static void whenItIsTriedToLoadABeneficiarioWithoutCUILCUIT_itIsNotSavedAndAFileIsCreatedWithTheCause() {
		List<String> productIds = new List<String>();
		productIds.add(aProduct.id);
		bodyLines = new List<String>();
		bodyLines.add('LastName test 1; 11111111 ; Capital Federal; 12324; 20111111111');
		bodyLines.add('LastName test 2; 11111112 ; Catamarca; 12325; ');
		ResponseUpload response = UploadBeneficiariosController.uploadFile('', bodyLines, '',
			titular.id, productIds, 'PersonAccount', 0, '');

		List<Account> accountsSaved = [
			SELECT id,
			LastName,
			Numero_de_Documento__c,
			RecordType.DeveloperName,
			Provincia_de_facturacion__c,
			Phone,
			CUIL_CUIT__c
			FROM Account
		];
		List<Beneficiario__c> beneficiariosSaved = [
			SELECT id,
			Titular__c,
			Contrato__c,
			Provincia1__c,
			Beneficiario__c,
			CUIL_CUIT__c
			FROM Beneficiario__c
		];
		List<Cobertura_de_Beneficiario__c> coberturaDeBeneficiariosSaved = [
			SELECT id,
			Beneficiario__c,
			Cobertura__c,
			Cobertura__r.Nombre_de_Producto__c
			FROM Cobertura_de_Beneficiario__c
		];

		List<ContentDocumentLink> contentDocumentLink = [
			SELECT id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:titular.id
		];
		String contentDocumentId = contentDocumentLink[0].ContentDocumentId;
		List<ContentVersion> contentVersion = [
			SELECT id, ContentDocumentId FROM ContentVersion
			WHERE ContentDocumentId=:contentDocumentId
		];

		System.assertEquals(2, accountsSaved.size());
		System.assertEquals(1, beneficiariosSaved.size());
		System.assertEquals(1, coberturaDeBeneficiariosSaved.size());
		System.assertEquals(1, contentDocumentLink.size());
		System.assertEquals(1, contentVersion.size());
		//Cuentas
		System.assertEquals('LastName test 1', accountsSaved[1].LastName);
		System.assertEquals('11111111', accountsSaved[1].Numero_de_Documento__c);
		System.assertEquals('PersonAccount', accountsSaved[1].RecordType.DeveloperName);
		System.assertEquals('Capital Federal', accountsSaved[1].Provincia_de_facturacion__c);
		System.assertEquals('12324', accountsSaved[1].Phone);
		System.assertEquals('20111111111', accountsSaved[1].CUIL_CUIT__c);
		//Beneficiarios
		System.assertEquals(titular.id, beneficiariosSaved[0].Titular__c);
		System.assertEquals(aContract.id, beneficiariosSaved[0].Contrato__c);
		System.assertEquals('Capital Federal', beneficiariosSaved[0].Provincia1__c);
		System.assertEquals(accountsSaved[1].id, beneficiariosSaved[0].Beneficiario__c);
		System.assertEquals(accountsSaved[1].CUIL_CUIT__c, beneficiariosSaved[0].CUIL_CUIT__c);

		//Coberturas de beneficiario
		System.assertEquals(beneficiariosSaved[0].id, coberturaDeBeneficiariosSaved[0].Beneficiario__c);
		System.assertEquals(aProduct.id, coberturaDeBeneficiariosSaved[0].Cobertura__c);
		System.assertEquals('Producto prueba', coberturaDeBeneficiariosSaved[0].Cobertura__r.Nombre_de_Producto__c);
	}

	@isTest
	private static void whenItIsTriedToLoadABeneficiarioWithAnInvalidProvincia_itIsNotSavedAndAFileIsCreatedWithTheCause() {
		List<String> productIds = new List<String>();
		productIds.add(aProduct.id);
		bodyLines = new List<String>();
		bodyLines.add('LastName test 1; 11111111 ; Capital Federal; 12324; 20111111111');
		bodyLines.add('LastName test 2; 11111112 ; asd; 12325; 20111111112');
		ResponseUpload response = UploadBeneficiariosController.uploadFile('', bodyLines, '',
			titular.id, productIds, 'PersonAccount', 0, '');

		List<Account> accountsSaved = [
			SELECT id,
			LastName,
			Numero_de_Documento__c,
			RecordType.DeveloperName,
			Provincia_de_facturacion__c,
			Phone,
			CUIL_CUIT__c
			FROM Account
		];
		List<Beneficiario__c> beneficiariosSaved = [
			SELECT id,
			Titular__c,
			Contrato__c,
			Provincia1__c,
			Beneficiario__c,
			CUIL_CUIT__c
			FROM Beneficiario__c
		];
		List<Cobertura_de_Beneficiario__c> coberturaDeBeneficiariosSaved = [
			SELECT id,
			Beneficiario__c,
			Cobertura__c,
			Cobertura__r.Nombre_de_Producto__c
			FROM Cobertura_de_Beneficiario__c
		];

		List<ContentDocumentLink> contentDocumentLink = [
			SELECT id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:titular.id
		];
		String contentDocumentId = contentDocumentLink[0].ContentDocumentId;
		List<ContentVersion> contentVersion = [
			SELECT id, ContentDocumentId FROM ContentVersion
			WHERE ContentDocumentId=:contentDocumentId
		];

		System.assertEquals(2, accountsSaved.size());
		System.assertEquals(1, beneficiariosSaved.size());
		System.assertEquals(1, coberturaDeBeneficiariosSaved.size());
		System.assertEquals(1, contentDocumentLink.size());
		System.assertEquals(1, contentVersion.size());
		//Cuentas
		System.assertEquals('LastName test 1', accountsSaved[1].LastName);
		System.assertEquals('11111111', accountsSaved[1].Numero_de_Documento__c);
		System.assertEquals('PersonAccount', accountsSaved[1].RecordType.DeveloperName);
		System.assertEquals('Capital Federal', accountsSaved[1].Provincia_de_facturacion__c);
		System.assertEquals('12324', accountsSaved[1].Phone);
		System.assertEquals('20111111111', accountsSaved[1].CUIL_CUIT__c);
		//Beneficiarios
		System.assertEquals(titular.id, beneficiariosSaved[0].Titular__c);
		System.assertEquals(aContract.id, beneficiariosSaved[0].Contrato__c);
		System.assertEquals('Capital Federal', beneficiariosSaved[0].Provincia1__c);
		System.assertEquals(accountsSaved[1].id, beneficiariosSaved[0].Beneficiario__c);
		System.assertEquals(accountsSaved[1].CUIL_CUIT__c, beneficiariosSaved[0].CUIL_CUIT__c);

		//Coberturas de beneficiario
		System.assertEquals(beneficiariosSaved[0].id, coberturaDeBeneficiariosSaved[0].Beneficiario__c);
		System.assertEquals(aProduct.id, coberturaDeBeneficiariosSaved[0].Cobertura__c);
		System.assertEquals('Producto prueba', coberturaDeBeneficiariosSaved[0].Cobertura__r.Nombre_de_Producto__c);
	}

	static Product2 product;
	static Contrato__c aContract;
	static Account anAccount;
	static String[] bodyLines;
	static Titular__c titular;
	static Cobertura__c aProduct;

	static {
		anAccount = Build.anAccount().build();
		insert anAccount;
		aContract = Build.aContract().withUniqueNumber().withUniqueNumber('H').forAccount(anAccount).build();
		insert aContract;
		titular = new Titular__c(Contrato__c = aContract.id, Cliente__c = anAccount.id);
		insert titular;
		product = new Product2(name = 'Producto prueba');
		insert product;
		aProduct = new Cobertura__c(Producto__c = product.id, Contrato__c = aContract.id);
		insert aProduct;
		bodyLines = new List<String>();
		bodyLines.add('LastName test 1; 11111111 ; Capital Federal; 12324; 20111111111');
		bodyLines.add('LastName test 2; 11111112 ; Catamarca; 12325; 20111111112');
	}
}
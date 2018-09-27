@isTest
public class GeneratePDFcontractControllerTest {

	private static testmethod void generateAPDFWithHogarPortegido() {
		Account accountOfContract = Build.anAccount().build();
		insert accountOfContract;

		Product2 productHogarProtegido = Build.aProduct().withName('Hogar Protegido').build();
		insert productHogarProtegido;

		Contrato__c contractOfTest = Build.aContract().forAccount(accountOfContract).build();
		insert contractOfTest;

		Cobertura__c productOfContract = Build.aCoverage().forProduct(productHogarProtegido).forContract(contractOfTest).build();
		insert productOfContract;

		//Beneficiario__c beneficiarioOfContract = Build.aRecipient().forContract(contractOfTest).forAccount(accountOfContract).build();
		//insert beneficiarioOfContract;

		ApexPages.currentPage().getParameters().put('id', contractOfTest.Id);

		GeneratePDFcontractController controller = new GeneratePDFcontractController();

		System.assertEquals(true, controller.haveHogarProtegido);
	}

	private static testmethod void generateAPDFWithAreaProtegida() {
		Account accountOfContract = Build.anAccount().build();
		insert accountOfContract;

		Product2 productArea = Build.aProduct().withName('Area Protegida').build();
		insert productArea;

		Contrato__c contractOfTest = Build.aContract().forAccount(accountOfContract).build();
		insert contractOfTest;

		Cobertura__c productOfContract = Build.aCoverage().forProduct(productArea).forContract(contractOfTest).build();
		insert productOfContract;


		ApexPages.currentPage().getParameters().put('id', contractOfTest.Id);

		GeneratePDFcontractController controller = new GeneratePDFcontractController();

		System.assertEquals(true, controller.haveAreaProtegida);
	}

	private static testmethod void generateAPDFWithEmerphone() {
		Account accountOfContract = Build.anAccount().build();
		insert accountOfContract;

		Product2 productEmerPhone = Build.aProduct().withName('Emerphone').build();
		insert productEmerPhone;

		Contrato__c contractOfTest = Build.aContract().forAccount(accountOfContract).build();
		insert contractOfTest;

		Cobertura__c productOfContract = Build.aCoverage().forProduct(productEmerPhone).forContract(contractOfTest).build();
		insert productOfContract;


		ApexPages.currentPage().getParameters().put('id', contractOfTest.Id);

		GeneratePDFcontractController controller = new GeneratePDFcontractController();

		System.assertEquals(true, controller.haveEmerphone);
	}

	private static testmethod void generateAPDFWithAutoProtegido() {
		Account accountOfContract = Build.anAccount().build();
		insert accountOfContract;

		Product2 productAutoProtegido = Build.aProduct().withName('Auto Protegido').build();
		insert productAutoProtegido;

		Contrato__c contractOfTest = Build.aContract().forAccount(accountOfContract).build();
		insert contractOfTest;

		Cobertura__c productOfContract = Build.aCoverage().forProduct(productAutoProtegido).forContract(contractOfTest).build();
		insert productOfContract;


		ApexPages.currentPage().getParameters().put('id', contractOfTest.Id);

		GeneratePDFcontractController controller = new GeneratePDFcontractController();

		System.assertEquals(true, controller.haveAutoProtegido);
	}

	private static testmethod void generateAPDFWithMedicinaEmpresarial() {
		Account accountOfContract = Build.anAccount().build();
		insert accountOfContract;

		Product2 productMedicinaEmpresarial = Build.aProduct().withName('MEDICINA EMPRESARIAL').build();
		insert productMedicinaEmpresarial;

		Contrato__c contractOfTest = Build.aContract().forAccount(accountOfContract).build();
		insert contractOfTest;

		Cobertura__c productOfContract = Build.aCoverage().forProduct(productMedicinaEmpresarial).forContract(contractOfTest).build();
		insert productOfContract;


		ApexPages.currentPage().getParameters().put('id', contractOfTest.Id);

		GeneratePDFcontractController controller = new GeneratePDFcontractController();

		System.assertEquals(true, controller.haveMedicinaEmpresarial);
	}

	private static testmethod void generateAPDFWithVisitorCard() {
		
		Account accountOfContract = Build.anAccount().build();
		insert accountOfContract;

		Product2 prodcutVisitorCard = Build.aProduct().withName('Visitor Card').build();
		insert prodcutVisitorCard;

		Contrato__c contractOfTest = Build.aContract().forAccount(accountOfContract).build();
		insert contractOfTest;

		Cobertura__c productOfContract = Build.aCoverage().forProduct(prodcutVisitorCard).forContract(contractOfTest).build();
		insert productOfContract;


		ApexPages.currentPage().getParameters().put('id', contractOfTest.Id);

		GeneratePDFcontractController controller = new GeneratePDFcontractController();

		System.assertEquals(true, controller.haveVisitorCard);
	}

	private static testmethod void generateAPDFWithServicioECA() {
		Account accountOfContract = Build.anAccount().build();
		insert accountOfContract;

		Product2 productServicioECA = Build.aProduct().withName('Servicio ECA').build();
		insert productServicioECA;

		Contrato__c contractOfTest = Build.aContract().forAccount(accountOfContract).build();
		insert contractOfTest;

		Cobertura__c productOfContract = Build.aCoverage().forProduct(productServicioECA).forContract(contractOfTest).build();
		insert productOfContract;


		ApexPages.currentPage().getParameters().put('id', contractOfTest.Id);

		GeneratePDFcontractController controller = new GeneratePDFcontractController();

		System.assertEquals(true, controller.haveServicioEca);
	}


}
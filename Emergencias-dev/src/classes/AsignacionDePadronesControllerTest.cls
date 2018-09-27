@isTest
private class AsignacionDePadronesControllerTest {
	private static testMethod void initiallyTheCoveragesForTheContractShouldBeObtainable() {
		AsignacionDePadronesController controller = new AsignacionDePadronesController();

		System.assertEquals(1, controller.Coverages.size());
		System.assertEquals(aCoverage.Id, controller.Coverages[0].Id);
		System.assertEquals(aContract.Id, controller.ReturnRecord);
	}

	private static testMethod void initiallyAListOfTheProvincesShouldBeObtainable() {
		Map<String, String> provinceValues = new Map<String, String>();
		for(Schema.PicklistEntry provinceValue : Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues()) {
			provinceValues.put(provinceValue.getValue(), provinceValue.getLabel());
		}

		AsignacionDePadronesController controller = new AsignacionDePadronesController();

		System.assertEquals(provinceValues.size(), controller.ProvinceOptions.size());
		for(SelectOption provinceOption : controller.ProvinceOptions) {
			System.assert(provinceValues.containsKey(provinceOption.getValue()));
			System.assertEquals(
				provinceValues.get(provinceOption.getValue()),
				provinceOption.getLabel()
			);
		}
	}

	private static testMethod void itShouldBePosibleToAddARecipient() {
		String recipientToAdd = Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues()[0].getValue();
		AsignacionDePadronesController controller = new AsignacionDePadronesController();

		controller.NextRecipient = recipientToAdd;
		controller.addRecipient();
		System.assertEquals('', controller.NextRecipient);
		System.assertEquals(1, controller.Recipients.size());
		System.assertEquals(recipientToAdd, controller.Recipients[0].Recipient.Provincia1__c);
		System.assertEquals(
			controller.Coverages.size() * controller.IVATreatmentLabelByValue.size(),
			controller.Recipients[0].RelationsByIVAAndCoverage.size()
		);
		for(Cobertura__c coverage : controller.Coverages) {
			for(String ivaTreatmentKey : controller.IVATreatmentLabelByValue.keySet()) {
				System.assertEquals(
					true,
					controller.Recipients[0].RelationsByIVAAndCoverage.containsKey(ivaTreatmentKey + coverage.Id)
				);
			}
		}

		System.assertEquals(
			Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues().size() - 1,
			controller.ProvinceOptions.size()
		);
		for(SelectOption provinceOption : controller.ProvinceOptions) {
			System.assertNotEquals(recipientToAdd, provinceOption.getValue());
		}
	}

	private static testMethod void itShouldBePosibleToSaveTheCoverageRelations() {
		AsignacionDePadronesController controller = new AsignacionDePadronesController();

		controller.NextRecipient = Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues()[0].getValue();
		controller.addRecipient();

		controller.Recipients[0].RelationsByIVAAndCoverage.values()[0].Cantidad_de_Padron__c = 200;//Should be saved
		controller.Recipients[0].RelationsByIVAAndCoverage.values()[1].Cantidad_de_Padron__c = 0;//Should not be saved

		controller.save();

		List<Beneficiario__c> recipients = [
			SELECT Id, Provincia1__c, RecordType.DeveloperName
			FROM Beneficiario__c
			WHERE Contrato__c = :aContract.Id
		];

		List<Historial_de_Padron__c> historiales = [SELECT id,
			Tipo_de_operacion__c, Cantidad_de_capitas__c, Contrato__c, Producto__c
			FROM Historial_de_Padron__c];

		System.assertEquals(1, recipients.size());
		System.assertEquals(controller.Recipients[0].Recipient.Provincia1__c, recipients[0].Provincia1__c);
		System.assertEquals('Padron', recipients[0].RecordType.DeveloperName);

		System.assertEquals(1, historiales.size());
		System.assertEquals(200, historiales[0].Cantidad_de_capitas__c);
		System.assertEquals('Creacion', historiales[0].Tipo_de_operacion__c);
		System.assertEquals(aContract.id, historiales[0].Contrato__c);
		System.assertEquals('Test', historiales[0].Producto__c);

		List<Cobertura_de_Beneficiario__c> recipientCoverages = [
			SELECT id, Cantidad_de_Padron__c
			FROM Cobertura_de_Beneficiario__c
			WHERE Beneficiario__c = :recipients[0].Id
		];

		System.assertEquals(1, recipientCoverages.size());
		System.assertEquals(
			controller.Recipients[0].RelationsByIVAAndCoverage.values()[0].Cantidad_de_Padron__c,
			recipientCoverages[0].Cantidad_de_Padron__c
		);
	}

	private static testMethod void initiallySavedCoverageRelationsShouldBeLoaded() {
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract)
			.forAccount(anAccount).forHolder(aHolder).withCensusDate(System.today().addDays(-3))
			.withProvince(Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues()[0].getValue())
			.build();
		insert aRecipient;
		Cobertura_de_Beneficiario__c aRecpientCoverage = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(aCoverage).withIVATreatmentExempt().withAmountForMassiveRecipient(30).build();
		insert aRecpientCoverage;

		AsignacionDePadronesController controller = new AsignacionDePadronesController();

		System.assertEquals(1, controller.Recipients.size());
		System.assertEquals(aRecipient.Id, controller.Recipients[0].Recipient.Id);
		System.assertEquals(
			controller.Coverages.size() * controller.IVATreatmentLabelByValue.size(),
			controller.Recipients[0].RelationsByIVAAndCoverage.size()
		);
		System.assertEquals(
			aRecpientCoverage.Cantidad_de_Padron__c,
			controller.Recipients[0].RelationsByIVAAndCoverage.get(
				aRecpientCoverage.Tratamiento_de_IVA__c + aRecpientCoverage.Cobertura__c
			).Cantidad_de_Padron__c
		);
		System.assertEquals(aRecipient.Fecha_de_padron__c, controller.StartDate);

		System.assertEquals(
			Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues().size() - 1,
			controller.ProvinceOptions.size()
		);
		for(SelectOption provinceOption : controller.ProvinceOptions) {
			System.assertNotEquals(aRecipient.Provincia1__c, provinceOption.getValue());
		}
	}

	private static testMethod void whenSavingACoverageRelationsWithAnAmountOfZeroDontShouldBeDeleted() {
		AsignacionDePadronesController controller = new AsignacionDePadronesController();
		controller.NextRecipient = Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues()[0].getValue();
		controller.addRecipient();

		controller.Recipients[0].RelationsByIVAAndCoverage.values()[0].Cantidad_de_Padron__c = 200;
		controller.save();
		List<Cobertura_de_Beneficiario__c> coberturas = [
			SELECT Id
			FROM Cobertura_de_Beneficiario__c];
		List<Beneficiario__c> beneficiarios = [
			SELECT Id
			FROM Beneficiario__c];

		AsignacionDePadronesController newInstanceController = new AsignacionDePadronesController();

		Test.StartTest();
		newInstanceController.Recipients[0].RelationsByIVAAndCoverage.values()[0].Cantidad_de_Padron__c = 0;
		newInstanceController.save();
		Test.StopTest();

		List<Cobertura_de_Beneficiario__c> theRecpientCoverageInDb = [
			SELECT Id
			FROM Cobertura_de_Beneficiario__c];

		System.assertEquals(1, theRecpientCoverageInDb.size());

		List<Historial_de_Padron__c> historiales = [SELECT id,
			Tipo_de_operacion__c, Cantidad_de_capitas__c, Contrato__c, Producto__c
			FROM Historial_de_Padron__c];
		System.assertEquals(2, historiales.size());

		System.assertEquals(200, historiales[0].Cantidad_de_capitas__c);
		System.assertEquals('Creacion', historiales[0].Tipo_de_operacion__c);
		System.assertEquals(aContract.id, historiales[0].Contrato__c);
		System.assertEquals('Test', historiales[0].Producto__c);

		System.assertEquals(0, historiales[1].Cantidad_de_capitas__c);
		System.assertEquals('Modificacion', historiales[1].Tipo_de_operacion__c);
		System.assertEquals(aContract.id, historiales[1].Contrato__c);
		System.assertEquals('Test', historiales[1].Producto__c);
	}

	private static testMethod void itShouldBePosibleToRemoveARecipient() {
		AsignacionDePadronesController controller = new AsignacionDePadronesController();
		String recipientToAdd = Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues()[0].getValue();

		controller.NextRecipient = recipientToAdd;
		controller.addRecipient();

		controller.RecipientToRemove = controller.Recipients[0].Index;
		controller.removeRecipient();

		System.assertEquals(0, controller.Recipients.size());

		System.assertEquals(
			Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues().size(),
			controller.ProvinceOptions.size()
		);
		boolean provinceIsAvailable = false;
		for(SelectOption provinceOption : controller.ProvinceOptions) {
			if(recipientToAdd == provinceOption.getValue()) {
				provinceIsAvailable = true;
			}
		}
		System.assert(provinceIsAvailable);
	}

	private static testMethod void whenARecipientIsRemovedItShouldBeDeletedWhenSaving() {
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract).forAccount(anAccount)
			.withProvince(Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues()[0].getValue())
			.forHolder(aHolder).build();
		insert aRecipient;
		Cobertura_de_Beneficiario__c aRecpientCoverage = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(aCoverage).withIVATreatmentExempt().withAmountForMassiveRecipient(30).build();
		insert aRecpientCoverage;

		AsignacionDePadronesController controller = new AsignacionDePadronesController();

		controller.RecipientToRemove = controller.Recipients[0].Index;
		controller.removeRecipient();

		System.assertEquals(0, controller.Recipients.size());

		List<Beneficiario__c> theRecipientInDb = [
			SELECT Id
			FROM Beneficiario__c
			WHERE Id = :aRecipient.Id
		];
		System.assertEquals(1, theRecipientInDb.size());

		controller.save();

		theRecipientInDb = [
			SELECT Id
			FROM Beneficiario__c
			WHERE Id = :aRecipient.Id
		];
		System.assertEquals(0, theRecipientInDb.size());
	}

	private static testMethod void itShouldBePosibleToSetADateForAllRecipients() {
		AsignacionDePadronesController controller = new AsignacionDePadronesController();

		controller.StartDate = System.today().addDays(4);

		controller.NextRecipient = Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues()[0].getValue();
		controller.addRecipient();
		controller.Recipients[0].RelationsByIVAAndCoverage.values()[0].Cantidad_de_Padron__c = 200;

		controller.save();

		List<Beneficiario__c> recipients = [
			SELECT Id, Fecha_de_padron__c
			FROM Beneficiario__c
			WHERE Contrato__c = :aContract.Id
		];

		System.assertEquals(controller.StartDate, recipients[0].Fecha_de_padron__c);
		List<Historial_de_Padron__c> historiales = [SELECT id,
			Tipo_de_operacion__c, Cantidad_de_capitas__c, Contrato__c, Producto__c
			FROM Historial_de_Padron__c];
		System.assertEquals(1, historiales.size());
		System.assertEquals(200, historiales[0].Cantidad_de_capitas__c);
		System.assertEquals('Creacion', historiales[0].Tipo_de_operacion__c);
		System.assertEquals(aContract.id, historiales[0].Contrato__c);
		System.assertEquals('Test', historiales[0].Producto__c);
	}

	private static testMethod void whenSavingACoverageRelationsWithAnAmountOfDifferentFromThePrevious_AHistorialShouldBeSabed() {
		AsignacionDePadronesController controller = new AsignacionDePadronesController();

		controller.NextRecipient = Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues()[0].getValue();
		controller.addRecipient();

		controller.Recipients[0].RelationsByIVAAndCoverage.values()[0].Cantidad_de_Padron__c = 200;
		controller.save();

		AsignacionDePadronesController newInstanceController = new AsignacionDePadronesController();
		Test.StartTest();
		newInstanceController.Recipients[0].RelationsByIVAAndCoverage.values()[0].Cantidad_de_Padron__c = 1234;
		newInstanceController.save();
		Test.StopTest();

		List<Cobertura_de_Beneficiario__c> theRecpientCoverageInDb = [
			SELECT Id
			FROM Cobertura_de_Beneficiario__c];

		System.assertEquals(1, theRecpientCoverageInDb.size());

		List<Historial_de_Padron__c> historiales = [SELECT id,
			Tipo_de_operacion__c, Cantidad_de_capitas__c, Contrato__c, Producto__c
			FROM Historial_de_Padron__c];
		System.assertEquals(2, historiales.size());

		System.assertEquals(200, historiales[0].Cantidad_de_capitas__c);
		System.assertEquals('Creacion', historiales[0].Tipo_de_operacion__c);
		System.assertEquals(aContract.id, historiales[0].Contrato__c);
		System.assertEquals('Test', historiales[0].Producto__c);

		System.assertEquals(1234, historiales[1].Cantidad_de_capitas__c);
		System.assertEquals('Modificacion', historiales[1].Tipo_de_operacion__c);
		System.assertEquals(aContract.id, historiales[1].Contrato__c);
		System.assertEquals('Test', historiales[1].Producto__c);
	}

	private static testMethod void afterSavingSuccessfully_TheContractShouldBeSentToSAP() {
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		String province = Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues()[0].getValue();
		Interlocutor_Provincia__c aProvinceSetting = Build.aProvinceSetting().withName(province).withSAPCode('78yi32307u').build();
		insert aProvinceSetting;
		aContract.Estado__c = 'Activo';
		aContract.Saltear_envio__c = 2;
		update aContract;

		AsignacionDePadronesController controller = new AsignacionDePadronesController();

		controller.NextRecipient = province;
		controller.addRecipient();

		controller.Recipients[0].RelationsByIVAAndCoverage.values()[0].Cantidad_de_Padron__c = 200;

		Test.startTest();
		controller.save();
		Test.stopTest();

		System.assertNotEquals(null, serverMock.requestObj);
	}

	//==========================================================================
	static Product2 aProduct;
	static Account anAccount;
	static Contrato__c aContract;
	static Titular__c aHolder;
	static Cobertura__c aCoverage;

	static {
		aProduct = Build.aProduct().build();
		insert aProduct;
		anAccount = Build.anAccount().build();
		insert anAccount;
		aContract = Build.aContract().forAccount(anAccount).withUniqueNumber().build();
		insert aContract;
		aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		aCoverage = Build.aCoverage().forContract(aContract).forProduct(aProduct).build();
		insert aCoverage;

		Test.setCurrentPage(new PageReference('Page.AsignacionDePadrones'));
		ApexPages.currentPage().getParameters().put('Id', aContract.Id);
	}
}
@isTest
private class AsignacionDeBeneficiosControllerTest {
	private static testMethod void initiallyTheRecipientsOfTheContractShouldBeObtained() {
		Set<Id> reciepientsId = new Set<Id>();
		for(Beneficiario__c recipient : recipients) {
			reciepientsId.add(recipient.Id);
		}
		
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		System.assertEquals(recipients.size(), controller.Recipients.size());
		for(Beneficiario__c recipient : controller.Recipients) {
			System.assert(reciepientsId.contains(recipient.Id));
		}
	}
	
	private static testMethod void itShouldBePosibleToGetTheCoveredProductsByTheContract() {
		Set<Id> coberageIds = new Set<Id>();
		for(Cobertura__c coverage : coverages) {
			coberageIds.add(coverage.Id);
		}
		
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		System.assertEquals(coverages.size(), controller.Coverages.size());
		for(Cobertura__c coverage : controller.Coverages) {
			System.assert(coberageIds.contains(coverage.Id));
		}
	}
	
	private static testMethod void initiallyARelationWrapperForEveryCoverageAndRecipientShouldBePrepared() {
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		System.assertEquals(recipients.size(), controller.RelationsByCoverageByRecipient.size());
		for(Beneficiario__c recipient : recipients) {
			System.assertEquals(products.size(), controller.RelationsByCoverageByRecipient.get(recipient.Id).size());
		}
	}

	private static testMethod void initiallyARelationWrapperForEveryRecipientCoverageAndAAppliedDiscountOfAnSpecificCodeShouldBePrepared() {
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		System.assertEquals(recipients.size(), controller.RelationsByCoverageByRecipient.size());
		for(Beneficiario__c recipient : recipients) {

			List<AsignacionDeBeneficiosController.CoverageRecipientWrapper> wrappers = controller.RelationsByCoverageByRecipient.get(recipient.Id).values();
			
			for (AsignacionDeBeneficiosController.CoverageRecipientWrapper wrapper : wrappers) {
				
				if (wrapper.Relation.Cobertura__c == Coverages[0].Id) {
					System.assertNotEquals(null, wrapper.Discounts);
					System.assertEquals(1, wrapper.Discounts.size()); // Only one discount with code ZDV1
				} else {
					System.assertNotEquals(null, wrapper.Discounts);
					System.assert(wrapper.Discounts.isEmpty());
				}
			}
		}
	}
	
	private static testMethod void itShouldBePosibleToCreateANewRecipientForAContractAndPrepareItsRelations() {
		Account recipientAccount = Build.anAccount().isPersonAccount()
			.withLastName('Test').withFirstName('man').withCUILCUIT('45678687687').build();
		insert recipientAccount;
		RecordType personRecipientType = [
			SELECT Id, Name, DeveloperName
			FROM RecordType
			WHERE sObjectType = 'Beneficiario__c'
				AND IsActive = true
				AND DeveloperName = 'Persona'
		];
		
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		controller.NewAccount.CUIL_CUIT__c = recipientAccount.CUIL_CUIT__c;
		controller.NewAccount.Phone = '676567823423';
		controller.AccFirstName = 'Test';
		controller.NewRecipient.Provincia1__c = Beneficiario__c.Provincia1__c
			.getDescribe().getPicklistValues()[0].getValue();
		controller.AccLastName = 'Man';
		controller.NewRecipient.RecordTypeId = personRecipientType.Id;
		controller.NewRecipient.Titular__c = holders[0].Id;
		controller.createRecipient();
		
		List<Beneficiario__c> newRecipients = [
			SELECT Id, Beneficiario__c, Contrato__c
			FROM Beneficiario__c
			WHERE Beneficiario__c = :recipientAccount.Id
		];
		
		System.assertEquals(1, newRecipients.size());
		System.assertEquals(recipientAccount.Id, newRecipients[0].Beneficiario__c);
		System.assertEquals(aContract.Id, newRecipients[0].Contrato__c);
		
		System.assertEquals(recipients.size() + 1, controller.Recipients.size());
		integer i = 0;
		while(i < controller.Recipients.size() && controller.Recipients[i].Id != newRecipients[0].Id) {
			i++;
		}
		
		System.assertNotEquals(null, controller.Recipients[i].Nombre__c);
		System.assertNotEquals(null, controller.Recipients[i].Apellido__c);
		
		System.assertEquals(recipients.size() + 1, controller.RelationsByCoverageByRecipient.size());
		System.assertEquals(coverages.size(), controller.RelationsByCoverageByRecipient.get(newRecipients[0].Id).size());
	}
	
	private static testMethod void theNewRecipientCreatedForTheContractHasAPreparedRelationToAnAppliedDiscount() {
		Account recipientAccount = Build.anAccount().isPersonAccount()
			.withLastName('Test').withFirstName('man').withCUILCUIT('45678687687').build();
		insert recipientAccount;
		RecordType personRecipientType = [
			SELECT Id, Name, DeveloperName
			FROM RecordType
			WHERE sObjectType = 'Beneficiario__c'
				AND IsActive = true
				AND DeveloperName = 'Persona'
		];
		
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		controller.NewAccount.CUIL_CUIT__c = recipientAccount.CUIL_CUIT__c;
		controller.NewAccount.Phone = '676567823423';
		controller.AccFirstName = 'Test';
		controller.AccLastName = 'Man';
		controller.NewRecipient.Provincia1__c = Beneficiario__c.Provincia1__c
			.getDescribe().getPicklistValues()[0].getValue();
		controller.NewRecipient.RecordTypeId = personRecipientType.Id;
		controller.NewRecipient.Titular__c = holders[0].Id;
		controller.createRecipient();
		
		List<Beneficiario__c> newRecipients = [
			SELECT Id, Beneficiario__c, Contrato__c
			FROM Beneficiario__c
			WHERE Beneficiario__c = :recipientAccount.Id
		];
		
		System.assertEquals(recipients.size() + 1, controller.Recipients.size());
		integer i = 0;
		while(i < controller.Recipients.size() && controller.Recipients[i].Id != newRecipients[0].Id) {
			i++;
		}
				
		System.assertEquals(recipients.size() + 1, controller.RelationsByCoverageByRecipient.size());
		
		List<AsignacionDeBeneficiosController.CoverageRecipientWrapper> newRecipientWrappers = controller.RelationsByCoverageByRecipient.get(newRecipients[0].Id).values();
			
		for (AsignacionDeBeneficiosController.CoverageRecipientWrapper wrapper : newRecipientWrappers) {
				
			if (wrapper.Relation.Cobertura__c == Coverages[0].Id) {
				System.assertNotEquals(null, wrapper.Discounts);
				System.assertEquals(1, wrapper.Discounts.size()); // Only one discount with code ZDV1
			} else {
				System.assertNotEquals(null, wrapper.Discounts);
				System.assert(wrapper.Discounts.isEmpty());
			}
		}
	}

	private static testMethod void initiallyExistingRelationsShouldBeMarkedAsActive() {
		Cobertura_de_Beneficiario__c aCoverageRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(recipients[1]).forCoverage(coverages[0]).build();
		insert aCoverageRecipientRelation;
		
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		System.assertEquals(
			true,
			controller
				.RelationsByCoverageByRecipient
					.get(aCoverageRecipientRelation.Beneficiario__c)
					.get(aCoverageRecipientRelation.Cobertura__c)
						.IsActive
		);
	}

	private static testMethod void initiallyExistingApplicantsToDiscountsShouldBeMarkedAsActive() {

		Cobertura_de_Beneficiario__c aCoverageRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(recipients[1])
			.forCoverage(coverages[0])
			.build();
		insert aCoverageRecipientRelation;

		Aplicante__c anApplicant = Build.anApplicant()
			.forAppliedDiscount(appliedDiscounts[0])
			.forRecipientCoverage(aCoverageRecipientRelation)
			.build();
		insert anApplicant;
		
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		System.assertEquals(
			true,
			controller
				.RelationsByCoverageByRecipient
					.get(aCoverageRecipientRelation.Beneficiario__c)
					.get(aCoverageRecipientRelation.Cobertura__c)
					.Discounts[0].IsActive
		);
	}
	
	private static testMethod void itShouldBePosibleToSaveTheActiveRelations() {
		Id coverageId = coverages[0].Id;
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		activateRelationsForAllRecipients(controller, coverageId);
		
		PageReference nextPage = controller.save();
		
		System.assertEquals('/' + aContract.Id, nextPage.getUrl());
		
		List<Cobertura_de_Beneficiario__c> coverageRecipientRelations = [
			SELECT Id, Beneficiario__c, Cobertura__c
			FROM Cobertura_de_Beneficiario__c
		];
		
		System.assertEquals(recipients.size(), coverageRecipientRelations.size());
		System.assertEquals(coverageId, coverageRecipientRelations[0].Cobertura__c);
	}
	
	private static testMethod void itShouldBePosibleToSaveTheActiveRelationsWithAppliedDiscounts() {
		
		// Build a minor recipient
		Account aMinor = Build.anAccount().isPersonAccount().withBirthdate(birthdateOfAMinor).build();
		insert aMinor;
		Beneficiario__c aMinorRecipient = Build.aRecipient()
			.forContract(aContract)
			.forAccount(aMinor)
			.forHolder(holders[0])
			.forOpportunity(anOpportunity)
			.build();
		insert aMinorRecipient;

		anAccount.Fecha_de_nacimiento__c = birthdateOfAnAdult;
		update anAccount;

		// The coverage with the specific discount applied
		Id coverageId = coverages[0].Id;
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();

		Test.startTest();

		// Activate relation to coverage for all recipients
		activateRelationsForAllRecipients(controller, coverageId);

		// Apply the minor for the special discount
		AsignacionDeBeneficiosController.CoverageRecipientWrapper wrapper = controller.RelationsByCoverageByRecipient.get(aMinorRecipient.Id).get(coverageId);
		wrapper.Discounts[0].isActive = true;
		
		PageReference nextPage = controller.save();

		Test.stopTest();
		
		System.assert(!controller.InvalidDiscounts);
		
		List<Cobertura_de_Beneficiario__c> coverageRecipientRelations = [
			SELECT Id, Beneficiario__c, Cobertura__c,
				(SELECT Id, Descuento_recargo_aplicado__c FROM Aplicantes__r)
			FROM Cobertura_de_Beneficiario__c
		];
		
		System.assertEquals(3, coverageRecipientRelations.size());
		
		for(Cobertura_de_Beneficiario__c recipientCoverage : coverageRecipientRelations) {
			if (recipientCoverage.Beneficiario__c == aMinorRecipient.Id) {
				System.assertEquals(1, recipientCoverage.Aplicantes__r.size());
				System.assertEquals(appliedDiscounts[0].Id, recipientCoverage.Aplicantes__r[0].Descuento_recargo_aplicado__c);
			} else {
				System.assertEquals(0, recipientCoverage.Aplicantes__r.size());
			}
		}
	}

	private static testMethod void whenSavingAnActiveApplicantToASpecificDiscount_ThereShouldBeTwoPersonsForEachMinorSelectedInTheCoverage() {
		
		// Build a minor recipient
		Account aMinor = Build.anAccount().isPersonAccount().withBirthdate(birthdateOfAMinor).build();
		insert aMinor;
		Beneficiario__c aMinorRecipient = Build.aRecipient()
			.forContract(aContract)
			.forAccount(aMinor)
			.forHolder(holders[0])
			.forOpportunity(anOpportunity)
			.build();
		insert aMinorRecipient;

		// The coverage with the specific discount applied
		Id coverageId = coverages[0].Id;
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();

		Test.startTest();
		// Apply the minor for the special discount
		AsignacionDeBeneficiosController.CoverageRecipientWrapper wrapper = controller.RelationsByCoverageByRecipient.get(aMinorRecipient.Id).get(coverageId);
		wrapper.IsActive = true;
		wrapper.Discounts[0].isActive = true;
		
		PageReference nextPage = controller.save();
		Test.stopTest();
		
		System.assert(controller.InvalidDiscounts);
		System.assertEquals(null, nextPage);
		
		List<Cobertura_de_Beneficiario__c> coverageRecipientRelations = [
			SELECT Id, Beneficiario__c, Cobertura__c
			FROM Cobertura_de_Beneficiario__c
		];
		
		System.assertEquals(0, coverageRecipientRelations.size());
	}
	
	private static testMethod void ifAnExistingRelationIsDeactivated_TheRelationShouldBeDeleted() {
		Cobertura_de_Beneficiario__c aCoverageRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(recipients[0]).forCoverage(coverages[1]).build();
		insert aCoverageRecipientRelation;
		Id recipientId = aCoverageRecipientRelation.Beneficiario__c;
		Id coverageId = aCoverageRecipientRelation.Cobertura__c;
		
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		activateRelationsForAllRecipients(controller, coverages[0].Id);
		//Remove the created relation
		controller.RelationsByCoverageByRecipient.get(recipientId).get(coverageId).IsActive = false;
		
		controller.save();
		
		List<Cobertura_de_Beneficiario__c> coverageRecipientRelations = [
			SELECT Id, Beneficiario__c, Cobertura__c
			FROM Cobertura_de_Beneficiario__c
			WHERE Id = :aCoverageRecipientRelation.Id
		];
		
		System.assertEquals(0, coverageRecipientRelations.size());
	}
	
	private static testMethod void ifAnExistingRelationIsDeactivatedWithDiscountsApplied_TheRelationAndTheApplicantsShouldBeDeleted() {
		Account minorAccount = Build.anAccount().isPersonAccount().withBirthdate(birthdateOfAMinor).build();
		insert minorAccount;
		recipients[0].Beneficiario__c = minorAccount.Id;
		update recipients[0];
		
		Cobertura_de_Beneficiario__c aCoverageRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(recipients[0])
			.forCoverage(coverages[0])
			.build();
		insert aCoverageRecipientRelation;

		Aplicante__c anApplicant = Build.anApplicant()
			.forAppliedDiscount(appliedDiscounts[0])
			.forRecipientCoverage(aCoverageRecipientRelation)
			.build();
		insert anApplicant;

		Id recipientId = aCoverageRecipientRelation.Beneficiario__c;
		Id coverageId = aCoverageRecipientRelation.Cobertura__c;
		
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();

		Test.startTest();

		activateRelationsForAllRecipients(controller, coverages[1].Id);

		//Remove the created relation
		controller.RelationsByCoverageByRecipient.get(recipientId).get(coverageId).IsActive = false;
		
		controller.save();

		Test.stopTest();

		List<Cobertura_de_Beneficiario__c> coverageRecipientRelations = [
			SELECT Id, Beneficiario__c, Cobertura__c
			FROM Cobertura_de_Beneficiario__c
			WHERE Id = :aCoverageRecipientRelation.Id
		];
		
		List<Aplicante__c> applicants = [
			SELECT Id
			FROM Aplicante__c
			WHERE Cobertura__c = :aCoverageRecipientRelation.Id
		];

		System.assertEquals(0, coverageRecipientRelations.size(), coverageRecipientRelations);
		System.assertEquals(0, applicants.size());
	}

	private static testMethod void itShouldBePosibleToRemoveARecipient() {
		Id recipientToRemove = recipients[0].Id;
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		controller.RecipientToRemove = recipientToRemove;
		controller.removeRecipient();
		
		List<Beneficiario__c> recipientInDb = [
			SELECT Id
			FROM Beneficiario__c
			WHERE Id = :recipientToRemove
		];
		
		System.assertEquals(0, recipientInDb.size());
		System.assertEquals(recipients.size() - 1, controller.Recipients.size());
		System.assertEquals(recipients.size() - 1, controller.RelationsByCoverageByRecipient.size());
	}

	private static testMethod void ifTheRemovedRecipientHadAppliedToADiscountItShouldBeDeletedToo() {
		
		// Existing coverage and discount of recipient
		Cobertura_de_Beneficiario__c aCoverageRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(recipients[0])
			.forCoverage(coverages[0])
			.build();
		insert aCoverageRecipientRelation;

		Aplicante__c anApplicant = Build.anApplicant()
			.forAppliedDiscount(appliedDiscounts[0])
			.forRecipientCoverage(aCoverageRecipientRelation)
			.build();
		insert anApplicant;

		Id recipientToRemove = recipients[0].Id;
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		controller.RecipientToRemove = recipientToRemove;
		controller.removeRecipient();
		
		List<Beneficiario__c> recipientInDb = [
			SELECT Id
			FROM Beneficiario__c
			WHERE Id = :recipientToRemove
		];

		List<Cobertura_de_Beneficiario__c> recipientCoveragesInDb = [
			SELECT Id, Beneficiario__c, Cobertura__c
			FROM Cobertura_de_Beneficiario__c
			WHERE Beneficiario__c = :recipientToRemove
		];
		
		List<Aplicante__c> applicantsInDb = [
			SELECT Id
			FROM Aplicante__c
			WHERE Cobertura__c = :aCoverageRecipientRelation.Id
		];
		
		System.assertEquals(0, recipientInDb.size());
		System.assertEquals(0, recipientCoveragesInDb.size());
		System.assertEquals(0, applicantsInDb.size());
		System.assertEquals(recipients.size() - 1, controller.Recipients.size());
		System.assertEquals(recipients.size() - 1, controller.RelationsByCoverageByRecipient.size());
	}
	
	private static testMethod void ifARecipientHasNoBenefitsWhenSavingItShouldNotSave_NotRedirectToTheContractAndAFlagShouldBeActive() {
		Id coverageId = coverages[0].Id;
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		activateRelationsForAllRecipients(controller, coverageId);
		//make sure one has no coverage.
		controller.RelationsByCoverageByRecipient.get(recipients[0].Id).get(coverageId).IsActive = false;
		
		PageReference nextPage = controller.save();
		
		System.assertEquals(true, controller.EmptyRecipients);
		
		System.assertEquals(null, nextPage);
		
		List<Cobertura_de_Beneficiario__c> coverageRecipientRelations = [
			SELECT Id, Beneficiario__c, Cobertura__c
			FROM Cobertura_de_Beneficiario__c
		];
		
		System.assertEquals(0, coverageRecipientRelations.size());
	}
	
	private static testMethod void ifTheOpportunityIdIsPassedAsAParameterTheReturnAddressShouldBeTheOpportunityPage() {
		ApexPages.currentPage().getParameters().put('opp', anOpportunity.Id);
		
		Id coverageId = coverages[0].Id;
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		activateRelationsForAllRecipients(controller, coverageId);
		
		PageReference nextPage = controller.save();
		
		System.assertEquals(controller.ReturnRecord, anOpportunity.Id);
		System.assertEquals('/' + anOpportunity.Id, nextPage.getUrl());
	}
	
	private static testMethod void itShouldBePosibleToSpecifyAReturnRecordAsParameter() {
		ApexPages.currentPage().getParameters().put('retId', anAccount.Id);
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		System.assertEquals(anAccount.Id, controller.ReturnRecord);
		
		activateRelationsForAllRecipients(controller, coverages[0].Id);
		PageReference nextPage = controller.save();
		
		System.assertEquals('/' + anAccount.Id, nextPage.getUrl());
	}
	
	// ==========================================================================
	// Applicants
	private static testMethod void itShouldBePossibleToObtainIfARecipientIsAnAdultByItsBirthDate() {
		Account anAdult = Build.anAccount().isPersonAccount().withBirthdate(birthdateOfAnAdult).build();
		Account aChild = Build.anAccount().isPersonAccount().withBirthdate(birthdateOfAMinor).build();
		insert new List<Account> {anAdult, aChild};
		
		Beneficiario__c anAdultRecipient = recipients[0];
		Beneficiario__c aChildRecipient = recipients[1];
		anAdultRecipient.Beneficiario__c = anAdult.Id;
		aChildRecipient.Beneficiario__c = aChild.Id;
		update recipients;
		
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		System.assertEquals(
			true,
			controller.RelationsByCoverageByRecipient.get(anAdultRecipient.Id).values()[0].IsAnAdult
		);
		
		System.assertEquals(
			false,
			controller.RelationsByCoverageByRecipient.get(aChildRecipient.Id).values()[0].IsAnAdult
		);
	}
	
	private static testMethod void createdApplicationsShouldHaveAnEndDateDependingOnTheMinorsBirthdate() {
		Account aChild = Build.anAccount().isPersonAccount().withBirthdate(birthdateOfAMinor).build();
		Account anotherChild = Build.anAccount().isPersonAccount().withBirthdate(birthdateOfAMinor.addYears(1)).build();
		insert new List<Account> {aChild, anotherChild};
		
		Beneficiario__c aChildRecipient = recipients[0];
		Beneficiario__c anotherChildRecipient = recipients[1];
		aChildRecipient.Beneficiario__c = aChild.Id;
		anotherChildRecipient.Beneficiario__c = anotherChild.Id;
		update recipients;
		
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		System.assertEquals(
			aChild.Fecha_de_nacimiento__c.addYears(13),
			controller.RelationsByCoverageByRecipient.get(aChildRecipient.Id)
				.get(coverages[0].Id).Discounts[0].Relation.Fin_Vigencia__c
		);
		
		System.assertEquals(
			anotherChild.Fecha_de_nacimiento__c.addYears(13),
			controller.RelationsByCoverageByRecipient.get(anotherChildRecipient.Id)
				.get(coverages[0].Id).Discounts[0].Relation.Fin_Vigencia__c
		);
	}
	
	// ==========================================================================
	// "Created in" fields
	private static testMethod void whenTheReturnRecordIsAnOpportunityNewRecipientCoveragesShouldPointToIt() {
		ApexPages.currentPage().getParameters().put('opp', anOpportunity.Id);
		
		Id coverageId = coverages[0].Id;
		
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		activateRelationsForAllRecipients(controller, coverageId);
		controller.save();
		
		Cobertura_de_Beneficiario__c createdRelation = [
			SELECT Id, Creado_en_Oportunidad__c
			FROM Cobertura_de_Beneficiario__c
			WHERE Cobertura__c = :coverageId
			LIMIT 1
		];
		
		System.assertEquals(anOpportunity.Id, createdRelation.Creado_en_Oportunidad__c);
	}
	
	private static testMethod void whenTheReturnRecordIsACaseNewRecipientCoveragesShouldPointToIt() {
		ApexPages.currentPage().getParameters().put('retId', aCase.Id);
		
		Id coverageId = coverages[0].Id;
		
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		activateRelationsForAllRecipients(controller, coverageId);
		controller.save();
		
		Cobertura_de_Beneficiario__c createdRelation = [
			SELECT Id, Creado_en_Caso__c
			FROM Cobertura_de_Beneficiario__c
			WHERE Cobertura__c = :coverageId
			LIMIT 1
		];
		
		System.assertEquals(aCase.Id, createdRelation.Creado_en_Caso__c);
	}
	
	// ==========================================================================
	// Addition Cases
	private static testMethod void whenACaseThatMakesAdditionsIsPassedAsTheReturnParameterNewRecipientCoveragesShouldBeMarkedForTheCase() {
		ApexPages.currentPage().getParameters().put('retId', aCase.Id);
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		controller.NewRecipient.Provincia1__c = 'Capital Federal';
		
		System.assertEquals(true, controller.ForAdditionCase);
		
		activateRelationsForAllRecipients(controller, coverages[0].Id);
		controller.save();
		
		List<Cobertura_de_Beneficiario__c> coverageRecipientRelations = [
			SELECT Id, Beneficiario__c, Caso__c
			FROM Cobertura_de_Beneficiario__c
		];
		
		System.assertEquals(recipients.size(), coverageRecipientRelations.size());
		System.assertEquals(aCase.Id, coverageRecipientRelations[0].Caso__c);
	}
	
	private static testMethod void whenInCaseAdditionModeARecipientIsCreated_ItShouldHaveItsCaseFieldFilled() {
		Account recipientAccount = Build.anAccount().isPersonAccount()
			.withLastName('Test').withFirstName('man').withCUILCUIT('45678687687').build();
		insert recipientAccount;
		RecordType personRecipientType = [
			SELECT Id, Name, DeveloperName
			FROM RecordType
			WHERE sObjectType = 'Beneficiario__c'
				AND IsActive = true
				AND DeveloperName = 'Persona'
		];
		
		ApexPages.currentPage().getParameters().put('retId', aCase.Id);
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		controller.NewAccount.CUIL_CUIT__c = recipientAccount.CUIL_CUIT__c;
		controller.NewAccount.Phone = '676567823423';
		controller.AccFirstName = 'Test';
		controller.AccLastName = 'Man';
		controller.NewRecipient.RecordTypeId = personRecipientType.Id;
		controller.NewRecipient.Provincia1__c = Beneficiario__c.Provincia1__c
			.getDescribe().getPicklistValues()[0].getValue();
		controller.NewRecipient.Titular__c = holders[0].Id;
		controller.createRecipient();
		
		List<Beneficiario__c> newRecipients = [
			SELECT Id, Caso__c
			FROM Beneficiario__c
			WHERE Caso__c = :aCase.Id
		];
		
		System.assertEquals(1, newRecipients.size());
	}
	
	// ==========================================================================
	// Amounts for Address recipients
	@isTest
	private static void whenARelationForAnAddressRecipientHasItsAmountsChanged_TheRelationShouldBeMarkedAsActive() {
		RecordType addressRt = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Domicilio'
				AND sObjectType = 'Beneficiario__c'
				AND IsActive = true
			LIMIT 1
		];
		delete recipients;//I need just an address recipient for this test
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract)
			.forAccount(anAccount).forHolder(holders[0]).forOpportunity(anOpportunity)
			.withRecordType(addressRt).build();
		insert aRecipient;
		
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		controller.RelationsByCoverageByRecipient.get(aRecipient.Id)
			.get(coverages[0].Id).AmountDetail.Cantidad__c = 1;
		
		System.assertEquals(
			true,
			controller.RelationsByCoverageByRecipient.get(aRecipient.Id)
				.get(coverages[0].Id).IsActive
		);
	}
	
	@isTest
	private static void whenARelationForAnAddressRecipientHasItsInTransitAmountsChanged_TheRelationShouldBeMarkedAsActive() {
		RecordType addressRt = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Domicilio'
				AND sObjectType = 'Beneficiario__c'
				AND IsActive = true
			LIMIT 1
		];
		delete recipients;//I need just an address recipient for this test
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract)
			.forAccount(anAccount).forHolder(holders[0]).forOpportunity(anOpportunity)
			.withRecordType(addressRt).build();
		insert aRecipient;
		
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		controller.RelationsByCoverageByRecipient.get(aRecipient.Id)
			.get(coverages[0].Id).AmountDetail.Cantidad_en_transito__c = 1;
		
		System.assertEquals(
			true,
			controller.RelationsByCoverageByRecipient.get(aRecipient.Id)
				.get(coverages[0].Id).IsActive
		);
	}
	
	@isTest
	private static void whenARelationForAnAddressRecipientHasItsAmountsAsZero_TheRelationShouldBeMarkedAsNotActive() {
		RecordType addressRt = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Domicilio'
				AND sObjectType = 'Beneficiario__c'
				AND IsActive = true
			LIMIT 1
		];
		delete recipients;//I need just an address recipient for this test
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract)
			.forAccount(anAccount).forHolder(holders[0]).forOpportunity(anOpportunity)
			.withRecordType(addressRt).build();
		insert aRecipient;
		
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		controller.RelationsByCoverageByRecipient.get(aRecipient.Id)
			.get(coverages[0].Id).IsActive = true;
			
		controller.RelationsByCoverageByRecipient.get(aRecipient.Id)
			.get(coverages[0].Id).AmountDetail.Cantidad__c = 0;
		controller.RelationsByCoverageByRecipient.get(aRecipient.Id)
			.get(coverages[0].Id).AmountDetail.Cantidad_en_transito__c = 0;
		
		System.assertEquals(
			false,
			controller.RelationsByCoverageByRecipient.get(aRecipient.Id)
				.get(coverages[0].Id).IsActive
		);
	}
	
	@isTest
	private static void whenLoadingARelationForAnAddressRecipient_TheAmountsShouldBeObtained() {
		RecordType addressRt = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Domicilio'
				AND sObjectType = 'Beneficiario__c'
				AND IsActive = true
			LIMIT 1
		];
		delete recipients;//I need just an address recipient for this test
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract)
			.forAccount(anAccount).forHolder(holders[0]).forOpportunity(anOpportunity)
			.withRecordType(addressRt).build();
		insert aRecipient;
		
		Cobertura_de_Beneficiario__c aCoverageRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(coverages[0])
			.withDirectionAmount(0).withDirectionTransitAmount(1).build();
		insert aCoverageRecipientRelation;
		Cantidad_de_producto_de_beneficiaro__c anAmountDetail = Build.anAmountDetail()
			.forRecipientCoverageRelation(aCoverageRecipientRelation)
			.withAmount(3).withTransitAmount(2).forOpportunity(anOpportunity)
			.build();
		insert anAmountDetail;
		
		ApexPages.currentPage().getParameters().put('opp', anOpportunity.Id);
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		System.assertEquals(
			true,
			controller
				.RelationsByCoverageByRecipient
					.get(aCoverageRecipientRelation.Beneficiario__c)
					.get(aCoverageRecipientRelation.Cobertura__c)
						.IsActive
		);
		
		Cantidad_de_producto_de_beneficiaro__c amountDetailInController = controller
			.RelationsByCoverageByRecipient
				.get(aCoverageRecipientRelation.Beneficiario__c)
				.get(aCoverageRecipientRelation.Cobertura__c).amountDetail;
		
		System.assertEquals(
			anAmountDetail.Id,
			amountDetailInController.Id
		);
		
		System.assertEquals(
			anAmountDetail.Cantidad__c,
			amountDetailInController.Cantidad__c
		);
		System.assertEquals(
			anAmountDetail.Cantidad_en_transito__c,
			amountDetailInController.Cantidad_en_transito__c
		);
	}
	
	@isTest
	private static void itShouldBePosibleToUpdateARelationForAnAddressRecipient() {
		RecordType addressRt = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Domicilio'
				AND sObjectType = 'Beneficiario__c'
				AND IsActive = true
			LIMIT 1
		];
		delete recipients;//I need just an address recipient for this test
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract)
			.forAccount(anAccount).forHolder(holders[0]).forOpportunity(anOpportunity)
			.withRecordType(addressRt).build();
		insert aRecipient;
		
		Cobertura_de_Beneficiario__c aCoverageRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(coverages[0])
			.withDirectionAmount(0).withDirectionTransitAmount(1).build();
		insert aCoverageRecipientRelation;
		Cantidad_de_producto_de_beneficiaro__c anAmountDetail = Build.anAmountDetail()
			.forRecipientCoverageRelation(aCoverageRecipientRelation)
			.withAmount(3).withTransitAmount(2).forOpportunity(anOpportunity)
			.build();
		insert anAmountDetail;
		
		ApexPages.currentPage().getParameters().put('opp', anOpportunity.Id);
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		controller.RelationsByCoverageByRecipient.get(aRecipient.Id)
			.get(coverages[0].Id).amountDetail.Cantidad__c = 5;
		controller.RelationsByCoverageByRecipient.get(aRecipient.Id)
			.get(coverages[0].Id).amountDetail.Cantidad_en_transito__c = 4;
		
		Cantidad_de_producto_de_beneficiaro__c amountDetailInController =
			controller.RelationsByCoverageByRecipient.get(aRecipient.Id)
				.get(coverages[0].Id).amountDetail;
		
		controller.save();
		
		Cantidad_de_producto_de_beneficiaro__c amountDetailInDb = [
			SELECT Cantidad__c, Cantidad_en_transito__c
			FROM Cantidad_de_producto_de_beneficiaro__c
			WHERE Id = :anAmountDetail.Id
		];
		
		System.assertEquals(
			amountDetailInController.Cantidad__c,
			amountDetailInDb.Cantidad__c
		);
		System.assertEquals(
			amountDetailInController.Cantidad_en_transito__c,
			amountDetailInDb.Cantidad_en_transito__c
		);
	}
	
	@isTest
	private static void whenTheAmountDetailForAnAddressRecipientIsAlreadyActive_ChangesShouldBeSavedToANewDetail() {
		RecordType addressRt = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Domicilio'
				AND sObjectType = 'Beneficiario__c'
				AND IsActive = true
			LIMIT 1
		];
		delete recipients;//I need just an address recipient for this test
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract)
			.forAccount(anAccount).forHolder(holders[0]).forOpportunity(anOpportunity)
			.withRecordType(addressRt).build();
		insert aRecipient;
		
		Cobertura_de_Beneficiario__c aCoverageRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(coverages[0])
			.withDirectionAmount(0).withDirectionTransitAmount(1).build();
		insert aCoverageRecipientRelation;
		Cantidad_de_producto_de_beneficiaro__c anAmountDetail = Build.anAmountDetail()
			.forRecipientCoverageRelation(aCoverageRecipientRelation)
			.withAmount(3).withTransitAmount(2).isActive().build();
		insert anAmountDetail;
		
		ApexPages.currentPage().getParameters().put('opp', anOpportunity.Id);
		AsignacionDeBeneficiosController controller = new AsignacionDeBeneficiosController();
		
		controller.RelationsByCoverageByRecipient.get(aRecipient.Id)
			.get(coverages[0].Id).amountDetail.Cantidad__c = 5;
		controller.RelationsByCoverageByRecipient.get(aRecipient.Id)
			.get(coverages[0].Id).amountDetail.Cantidad_en_transito__c = 4;
		
		Cantidad_de_producto_de_beneficiaro__c amountDetailInController =
			controller.RelationsByCoverageByRecipient.get(aRecipient.Id)
				.get(coverages[0].Id).amountDetail;
		
		controller.save();
		
		Cantidad_de_producto_de_beneficiaro__c amountDetailInDb = [
			SELECT Cantidad__c, Cantidad_en_transito__c
			FROM Cantidad_de_producto_de_beneficiaro__c
			WHERE Id != :anAmountDetail.Id
				AND Cobertura_de_Beneficiario__c = :aCoverageRecipientRelation.Id
		];
		
		System.assertEquals(
			amountDetailInController.Cantidad__c,
			amountDetailInDb.Cantidad__c
		);
		System.assertEquals(
			amountDetailInController.Cantidad_en_transito__c,
			amountDetailInDb.Cantidad_en_transito__c
		);
		
		Cantidad_de_producto_de_beneficiaro__c oldAmountDetailInDb = [
			SELECT Cantidad__c, Cantidad_en_transito__c
			FROM Cantidad_de_producto_de_beneficiaro__c
			WHERE Id = :anAmountDetail.Id
		];
		
		System.assertEquals(
			anAmountDetail.Cantidad__c,
			oldAmountDetailInDb.Cantidad__c
		);
		System.assertEquals(
			anAmountDetail.Cantidad_en_transito__c,
			oldAmountDetailInDb.Cantidad_en_transito__c
		);
	}
	
	// ==========================================================================
	private static void activateRelationsForAllRecipients(AsignacionDeBeneficiosController controller, Id coverageId) {
		for(Id recipientId : controller.RelationsByCoverageByRecipient.keySet()) {
			//Set an active coverage for each recipient
			controller.RelationsByCoverageByRecipient.get(recipientId).get(coverageId).IsActive = true;
		}
	}
	
	// ==========================================================================
	static Account anAccount;
	static Contrato__c aContract;
	static Opportunity anOpportunity;
	static List<Beneficiario__c> recipients;
	static List<Product2> products;
	static List<Cobertura__c> coverages;
	static List<Titular__c> holders;
	static List<Descuento_Recargo__c> discounts;
	static List<Descuento_Recargo_Aplicado__c> appliedDiscounts;
	static Date birthdateOfAMinor = Date.today().addYears(-12), birthdateOfAnAdult = Date.today().addYears(-13);
	static Case aCase;
	
	static {
		Id opportunityType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Opportunity'
				AND IsActive = true
				AND DeveloperName = 'Venta_Consumidor_Final'
			LIMIT 1
		].Id;
		anAccount = Build.anAccount().isPersonAccount().build();
		insert anAccount;
		anOpportunity = Build.anOpportunity().forAccount(anAccount)
			.withDischargeTypeNew().withRecordTypeId(opportunityType).build();
		insert anOpportunity;
		aContract = [
			SELECT Id
			FROM Contrato__c
			WHERE Id IN (SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		];
		
		holders = [
			SELECT Id
			FROM Titular__c
			WHERE Contrato__c = :aContract.Id
		];
		recipients = new List<Beneficiario__c> {
			Build.aRecipient().forContract(aContract).forAccount(anAccount).forHolder(holders[0]).forOpportunity(anOpportunity).build(),
			Build.aRecipient().forContract(aContract).forAccount(anAccount).forHolder(holders[0]).forOpportunity(anOpportunity).build()
		};
		insert recipients;
		
		products = new List<Product2> {
			Build.aProduct().withName('Prod 1').build(),
			Build.aProduct().withName('Prod 2').build()
		};
		insert products;
		
		discounts = new List<Descuento_Recargo__c> {
			Build.aDiscount().withDiscountCode('ZDV1').build(),
			Build.aDiscount().withDiscountCode('OtherCode').build()
		};
		insert discounts;

		coverages = new List<Cobertura__c> {
			Build.aCoverage().forContract(aContract).forProduct(products[0]).build(),
			Build.aCoverage().forContract(aContract).forProduct(products[1]).build()
		};
		insert coverages;
		
		appliedDiscounts = new List<Descuento_Recargo_Aplicado__c> {
			Build.anAppliedDiscount().forCoverage(coverages[0]).forDiscount(discounts[0]).build(),
			Build.anAppliedDiscount().forCoverage(coverages[0]).forDiscount(discounts[1]).build(),
			Build.anAppliedDiscount().forCoverage(coverages[1]).forDiscount(discounts[1]).build()
		};
		insert appliedDiscounts;

		Test.setCurrentPage(new PageReference('Page.AsignacionDeBeneficios'));
		ApexPages.currentPage().getParameters().put('Id', aContract.Id);
		//============================================
		//interference
		Contrato__c anotherContract = Build.aContract().forAccount(anAccount).build();
		insert anotherContract;
		Titular__c aHolder = Build.aHolder().forAccount(anAccount).forContract(anotherContract).forOpportunity(anOpportunity).build();
		insert aHolder;
		List<Beneficiario__c> otherRecipients = new List<Beneficiario__c> {
			Build.aRecipient().forContract(anotherContract).forHolder(aHolder).forAccount(anAccount).build(),
			Build.aRecipient().forContract(anotherContract).forHolder(aHolder).forAccount(anAccount).build()
		};
		insert otherRecipients;
		
		//============================================
		RecordType caseRecordType = [
			SELECT Id, DeveloperName
			FROM RecordType
			WHERE SObjectType = 'Case'
				AND DeveloperName = 'Cambio_de_Cobertura'
			LIMIT 1
		];
		
		Casos_Beneficiarios_Descuentos__c additionSettings = Build.someAdditionCaseSettings()
			.forCaseRecordType(caseRecordType).withCloseReasonCorrect('Procesado')
			.withCloseReasonIncorrect('Rechazado').build();
		insert additionSettings;
		
		aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
		insert aCase;
	}
}
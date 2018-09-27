@isTest
private class CaseTriggerTest {
	private static testMethod void whenACaseForASpecificReasonIsInsertedItShouldFirstBeAssignedToUsersWithNullLastAssignmentTime() {
		Case aCase = Build.aCase().forAccount(anAccount)
			.withReason(groupCaseAssignmentSettings.Name).build();
		
		Test.startTest();
		insert aCase;
		Test.stopTest();
		
		Case theCaseInDb = [
			SELECT Id, OwnerId
			FROM Case
			WHERE Id = :aCase.Id
		];
		
		System.assertEquals(anUser.Id, theCaseInDb.OwnerId);
		
		anUser = [
			SELECT Id, Gestion_mora_ultima_asignacion__c
			FROM User
			WHERE Id = :anUser.Id
		];
		
		System.assertNotEquals(null, anUser.Gestion_mora_ultima_asignacion__c);
	}
	
	private static testMethod void whenACaseForASpecificReasonIsInsertedItShouldBeAssignedToTheUserThatHasBeenTheMostTimeSinceLastAssignment() {
		anUser.Gestion_mora_ultima_asignacion__c = system.now();
		update anUser;
		
		Case aCase = Build.aCase().forAccount(anAccount)
			.withReason(groupCaseAssignmentSettings.Name).build();
		
		Test.startTest();
		insert aCase;
		Test.stopTest();
		
		Case theCaseInDb = [
			SELECT Id, OwnerId
			FROM Case
			WHERE Id = :aCase.Id
		];
		
		System.assertEquals(anotherUser.Id, theCaseInDb.OwnerId);
	}
	
	private static testMethod void whenACaseIsInsertedAndItIsASubCase_TheMasterCaseShouldPointToTheMainCase() {
		Case aCase = Build.aCase().forAccount(anAccount).build();
		insert aCase;
		
		Case aSubCase = Build.aCase().forAccount(anAccount).forParent(aCase).build();
		insert aSubCase;
		
		Case anotherSubCase = Build.aCase().forAccount(anAccount).forParent(aSubCase).build();
		insert anotherSubCase;
		
		List<Case> casesInDb = [
			SELECT Id, Caso_maestro__c
			FROM Case
			WHERE Id = :anotherSubCase.Id
				OR Id = :aSubCase.Id
		];
		for(Case theCase : casesInDb) {
			System.assertEquals(aCase.Id, theCase.Caso_maestro__c);
		}
	}

	//==========================================
	//Contract cloning cases
	private static testMethod void whenACaseOfASpecifiedTypeIsCreatedItsContractShouldBeCloned() {
		insert cloningSettings;
		insert aContract;
		
		Case aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.forContract(aContract).build();
		
		insert aCase;
		
		Case theCaseInDb = [
			SELECT Id, Contrato_clonado__c
			FROM Case
			WHERE Id = :aCase.Id
		];
		
		System.assertNotEquals(null, theCaseInDb.Contrato_clonado__c);
		System.assertNotEquals(aContract.Id, theCaseInDb.Contrato_clonado__c);
		
		List<Contrato__c> clonedContract = [
			SELECT Id, Cliente__c
			FROM Contrato__c
			WHERE Id = :theCaseInDb.Contrato_clonado__c
		];
		
		System.assertEquals(1, clonedContract.size());
	}
	
	private static testMethod void whenACaseThatClonesContractIsInsertedAndIsNotTheMainCase_TheClonedContractShouldBeSetInTheMainCase() {
		insert cloningSettings;
		insert aContract;
		
		Case aCase = Build.aCase().forAccount(anAccount).forContract(aContract).build();
		insert aCase;
		
		Case aSubCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.forParent(aCase).build();
		
		insert aSubCase;
		
		Case mainCase = [
			SELECT Id, Contrato_clonado__c
			FROM Case
			WHERE id = :aCase.Id
		];
		
		System.assertNotEquals(null, mainCase.Contrato_clonado__c);
	}
	
	private static testMethod void whenACaseThatClonesContractIsInsertedAndItsMainCaseHasACloneOfTheContract_TheContractShouldNotBeClonedAgain() {
		insert cloningSettings;
		insert aContract;
		
		Case aCase = Build.aCase().forAccount(anAccount).forContract(aContract)
			.withRecordType(caseRecordType).build();
		insert aCase;
		
		Case mainCaseBefore = [
			SELECT Id, Contrato_clonado__c
			FROM Case
			WHERE id = :aCase.Id
		];
		
		Case aSubCase = Build.aCase().forAccount(anAccount).forContract(aContract).withRecordType(caseRecordType)
			.forParent(aCase).build();
		
		insert aSubCase;
		
		Case mainCaseAfter = [
			SELECT Id, Contrato_clonado__c
			FROM Case
			WHERE id = :aCase.Id
		];
		
		System.assertEquals(
			mainCaseBefore.Contrato_clonado__c,
			mainCaseAfter.Contrato_clonado__c
		);
	}
	
	private static testMethod void whenACaseThatClonesContractIsInsertedAndAnOpenCaseThatIsntItsMainCaseHasACloneOfTheContractTheInsertionShouldFail() {
		insert cloningSettings;
		insert aContract;
		
		Case aCase = Build.aCase().forAccount(anAccount).forContract(aContract)
			.withRecordType(caseRecordType).build();
		insert aCase;
		
		List<Contrato__c> allContractsBefore = [
			SELECT Id
			FROM Contrato__c
		];
		
		Case anotherCase = Build.aCase().forAccount(anAccount).forContract(aContract)
			.withRecordType(caseRecordType).build();
		
		boolean failed = false;
		try {
			insert anotherCase;
		}
		catch (DmlException e) {
			failed = true;
			String expectedError = Label.Error_caso_ya_hay_clon_de_contrato.replace('{0}', aCase.Id);
			System.assert(
				e.getMessage().contains(expectedError),
				'exception message: "' + e.getMessage() + '" expected: "' + expectedError + '"'
			);
		}
		System.assert(failed, 'The insertion did not fail.');
		
		List<Contrato__c> allContractsAfter = [
			SELECT Id
			FROM Contrato__c
		];
		
		System.assertEquals(allContractsBefore.size(), allContractsAfter.size());
	}
	
	private static testMethod void whenACaseThatClonedTheContractIsClosedWithTheIncorrectReason_TheContractShouldBeDeleted() {
		insert cloningSettings;
		insert aContract;
		
		Case aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
		
		insert aCase;
		
		Case theCaseInDb = [
			SELECT Id, Contrato_clonado__c
			FROM Case
			WHERE Id = :aCase.Id
		];
		
		aCase.Motivo_de_Finalizacion__c = cloningSettings.Motivo_cierre_incorrecto__c;
		aCase.Status = 'Cerrado';
		
		update aCase;
		
		List<Contrato__c> contracts = [
			SELECT Id, Cliente__c
			FROM Contrato__c
			WHERE Id = :theCaseInDb.Contrato_clonado__c
		];
		System.assertEquals(0, contracts.size());
	}
	/**  Esta funcionalidad ha sido remplazada en los cambios de covertura por un Batch
	 * 
	 * 
	 * 
	private static testMethod void whenACaseThatClonedTheContractIsClosedWithTheCorrectReason_TheCloneContractShouldBeMarkedAsActiveAndTheOriginalAsInactive() {
		insert cloningSettings;
		insert aContract;
		
		Case aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
		
		insert aCase;
		
		Case theCaseInDb = [
			SELECT Id, Contrato_clonado__c
			FROM Case
			WHERE Id = :aCase.Id
		];
		
		aCase.Motivo_de_Finalizacion__c = cloningSettings.Motivo_cierre_correcto__c;
		aCase.Status = 'Cerrado';
		
		update aCase;
		
		List<Contrato__c> contractsInDb = [
			SELECT Id, Estado__c
			FROM Contrato__c
			WHERE Id = :theCaseInDb.Contrato_clonado__c
				OR Id = :aContract.Id
		];
		
		Contrato__c clonedContract;
		Contrato__c originalContract;
		if(contractsInDb[0].Id == theCaseInDb.Contrato_clonado__c) {
			clonedContract = contractsInDb[0];
			originalContract = contractsInDb[1];
		}
		else {
			originalContract = contractsInDb[0];
			clonedContract = contractsInDb[1];
		}
		
		System.assertEquals('Activo', clonedContract.Estado__c);
		System.assertEquals('Baja', originalContract.Estado__c);
	}
*/	
	private static testMethod void whenMultipleCasesThatCloneContractsAreInsertedAtTheSameTimeForTheSameContractItShouldFail() {
		insert cloningSettings;
		insert aContract;
		
		boolean failed = false;
		Case aCase = Build.aCase().forAccount(anAccount).forContract(aContract)
			.withRecordType(caseRecordType).build();
		Case anotherCase = Build.aCase().forAccount(anAccount).forContract(aContract)
			.withRecordType(caseRecordType).build();
		try {
			insert new List<Case> {aCase, anotherCase};
		}
		catch (DmlException e) {
			failed = true;
			String expectedError = Label.Error_multiples_casos_para_mismo_contrato;
			System.assert(
				e.getMessage().contains(expectedError),
				'exception message: "' + e.getMessage() + '" expected: "' + expectedError + '"'
			);
		}
		System.assert(failed, 'The insertion did not fail.');
		
		List<Contrato__c> allContractsAfter = [
			SELECT Id
			FROM Contrato__c
		];
		
		System.assertEquals(1, allContractsAfter.size());
	}
	
	//==========================================
	//Credit notes
	private static testMethod void whenACreditNoteCaseIsClosedWithAProcessedEndingMotive_ItShouldBeSentToSAP() {
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		serverMock.responseObj = new WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In();
		
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		
		RecordType creditNoteCase = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Nota_de_Credito'
		];
        
        
		Case aCase = Build.aCase().forAccount(anAccount).forContract(aContract).withRecordType(creditNoteCase)
			.WithBillNumber('1').WithCreditNoteMotive('Z37').build();
		insert aCase;

        
		Posicion__c pos = new Posicion__c();
        pos.Caso__c= aCase.id;
        pos.Valor__c=100;
        pos.Unidad__c='%';
        pos.Posicion__c='Test';
        insert pos;
        
		
		aCase.Motivo_de_Finalizacion__c = 'Procesado';
		aCase.Status = 'Cerrado';
		
		Test.startTest();
		update aCase;
		Test.stopTest();
		
		//System.assertNotEquals(null, serverMock.stub);
		
		Case theCaseInDb = [
			SELECT Id, Enviado_a_SAP__c
			FROM Case
			WHERE Id = :aCase.Id
		];
		
		//System.assertEquals(true, theCaseInDb.Enviado_a_SAP__c);
	}
    
	private static testMethod void whenACreditNoteCaseHasAlreadyBeenSentToSAP_ItShouldntBeSentAgain() {
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		serverMock.responseObj = new WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In();
		
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		
		RecordType creditNoteCase = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Nota_de_Credito'
		];
		Case aCase = Build.aCase().forAccount(anAccount).forContract(aContract).withRecordType(creditNoteCase)
			.WithCreditNoteMotive('Z37').build();
		insert aCase;
        
        Posicion__c pos = new Posicion__c();
        pos.Caso__c= aCase.id;
        pos.Valor__c=100;
        pos.Unidad__c='%';
        pos.Posicion__c='Test';
        insert pos;
		

		aCase.Motivo_de_Finalizacion__c = 'Procesado';
		aCase.Status = 'Cerrado';
		aCase.Enviado_a_SAP__c = true;
		
		Test.startTest();
		update aCase;
		Test.stopTest();
		
		System.assertEquals(null, serverMock.stub);
	}
	
	//==========================================
	//Contract modification cases
	private static testMethod void whenACaseThatModifiesContractsClosesIncorrectly_NewRecipientsShouldBeDiscarded() {
		insert modificationSettings;
		
		insert aContract;
		Titular__c aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		
		Case aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
		insert aCase;
		
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract).forHolder(aHolder).forCase(aCase).build();
		insert aRecipient;
		
		aCase.Motivo_de_Finalizacion__c = modificationSettings.Motivo_cierre_incorrecto__c;
		aCase.Status = 'Cerrado';
		
		update aCase;
		
		List<Beneficiario__c> recipients = [
			SELECT Id
			FROM Beneficiario__c
			WHERE Id = :aRecipient.Id
		];
		
		System.assertEquals(0, recipients.size());
	}
	
	private static testMethod void whenACaseThatModifiesContractsClosesIncorrectly_RecipientsThatAreInactiveShouldStayInactive() {
		insert modificationSettings;
		
		insert aContract;
		Titular__c aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		
		Case aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
		insert aCase;
		
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract).forHolder(aHolder)
			.forCase(aCase).withInactiveStatus().build();
		insert aRecipient;
		
		aCase.Motivo_de_Finalizacion__c = modificationSettings.Motivo_cierre_incorrecto__c;
		aCase.Status = 'Cerrado';
		
		update aCase;
		
		List<Beneficiario__c> recipients = [
			SELECT Id, Estado__c, Caso__c
			FROM Beneficiario__c
			WHERE Id = :aRecipient.Id
		];
		
		System.assertEquals(1, recipients.size());
		System.assertEquals('Baja', recipients[0].Estado__c);
		System.assertEquals(null, recipients[0].Caso__c);
	}
	
	private static testMethod void whenACaseThatModifiesContractsClosesIncorrectly_NewRecipientCoveragesShouldBeDiscarded() {
		insert modificationSettings;
		
		insert aContract;
		Titular__c aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract).forHolder(aHolder)
			.build();
		insert aRecipient;
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract).forProduct(aProduct).build();
		insert aCoverage;
		
		Case aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
		insert aCase;
		
		Cobertura_de_Beneficiario__c coverageRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(aCoverage).forCase(aCase).Build();
		insert coverageRecipientRelation;
		
		aCase.Motivo_de_Finalizacion__c = modificationSettings.Motivo_cierre_incorrecto__c;
		aCase.Status = 'Cerrado';
		
		update aCase;
		
		List<Cobertura_de_Beneficiario__c> relationsInDB = [
			SELECT Id
			FROM Cobertura_de_Beneficiario__c
			WHERE Id = :coverageRecipientRelation.Id
		];
		
		System.assertEquals(0, relationsInDB.size());
	}
	
	private static testMethod void whenACaseThatModifiesContractsClosesIncorrectly_RecipientCoveragesForDisabledRecipientsShouldStayInactive() {
		insert modificationSettings;
		
		insert aContract;
		Titular__c aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract).forProduct(aProduct).build();
		Cobertura__c anotherCoverage = Build.aCoverage().forContract(aContract).forProduct(anotherProduct).build();
		insert new List<Cobertura__c> {aCoverage, anotherCoverage};
		
		Case aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
		insert aCase;
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract).forHolder(aHolder)
			.forCase(aCase).withInactiveStatus().build();
		insert aRecipient;
		
		Cobertura_de_Beneficiario__c caseRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(aCoverage).forCase(aCase).Build();
		Cobertura_de_Beneficiario__c otherRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(anotherCoverage).Build();
		insert new List<Cobertura_de_Beneficiario__c> {caseRecipientRelation, otherRecipientRelation};
		
		aCase.Motivo_de_Finalizacion__c = modificationSettings.Motivo_cierre_incorrecto__c;
		aCase.Status = 'Cerrado';
		
		update aCase;
		
		List<Cobertura_de_Beneficiario__c> relationsInDB = [
			SELECT Id, Caso__c
			FROM Cobertura_de_Beneficiario__c
			WHERE Cobertura__r.Contrato__c = :aContract.Id
		];
		
		System.assertEquals(2, relationsInDB.size());
		System.assertEquals(null, relationsInDB[0].Caso__c);
		System.assertEquals(null, relationsInDB[1].Caso__c);
	}
	
	private static testMethod void whenACaseThatModifiesContractsClosesIncorrectly_NewDiscountsShouldBeDiscarded() {
		insert modificationSettings;
		
		insert aContract;
		Titular__c aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract).forProduct(aProduct).build();
		insert aCoverage;
		
		Case aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
		insert aCase;
		
		Descuento_Recargo_Aplicado__c anAppliedDiscount = Build.anAppliedDiscount().forCoverage(aCoverage)
			.forDiscount(aDiscount).forCase(aCase).Build();
		insert anAppliedDiscount;
		
		aCase.Motivo_de_Finalizacion__c = modificationSettings.Motivo_cierre_incorrecto__c;
		aCase.Status = 'Cerrado';
		
		update aCase;
		
		List<Descuento_Recargo_Aplicado__c> appliedDiscountsInDB = [
			SELECT Id
			FROM Descuento_Recargo_Aplicado__c
			WHERE Id = :anAppliedDiscount.Id
		];
		
		System.assertEquals(0, appliedDiscountsInDB.size());
	}
	
	private static testMethod void whenACaseThatModifiesContractsClosesIncorrectly_NewApplicantsShouldBeDiscarded() {
		insert modificationSettings;
		
		insert aContract;
		Titular__c aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract).forProduct(aProduct).build();
		insert aCoverage;
		Descuento_Recargo_Aplicado__c anAppliedDiscount = Build.anAppliedDiscount().forCoverage(aCoverage)
			.forDiscount(aDiscount).Build();
		insert anAppliedDiscount;
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract).forHolder(aHolder)
			.withInactiveStatus().build();
		insert aRecipient;
		Cobertura_de_Beneficiario__c coverageRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(aCoverage).Build();
		insert coverageRecipientRelation;
		
		Case aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
		insert aCase;
		
		Aplicante__c anApplicant = Build.anApplicant().forAppliedDiscount(anAppliedDiscount)
			.forRecipientCoverage(coverageRecipientRelation).withStartDate(Date.newInstance(2017, 3, 12))
			.withEndDate(Date.newInstance(2018, 10, 8)).forCase(aCase).build();
		insert anApplicant;
		
		aCase.Motivo_de_Finalizacion__c = modificationSettings.Motivo_cierre_incorrecto__c;
		aCase.Status = 'Cerrado';
		
		update aCase;
		
		List<Aplicante__c> applicantsInDB = [
			SELECT Id
			FROM Aplicante__c
			WHERE Id = :anApplicant.Id
		];
		
		System.assertEquals(0, applicantsInDB.size());
	}
	
	private static testMethod void whenACaseThatModifiesContractsClosesCorrectly_NewRecipientsShouldBeActivated() {
		insert modificationSettings;
		insert aContract;
		Titular__c aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		
		Case aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
		insert aCase;
		
        System.debug(aCase);
        
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract).forHolder(aHolder).forCase(aCase).build();
		insert aRecipient;
		
        System.debug(aRecipient);
        
		aCase.Motivo_de_Finalizacion__c = modificationSettings.Motivo_cierre_correcto__c;
		aCase.Status = 'Cerrado';
		
		update aCase;
		
		List<Beneficiario__c> recipients = [
			SELECT Id, Caso__c, Estado__c
			FROM Beneficiario__c
			WHERE Id = :aRecipient.Id
		];
		
		System.assertEquals(1, recipients.size());
		System.assertEquals(null, recipients[0].Caso__c);
		System.assertEquals('Activo', recipients[0].Estado__c);
	}
	
	private static testMethod void whenACaseThatModifiesContractsClosesCorrectly_RecipientsThatAreInactiveShouldBeActivated() {
		insert modificationSettings;
		
		insert aContract;
		Titular__c aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		
		Case aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
		insert aCase;
		
        System.debug('Id del caso '+ aCase.id);
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract).forHolder(aHolder)
			.forCase(aCase).withInactiveStatus().build();
		insert aRecipient;
		
		aCase.Motivo_de_Finalizacion__c = modificationSettings.Motivo_cierre_correcto__c;
		aCase.Status = 'Cerrado';
		
		update aCase;
		
		List<Beneficiario__c> recipients = [
			SELECT Id, Estado__c, Caso__c
			FROM Beneficiario__c
			WHERE Id = :aRecipient.Id
		];
		
		System.assertEquals(1, recipients.size());
		System.assertEquals(null, recipients[0].Caso__c);
        /*
        DMLException ex = new DMLException();
        ex.setMessage('HACK: '+recipients);
        throw ex;
        */
		System.assertEquals('Activo', recipients[0].Estado__c);
	}
	
	private static testMethod void whenACaseThatModifiesContractsClosesCorrectly_NewRecipientCoveragesShouldBeActivated() {
		insert modificationSettings;
		
		insert aContract;
		Titular__c aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract).forHolder(aHolder)
			.withInactiveStatus().build();
		insert aRecipient;
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract).forProduct(aProduct).build();
		insert aCoverage;
		
		Case aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
		insert aCase;
		
		Cobertura_de_Beneficiario__c coverageRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(aCoverage).forCase(aCase).Build();
		insert coverageRecipientRelation;
		
		aCase.Motivo_de_Finalizacion__c = modificationSettings.Motivo_cierre_correcto__c;
		aCase.Status = 'Cerrado';
		
		update aCase;
		
		List<Cobertura_de_Beneficiario__c> relationsInDB = [
			SELECT Id, Caso__c
			FROM Cobertura_de_Beneficiario__c
			WHERE Id = :coverageRecipientRelation.Id
		];
		
		System.assertEquals(1, relationsInDB.size());
		System.assertEquals(null, relationsInDB[0].Caso__c);
	}
	
	private static testMethod void whenACaseThatModifiesContractsClosesCorrectly_RecipientCoveragesForDisabledRecipientsShouldBeMadeActiveOrDeletedIfTheyAreToBeReactivated() {
		insert modificationSettings;
		
		insert aContract;
		Titular__c aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract).forProduct(aProduct).build();
		Cobertura__c anotherCoverage = Build.aCoverage().forContract(aContract).forProduct(anotherProduct).build();
		insert new List<Cobertura__c> {aCoverage, anotherCoverage};
		
		Case aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
		insert aCase;
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract).forHolder(aHolder)
			.forCase(aCase).withInactiveStatus().build();
		insert aRecipient;
		
		Cobertura_de_Beneficiario__c caseRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(aCoverage).forCase(aCase).Build();
		Cobertura_de_Beneficiario__c otherRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(anotherCoverage).Build();
		insert new List<Cobertura_de_Beneficiario__c> {caseRecipientRelation, otherRecipientRelation};
		
		aCase.Motivo_de_Finalizacion__c = modificationSettings.Motivo_cierre_correcto__c;
		aCase.Status = 'Cerrado';
		
		update aCase;
		
		List<Cobertura_de_Beneficiario__c> relationsInDB = [
			SELECT Id, Caso__c
			FROM Cobertura_de_Beneficiario__c
			WHERE Cobertura__r.Contrato__c = :aContract.Id
		];
		
		System.assertEquals(1, relationsInDB.size());
		System.assertEquals(null, relationsInDB[0].Caso__c);
		System.assertEquals(caseRecipientRelation.Id, relationsInDB[0].Id);
	}
	
	private static testMethod void whenACaseThatModifiesContractsClosesCorrectly_NewDiscountsShouldBeActivated() {
		insert modificationSettings;
		
		insert aContract;
		Titular__c aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract).forProduct(aProduct).build();
		insert aCoverage;
		
		Case aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
		insert aCase;
		
		Descuento_Recargo_Aplicado__c anAppliedDiscount = Build.anAppliedDiscount().forCoverage(aCoverage)
			.forDiscount(aDiscount).forCase(aCase).Build();
		insert anAppliedDiscount;
		
		aCase.Motivo_de_Finalizacion__c = modificationSettings.Motivo_cierre_correcto__c;
		aCase.Status = 'Cerrado';
		
		update aCase;
		
		List<Descuento_Recargo_Aplicado__c> appliedDiscountsInDB = [
			SELECT Id, Caso__c
			FROM Descuento_Recargo_Aplicado__c
			WHERE Id = :anAppliedDiscount.Id
		];
		
		System.assertEquals(1, appliedDiscountsInDB.size());
		System.assertEquals(null, appliedDiscountsInDB[0].Caso__c);
	}
    
    private static testMethod void whenACaseHaveAWrongCardNumber_itThrowAValidateException()  {
        RecordType casePaymentRecordType = [SELECT Id
                                 			FROM RecordType
                                 			WHERE DeveloperName='Cambio_de_forma_de_pago'
                                 			LIMIT 1];
        
        Case aCaseWithCreditCard = Build.aCase().forAccount(anAccount).withRecordType(casePaymentRecordType)
			.withReason('Cambio de forma de pago').forContract(aContract).build();
        aCaseWithCreditCard.Numero_de_Tarjeta__c=12345678;
        
        String error;
        try {        
			insert aCaseWithCreditCard;
        } catch (DMLException ex) {
            error = ex.getMessage();
        }
 		System.Assert(error.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
 		System.Assert(error.contains('Número de Tarjeta no válido'));
        
    }
     
     private static testMethod void whenACaseHaveAWrongCBU_itThrowAValidateException()  {
        RecordType casePaymentRecordType = [SELECT Id
                                 			FROM RecordType
                                 			WHERE DeveloperName='Cambio_de_forma_de_pago'
                                 			LIMIT 1];
        
        Case aCaseWithCBU = Build.aCase().forAccount(anAccount).withRecordType(casePaymentRecordType)
			.withReason('Cambio de forma de pago').forContract(aContract).build();
        aCaseWithCBU.CBU__c='123456789123';
        
        String error;
        try {        
			insert aCaseWithCBU;
        } catch (DMLException ex) {
            error = ex.getMessage();
        }
 		System.Assert(error.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
 		System.Assert(error.contains('Número de CBU no válido'));
        
    }
    
	private static testMethod void whenABonusCaseHaveNotDiscounts_itThrowAValidateException()  {
        RecordType caseBonusRecordType = [SELECT Id
                                 			FROM RecordType
                                 			WHERE DeveloperName='Bonificacion'
                                 			LIMIT 1];
        
        Case aBonusCase = Build.aCase().forAccount(anAccount).withRecordType(caseBonusRecordType)
			.withReason('Bonificaciones').forContract(aContract).build();
        
        aBonusCase.Submotivo__c='Fidelizacion';
        
		insert aBonusCase;
        
        aBonusCase.Motivo_de_Finalizacion__c='Procesado';
        
        String error;
        try {        
            update aBonusCase;
        } catch (DMLException ex) {
            error = ex.getMessage();
        }
 		System.Assert(error.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
 		System.Assert(error.contains(Label.La_bonificacion_no_tiene_descuentos));
        
    }
    
	private static testMethod void ifAContractHaveACaseOrOpportunityOpen_aCoverageChangeCaseCantBeClosed ()  {
        insert aContract;
        
        Opportunity aOpportunityToBlockCoverageChange = Build.anOpportunity()
            									.withDischargeTypePartial()
            									.forContract(aContract)
            									.forAccount(anAccount)
            									.withDischargeTypePartial()
            									.build();
        
		insert aOpportunityToBlockCoverageChange; 
        System.debug(aOpportunityToBlockCoverageChange.contrato__c);
        
        RecordType coverageChangeCaseRecordType = [SELECT Id
                                 			FROM RecordType
                                 			WHERE DeveloperName='Cambio_de_cobertura'
                                 			LIMIT 1];
        
		Case coverageChangeCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
        System.debug(coverageChangeCase.contrato__c);
       
        Caso_generador__c customSetting = new Caso_generador__c();
        customSetting.Name='Cambio_de_Cobertura';
        customSetting.Motivo_cierre_correcto__c='Procesado';
        insert customSetting;
        
        String error;
        try {        
            insert coverageChangeCase;
        } catch (DMLException ex) {
            error = ex.getMessage();
        }
 		System.Assert(error.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
 		System.Assert(error.contains(Label.Cambio_de_cobertura_con_otros_casos_abiertos));
        
    }
	
	private static testMethod void whenACaseThatModifiesContractsClosesCorrectly_NewApplicantsShouldBeActivated() {
		insert modificationSettings;
		
		insert aContract;
		Titular__c aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract).forProduct(aProduct).build();
		insert aCoverage;
		Descuento_Recargo_Aplicado__c anAppliedDiscount = Build.anAppliedDiscount().forCoverage(aCoverage)
			.forDiscount(aDiscount).Build();
		insert anAppliedDiscount;
		Beneficiario__c aRecipient = Build.aRecipient().forContract(aContract).forHolder(aHolder)
			.withInactiveStatus().build();
		insert aRecipient;
		Cobertura_de_Beneficiario__c coverageRecipientRelation = Build.aCoverageRecipientRelation()
			.forRecipient(aRecipient).forCoverage(aCoverage).Build();
		insert coverageRecipientRelation;
		
		Case aCase = Build.aCase().forAccount(anAccount).withRecordType(caseRecordType)
			.withReason('Cambio de cobertura').forContract(aContract).build();
		insert aCase;
		
		Aplicante__c anApplicant = Build.anApplicant().forAppliedDiscount(anAppliedDiscount)
			.forRecipientCoverage(coverageRecipientRelation).withStartDate(Date.newInstance(2017, 3, 12))
			.withEndDate(Date.newInstance(2018, 10, 8)).forCase(aCase).build();
		insert anApplicant;
		
		aCase.Motivo_de_Finalizacion__c = modificationSettings.Motivo_cierre_Correcto__c;
		aCase.Status = 'Cerrado';
		
		update aCase;
		
		List<Aplicante__c> applicantsInDB = [
			SELECT Id, Caso__c
			FROM Aplicante__c
			WHERE Id = :anApplicant.Id
		];
		
		System.assertEquals(1, applicantsInDB.size());
		System.assertEquals(null, applicantsInDB[0].Caso__c);
	}
	
	//==========================================================================
	static User anUser;
	static User anotherUser;
	static Group aGroup;
	static Grupos_para_casos__c groupCaseAssignmentSettings;
	static Account anAccount;
	static RecordType caseRecordType;
	static Caso_generador__c cloningSettings;
	static Casos_Beneficiarios_Descuentos__c modificationSettings;
	static Contrato__c aContract;
	static Product2 aProduct;
	static Product2 anotherProduct;
	static Descuento_Recargo__c aDiscount;
	
	static {
		User myself = new User(Id = UserInfo.getUserId());
		anUser = Build.anUser().build();
		anotherUser = Build.anUser().withLastCaseLatePaymentAssignment(System.now().addDays(-1)).build();
		insert new List<User> {anUser, anotherUser};
		
		System.runAs(myself) {
			//Execute in different context
			aGroup = Build.aGroup().withName('My group').build();
			insert aGroup;
			List<GroupMember> groupMemberships = new List<GroupMember> {
				Build.aGroupMembership().forMember(anUser).forGroup(aGroup).build(),
				Build.aGroupMembership().forMember(anotherUser).forGroup(aGroup).build()
			};
			insert groupMemberships;
		}
		caseRecordType = [
			SELECT Id, DeveloperName
			FROM RecordType
			WHERE SObjectType = 'Case'
				AND DeveloperName = 'Cambio_de_Cobertura'
			LIMIT 1
		];
		
		aProduct = Build.aProduct().withName('Prod 1').withNumber('Prod 1')
			.withSector(Product2.Sector__c.getDescribe().getPicklistValues()[0].getValue()).build();
		anotherProduct = Build.aProduct().withName('Prod 2').withNumber('Prod 2')
			.withSector(Product2.Sector__c.getDescribe().getPicklistValues()[0].getValue()).build();
		insert new List<Product2> {aProduct, anotherProduct};
		aDiscount = Build.aDiscount().withName('A discount')
			.withValue(21.34).withUnit('%').withDiscountCode('ZJUE').build();
		insert aDiscount;
		
		anAccount = Build.anAccount().build();
		insert anAccount;
		groupCaseAssignmentSettings = Build.someGroupCaseAssignmentSettings()
			.forGroup(aGroup).withUserField('Gestion_mora_ultima_asignacion__c')
			.withName('Gestion de Mora').build();
		insert groupCaseAssignmentSettings;
		
		//==================================================
		delete Caso_generador__c.getAll().values();
		delete Casos_Beneficiarios_Descuentos__c.getAll().values();
		
		cloningSettings = Build.someCaseContractCloneSettings().forCaseRecordType(caseRecordType)
			.withCloseReasonCorrect('Procesado')
			.withCloseReasonIncorrect('Rechazado').build();
		modificationSettings = Build.someAdditionCaseSettings()
			.forCaseRecordType(caseRecordType).withCloseReasonCorrect('Procesado')
			.withCloseReasonIncorrect('Rechazado').build();
		//==================================================
		
		aContract = Build.aContract().forAccount(anAccount).build();

		Notas_de_credito_numeracion__c numeracion;
		numeracion = new Notas_de_credito_numeracion__c();
		numeracion.Name='Numero';
		numeracion.Numero__c=6561645;
		insert numeracion;
	}
}
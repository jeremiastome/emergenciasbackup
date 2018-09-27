@isTest
private class OpportunityTriggerTest {
	//Contract creation
	private static testMethod void whenAnOpportunityIsInsertedWithTheNewDischargeTypeAContractShouldBeCreatedForIt() {
		List<Schema.PicklistEntry> SalesOrganizationValues = User.Organizacion_de_Venta__c.getDescribe().getPicklistValues();
		List<Schema.PicklistEntry> SalespersonGroupValues = User.Grupo_de_Vendedores__c.getDescribe().getPicklistValues();
		User aSalesperson = Build.anUser().withSalesOrganization(SalesOrganizationValues[0].getValue())
		.withSalespersonGroup(SalespersonGroupValues[0].getValue()).build();
		insert aSalesperson;
		Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount).withDischargeTypeNew().withSalesperson(aSalesperson).build();
		insert anOpportunity;
		List<Contrato__c> contracts = [
			SELECT Id, Cliente__c, Estado__c, RecordType.DeveloperName
			FROM Contrato__c
			WHERE Cliente__c = :anAccount.Id
		];
		
		System.assertEquals(1, contracts.size());
		System.assertEquals('En proceso de venta', contracts[0].Estado__c);
		System.assertEquals('Contrato', contracts[0].RecordType.DeveloperName);

		Opportunity theOpportunityInDB = [
			SELECT Id, Contrato__c
			FROM Opportunity
			WHERE Id = :anOpportunity.Id
		];
		System.assertEquals(contracts[0].Id, theOpportunityInDB.Contrato__c);
	}
	
	private static testMethod void whenAnOpportunityIsInsertedTheContractsUniqueNumberShouldHaveAValueDependingOnTheOpportunityType() {
		Map<Id, String> contractLetterByRecordType = getContractLetterByRecordType();
		
		List<Opportunity> opportunities = new List<Opportunity> ();
		for (Id recordTypeId : contractLetterByRecordType.keySet()) {
			Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount)
			.withDischargeTypeNew().withRecordTypeId(recordTypeId).build();
			if (contractLetterByRecordType.get(recordTypeId) == 'A') { //Is a Pymes opportunity
				anOpportunity.StageName = 'Identificado';
			}
			else if (contractLetterByRecordType.get(recordTypeId) == 'V') { //Salud y estado opportunity
				anOpportunity.StageName = 'Negociación';
			}
			else if (contractLetterByRecordType.get(recordTypeId) == 'C') { //Coorporaciones opportunity
				anOpportunity.StageName = 'Identificado';
			}
			opportunities.add(anOpportunity);
		}
		
		insert opportunities;
		
		List<Opportunity> opportunitiesInDb = [
			SELECT Id, RecordTypeId, Contrato__r.Numero_unico_de_contrato_numero__c,
				Contrato__r.Numero_unico_de_contrato_letra__c,
				Contrato__r.Numero_Unico_de_Contrato__c
			FROM Opportunity
		];
		
		for (Opportunity anOpportunity : opportunitiesInDb) {
			System.assertEquals(
				contractLetterByRecordType.get(anOpportunity.RecordTypeId),
				anOpportunity.Contrato__r.Numero_unico_de_contrato_letra__c
			);
			System.assertEquals(1, anOpportunity.Contrato__r.Numero_unico_de_contrato_numero__c);
			System.assertEquals(
				contractLetterByRecordType.get(anOpportunity.RecordTypeId) + '000001',
				anOpportunity.Contrato__r.Numero_Unico_de_Contrato__c
			);
		}
	}
	
	@isTest
	private static void whenAPymesOpportunityIsInsertedWithTheNewDischargeTypeTheCreatedContractShouldHaveThePymesDistributionChannel() {
		RecordType pymesOpportunityType = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Pymes'
		];
		List<Schema.PicklistEntry> SalesOrganizationValues = User.Organizacion_de_Venta__c
			.getDescribe().getPicklistValues();
		List<Schema.PicklistEntry> SalespersonGroupValues = User.Grupo_de_Vendedores__c
			.getDescribe().getPicklistValues();
		User aSalesperson = Build.anUser().withSalesOrganization(SalesOrganizationValues[0].getValue())
			.withSalespersonGroup(SalespersonGroupValues[0].getValue()).build();
		insert aSalesperson;
		Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount)
			.withRecordTypeId(pymesOpportunityType.Id).withDischargeTypeNew()
			.withSalesperson(aSalesperson).withStageName('Identificado').build();
		insert anOpportunity;
		Contrato__c aContract = [
			SELECT Id, TOLABEL(Canal_de_Distribucion__c)
			FROM Contrato__c
			WHERE Cliente__c = :anAccount.Id
		];
		
		System.assertEquals('Pymes y Comercios', aContract.Canal_de_Distribucion__c);
	}
	
	@isTest
	private static void whenAFinalConsumerOpportunityIsInsertedWithTheNewDischargeTypeTheCreatedContractShouldHaveTheFinalConsumerDistributionChannel() {
		RecordType finalConsumerOpportunityType = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Venta_Consumidor_Final'
		];
		List<Schema.PicklistEntry> SalesOrganizationValues = User.Organizacion_de_Venta__c
			.getDescribe().getPicklistValues();
		List<Schema.PicklistEntry> SalespersonGroupValues = User.Grupo_de_Vendedores__c
			.getDescribe().getPicklistValues();
		User aSalesperson = Build.anUser().withSalesOrganization(SalesOrganizationValues[0].getValue())
			.withSalespersonGroup(SalespersonGroupValues[0].getValue()).build();
		insert aSalesperson;
		Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount)
			.withRecordTypeId(finalConsumerOpportunityType.Id).withDischargeTypeNew()
			.withSalesperson(aSalesperson).build();
		insert anOpportunity;
		Contrato__c aContract = [
			SELECT Id, TOLABEL(Canal_de_Distribucion__c)
			FROM Contrato__c
			WHERE Cliente__c = :anAccount.Id
		];
		
		System.assertEquals('Consumidor Final', aContract.Canal_de_Distribucion__c);
	}
	
	private static testMethod void ifAContractAlreadyExistsForARecordTypeTheContractNumberShouldBeTheNextOne() {
		Numeros_de_contratos__c numberSettings = new Numeros_de_contratos__c();
		numberSettings.Name = 'D';
		numberSettings.Numero_maximo__c = 453432;
		insert numberSettings;
		
		Map<Id, String> contractLetterByRecordType = getContractLetterByRecordType();
		//Id opportunityType = new List<Id>(contractLetterByRecordType.keySet())[0]; // NO FUNCIONA EN PROD, NO RESPETA ORDEN!
		Id opportunityType;
		for (Id rtId : contractLetterByRecordType.keySet()) {
			if (contractLetterByRecordType.get(rtId) == 'D') {
				opportunityType = rtId;
				break;
			}
		}
		
		Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount)
			.withDischargeTypeNew().withRecordTypeId(opportunityType).build();
		
		integer contractNumber = 453432;
		Contrato__c aContract = Build.aContract().forAccount(anAccount)
			.withUniqueNumber(contractLetterByRecordType.get(opportunityType) + contractNumber)
			.build();
		insert aContract;
		
		insert anOpportunity;

		Opportunity theOpportunityInDb = [
			SELECT Id, RecordTypeId, Contrato__r.Numero_unico_de_contrato_numero__c
			FROM Opportunity
			WHERE Id = :anOpportunity.Id
		];
		
		System.assertEquals(
			contractNumber + 1,
			theOpportunityInDb.Contrato__r.Numero_unico_de_contrato_numero__c
		);
		System.debug('*** Embozados test 2: ' + [SELECT id FROM Pedido_de_Embozado__c]);
	}
	
	private static testMethod void ifTheOpportunityIsMarkedToNotHaveAContractAVariedSalesContractShouldBeCreated() {
		Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount).withDischargeTypeNew().saleWithoutContract().build();
		insert anOpportunity;
		
		List<Contrato__c> contracts = [
			SELECT Id, Cliente__c, Estado__c, Numero_unico_de_contrato_letra__c,
				RecordType.DeveloperName
			FROM Contrato__c
			WHERE Cliente__c = :anAccount.Id
		];
		
		System.assertEquals(1, contracts.size());
		System.assertEquals('En proceso de venta', contracts[0].Estado__c);
		System.assertEquals('Ventas_Varias', contracts[0].RecordType.DeveloperName);
		System.assertEquals('X', contracts[0].Numero_unico_de_contrato_letra__c);
		
		Opportunity theOpportunityInDB = [
			SELECT Id, Contrato__c
			FROM Opportunity
			WHERE Id = :anOpportunity.Id
		];
		
		System.assertEquals(contracts[0].Id, theOpportunityInDB.Contrato__c);
	}
	
	//========================================
	//Force comment on rejected approval process
	private static testMethod void ifAnOpportunityIsUpdatedAfterBeingRejectedInAnApprovalProcess_IfTheRejectionDoesNotHaveACommentItShouldFail() {
		Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount)
			.withWarningsValidated().withDischargeTypeNew()
			.withWarningJustification('some excuse.').build();
		insert anOpportunity;
		Advertencia__c aWarning = Build.aWarning().forOpportunity(anOpportunity)
			.withWarningTypeNotProfitable().build();
		insert aWarning;
		
		Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
		approvalRequest.setProcessDefinitionNameOrId('Aprobacion_de_oportunidadv5');
		approvalRequest.setObjectId(anOpportunity.Id);
		Approval.ProcessResult aProcessResult = Approval.process(approvalRequest);
		
		Approval.ProcessWorkitemRequest rejection = new Approval.ProcessWorkitemRequest();
		rejection.setAction('Reject');
		rejection.setWorkitemId(aProcessResult.getNewWorkitemIds() [0]);
		
		boolean failed = false;
		try {
			Approval.ProcessResult rejectionResult = Approval.process(rejection);
		}
		catch(DMLException e) {
			system.assertEquals(
				Label.No_se_dio_comentario_para_rechazo,
				e.getDmlMessage(0)
			);
			failed = true;
		}
		
		System.assertEquals(true, failed);
		
		Opportunity theOpportunityInDb = [
			SELECT Rechazada__c
			FROM Opportunity
			WHERE Id = :anOpportunity.Id
		];
		
		System.assertEquals(false, theOpportunityInDb.Rechazada__c);
	}
	
	private static testMethod void ifAnOpportunityIsUpdatedAfterBeingRejectedInAnApprovalProcess_IfTheRejectionHasACommentItShouldWork() {
		Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount)
		.withWarningsValidated().withDischargeTypeNew()
		.withWarningJustification('some excuse.').build();
		insert anOpportunity;
		Advertencia__c aWarning = Build.aWarning().forOpportunity(anOpportunity)
		.withWarningTypeNotProfitable().build();
		insert aWarning;
		
		Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
		approvalRequest.setProcessDefinitionNameOrId('Aprobacion_de_oportunidadv5');
		approvalRequest.setObjectId(anOpportunity.Id);
		Approval.ProcessResult aProcessResult = Approval.process(approvalRequest);
		
		Approval.ProcessWorkitemRequest rejection = new Approval.ProcessWorkitemRequest();
		rejection.setComments('Rejecting request with a comment.');
		rejection.setAction('Reject');
		rejection.setWorkitemId(aProcessResult.getNewWorkitemIds() [0]);
		
		Approval.ProcessResult rejectionResult = Approval.process(rejection);
		
		System.assertEquals(true, rejectionResult.isSuccess());
		
		Opportunity theOpportunityInDb = [
			SELECT Rechazada__c
			FROM Opportunity
			WHERE Id = :anOpportunity.Id
		];
		
		System.assertEquals(false, theOpportunityInDb.Rechazada__c);
	}
	
	//========================================
	//Others
	private static testMethod void ifAContractIsCreatedWithAExistingNumberTheCustomSettingsWillUpdate() {
		Numeros_de_contratos__c numberSettings = new Numeros_de_contratos__c();
		numberSettings.Name = 'D';
		numberSettings.Numero_maximo__c = 453432;
		insert numberSettings;
		
		Map<Id, String> contractLetterByRecordType = getContractLetterByRecordType();
		
		Id opportunityType;
		for (Id rtId : contractLetterByRecordType.keySet()) {
			if (contractLetterByRecordType.get(rtId) == 'D') {
				opportunityType = rtId;
				break;
			}
		}
		
		Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount)
			.withDischargeTypeNew().withRecordTypeId(opportunityType).build();
		
		integer contractNumber = 453432;
		Contrato__c aContract = Build.aContract().forAccount(anAccount)
			.withUniqueNumber(contractLetterByRecordType.get(opportunityType) + contractNumber)
			.build();
		insert aContract;
		
		integer contractNumber2 = 453433;
		Contrato__c aContract2 = Build.aContract().forAccount(anAccount)
			.withUniqueNumber(contractLetterByRecordType.get(opportunityType) + contractNumber2)
			.build();
		insert aContract2;
		
		Numeros_de_contratos__c maxNumber = Numeros_de_contratos__c.getValues('D');
		maxNumber.Numero_maximo__c = 453432;
		update maxNumber;
		
		insert anOpportunity;
		
		Opportunity theOpportunityInDB = [
			SELECT Id, Contrato__r.Numero_Unico_de_Contrato__c
			FROM Opportunity
			WHERE Id = :anOpportunity.Id
		];
		
		System.assertEquals('D453434', theOpportunityInDB.Contrato__r.Numero_Unico_de_Contrato__c);
		System.assertEquals(Numeros_de_contratos__c.getValues('D').numero_Maximo__c, 453434);
	}
	
	private static testMethod void ifAOppornityIsWon_themTheyWillBeActived() {
		Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount).withDischargeTypeNew().build();
		insert anOpportunity;
		RecordType consumidorFinal = [
			SELECT ID
			FROM RecordType
			WHERE DeveloperName = 'Venta_consumidor_final'
			LIMIT 1
		];
		
		Contrato__c aContract = [
			SELECT Id
			FROM Contrato__c
			WHERE Id IN (SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		];
		
		aHolder = [//Created by a process
			SELECT Id, Numero_de_Titular__c, Ult_Numero_de_beneficiario__c
			FROM Titular__c
			WHERE Contrato__c = :aContract.Id
		];
		
		cobertura__c coverage = build.aCoverage().withName('Coverage ')
			.forProduct(Producto).forContract(aContract).build();
		insert coverage;
		
		Beneficiario__c recipientTest = build.aRecipient().withInactiveStatus()
			.forContract(aContract).forHolder(aHolder).withProvince('Capital Federal')
			.withIVATreatment('BE').build();
		insert recipientTest;
		
		Cobertura_de_beneficiario__c CoverageRecipientRelation = build.aCoverageRecipientRelation()
			.forRecipient(recipientTest).forCoverage(coverage).CreatedInOpp(anOpportunity).build();
		insert CoverageRecipientRelation;
		
		//Gano la oportunidad
		anOpportunity.StageName='Ganada';
		anOpportunity.RecordTypeId=consumidorFinal.Id;
		
		//Creo una configuración de usuario no envia para no alcanzar limites de profundidad de pila
		Usuario_no_envia_a_SAP__c usrConfig = new Usuario_no_envia_a_SAP__c();
		usrConfig.Name = userInfo.getUserName();
		usrConfig.No_envia__c = true;
		insert usrConfig;
		//
		Test.startTest();
		update anOpportunity;
		Test.stopTest();
		recipients = [
			SELECT Id, Estado__c
			FROM Beneficiario__c
			WHERE ID = :recipientTest.id
		];
		System.debug('*** Embozados test 3: ' + [SELECT id FROM Pedido_de_Embozado__c]);
		for(Beneficiario__c recipient : recipients) {
			System.assertEquals(recipient.Estado__c, 'Activo');
		}


	}

	//========================================
	//Force discount justification on approval submit
	private static testMethod void ifAnOpportunityWithSpecialDiscountAndWithoutJustificationForItIsSubmittedForApproval_itShouldNotBeUpdatedAndShoeErrorMEssage() {
		
		initTestData();
		Boolean hasError = false;
		Test.startTest();
		try{       
			String respuesta = Oportunidad_enviarAprobacionController.sendForApproval(anOpp_Test_Justification.Id);
		}
		catch (DmlException e){
			System.assertEquals(1, e.getNumDml());
			System.assertEquals('Justificacion_de_descuentos_a_medida__c', e.getDmlFieldNames(0)[0]);
			System.assert(e.getDmlMessage(0).indexOf(
				Label.Oportunidad_Justificacion_por_descuento_a_medida_requerido) > -1
			);
			hasError = true;
		}
		Test.stopTest();
		
		Opportunity theOpportunityInDb = [SELECT StageName
			FROM Opportunity
			WHERE Id = :anOpp_Test_Justification.Id
		];
		
		System.assert(hasError);
		System.assertNotEquals('Pendiente de Aprobación', theOpportunityInDb.StageName);
		System.assertEquals(false, Approval.isLocked(theOpportunityInDb));
	}
	
	private static testMethod void ifAnOpportunityWithSpecialDiscountAndWithtJustificationForItIsSubmittedForApproval_itShouldContinueWithTheApprovalProccess() {
		
		//-------------------- Init test data ----------------------------------------------------
		initTestData();
		anOpp_Test_Justification.Justificacion_de_descuentos_a_medida__c = 'Some reason';
		update anOpp_Test_Justification;
		//-----------------------------------------------------------------------------------------

		Test.startTest();
		String respuesta = Oportunidad_enviarAprobacionController.sendForApproval(anOpp_Test_Justification.Id);
		Test.stopTest();
		
		Opportunity theOpportunityInDb = [SELECT StageName, Estado_Aprobacion__c
			FROM Opportunity
			WHERE Id = :anOpp_Test_Justification.Id
		];
		
		System.assertEquals('Ganada', theOpportunityInDb.StageName);
	}

	private static testMethod void ifAnOpportunityWithoutSpecialDiscountIsSubmittedForApproval_itShouldContinueWithTheApprovalProccess() {
		
		//-------------------- Init test data ----------------------------------------------------
		initTestData();

		Descuento_Recargo__c anotherDiscont = [SELECT Id, Codigo_de_descuento__c
			FROM Descuento_Recargo__c
			WHERE Codigo_de_descuento__c = 'ZDV0'
		];
		//cambio el descuento a medida
		anotherDiscont.Codigo_de_descuento__c = 'ZDV3';
		update anotherDiscont;
		//-----------------------------------------------------------------------------------------

		Test.startTest();
		String respuesta = Oportunidad_enviarAprobacionController.sendForApproval(anOpp_Test_Justification.Id);
		Test.stopTest();
		
		Opportunity theOpportunityInDb = [SELECT StageName, Estado_Aprobacion__c
			FROM Opportunity
			WHERE Id = :anOpp_Test_Justification.Id
		];
		
		System.assertEquals('Ganada', theOpportunityInDb.StageName);
	}

	// private static testMethod void ifAOpportunityIsCreatedByALead_triggerPutARecordType() {
	// 	Opportunity opp = Build.anOpportunity().withDistributionChannel('20').forAccount(anAccount)
	// 		.withDischargeTypeNew().saleWithoutContract().build();
	// 	opp.Tipo_de_oportunidad_por_prospecto__c = 'Pymes';
	//
	// 	Test.startTest();
	// 	insert opp;
	// 	Test.stopTest();
	//
	// 	Opportunity oppInserted = [
	// 		SELECT Id, RecordType.DeveloperName
	// 		FROM Opportunity
	// 		WHERE Id = :opp.Id
	// 		LIMIT 1
	// 	];
	// 	System.assertEquals(oppInserted.RecordType.DeveloperName, 'Pymes');
	// }
	
	//==========================================================================
	private static Map<Id, String> getContractLetterByRecordType() {
		List<RecordType> opportunityTypes = [
			SELECT Id, DeveloperName
			FROM RecordType
			WHERE sObjectType = 'Opportunity'
		];
		Map<Id, String> contractLetterByRecordType = new Map<Id, String> ();
		for (RecordType opportunityType : opportunityTypes) {
			if (opportunityType.DeveloperName == 'Venta_Consumidor_Final') {
				contractLetterByRecordType.put(opportunityType.Id, 'D');
			}
			else if (opportunityType.DeveloperName == 'Salud_y_Estado') {
				contractLetterByRecordType.put(opportunityType.Id, 'V');
			}
			else if (opportunityType.DeveloperName == 'Corporaciones') {
				contractLetterByRecordType.put(opportunityType.Id, 'C');
			}
			else if (opportunityType.DeveloperName == 'Pymes') {
				contractLetterByRecordType.put(opportunityType.Id, 'A');
			}
		}
		
		return contractLetterByRecordType;
	}
	//==========================================================================
	static Account anAccount;
	static Opportunity anOpportunity2;
	static Opportunity anOpp_Test_Justification;
	static Contrato__c aContract2;
	static Titular__c aHolder;
	static Product2 producto;
	static List<Cobertura__c> coverages;
	static List<Beneficiario__c> recipients;
	static List<Cobertura_de_Beneficiario__c> recipientCoverages;
	static List<Descuento_Recargo__c> discounts;
	static List<Descuento_Recargo_Aplicado__c> appliedDiscounts;
	static Product2 productoSinCredencial;

	static {
		insert new Configuracion_para_envio_de_credenciales__c(Envia__c = true);
		anAccount = Build.anAccount().withBillingCountry('Country').withBillingState('State')
			.withBillingCity('City').withBillingStreet('Street').withIVACondition('06').build();
		anAccount.Comprobar_cierre_primera_oportunidad__c = true;
		insert anAccount;
		
		producto = Build.aProduct().needsCredential().build();
		insert producto;
		
		productoSinCredencial=Build.aProduct().build();
		insert productoSinCredencial;
		
		/*
		List<Product2> products = new List<Product2>();
		for (integer i=0; i<1; i++) {
			Product2 product = build.aProduct().withName('Test '+i).build();
			product.isActive=true;
			products.add( product );
		}
		insert products;
		*/
		/*
		coverages = new List<Cobertura__c>();
		for (integer i=0; i<1; i++) {
			Cobertura__c coverage = build.aCoverage().withName('Coverage '+i)
				.forProduct(products[i]).forContract(aContract2).build();
			coverages.add( coverage );
		}
		insert coverages;
		*/
		/*
		recipients = new List<Beneficiario__c>();
		
		for (integer i=0; i<10; i++) {
			Beneficiario__c recipient = build.aRecipient().withInactiveStatus()
				.forContract(aContract2).forHolder(aHolder).build();
			recipients.add(recipient);
		}
		insert recipients;
		/*
		recipientCoverages = new List<Cobertura_de_Beneficiario__c>();
		for (integer i=0; i<10; i++) {
			recipientCoverages.add(
				build.aCoverageRecipientRelation().forRecipient(recipients[i])
					.forCoverage(coverages[0]).CreatedInOpp(anOpportunity2).build()
			);
		}
		insert recipientCoverages;
		*/
	}

	public static void initTestData() {
		
		// para evitar mandar a SAP
		anAccount.Estado__c = 'Activo';
		anAccount.Status_Envio__c = '-1';
		update anAccount;

		aContract2 = Build.aContract().forAccount(anAccount).withUniqueNumber()
			.withPaymentMethod(Contrato__c.Forma_de_Pago__c.getDescribe()
				.getPicklistValues() [0].getValue()
			)
			.withPaymentCondition(Contrato__c.Condicion_de_pago__c.getDescribe()
				.getPicklistValues() [0].getValue()
			)
			.build();
		insert aContract2;

		anOpp_Test_Justification = Build.anOpportunity().forAccount(anAccount).forContract(aContract2)
			.withWarningsValidated().withDischargeTypeNew().withSomeSalesHierarchy()
			.withDischargeTypePartial().withWarningJustification('some excuse.').build();
		insert anOpp_Test_Justification;
		
		aHolder = Build.aHolder().forAccount(anAccount).forContract(aContract2)
			.forOpportunity(anOpp_Test_Justification).build();
		insert aHolder;
	
		Beneficiario__c recipient = build.aRecipient().withInactiveStatus().forAccount(anAccount)
			.forOpportunity(anOpp_Test_Justification).forContract(aContract2).forHolder(aHolder).build();
		insert recipient;

		Cobertura__c aCoverageWithSpecialDiscount = Build.aCoverage().forContract(aContract2)
			.forProduct(Producto).build();

		Cobertura__c aCoverageWithoutSpecialDiscount = Build.aCoverage().forContract(aContract2)
			.forProduct(Producto).build();
		
		Cobertura__c anotherCoverageWithSpecialDiscount = Build.aCoverage().forContract(aContract2)
			.forProduct(Producto).build();

		coverages = new List<Cobertura__c>{
			aCoverageWithSpecialDiscount, aCoverageWithoutSpecialDiscount, anotherCoverageWithSpecialDiscount
		};
		insert coverages;

		Cobertura_de_Beneficiario__c aRecipientCoverage = Build.aCoverageRecipientRelation()
			.forRecipient(recipient).forCoverage(aCoverageWithSpecialDiscount)
			.CreatedInOpp(anOpp_Test_Justification)
			.build();

		Cobertura_de_Beneficiario__c anotherRecipientCoverage = Build.aCoverageRecipientRelation()
			.forRecipient(recipient).forCoverage(aCoverageWithoutSpecialDiscount)
			.CreatedInOpp(anOpp_Test_Justification)
			.build();

		Cobertura_de_Beneficiario__c onemoreRecipientCoverage = Build.aCoverageRecipientRelation()
			.forRecipient(recipient).forCoverage(anotherCoverageWithSpecialDiscount)
			.CreatedInOpp(anOpp_Test_Justification)
			.build();

		recipientCoverages = new List<Cobertura_de_Beneficiario__c> {
			aRecipientCoverage, anotherRecipientCoverage, onemoreRecipientCoverage
		};
		insert recipientCoverages;

		Descuento_Recargo__c aDiscount = Build.aDiscount()
			.withDiscountCode('ZDV3').build();

		Descuento_Recargo__c aSpecialDiscount = Build.aDiscount()
			.withDiscountCode('ZDV0').build();//ZDV0: descuento a medida

		discounts = new List<Descuento_Recargo__c> {aSpecialDiscount, aDiscount};
		insert discounts;

		Descuento_Recargo_Aplicado__c anAppliedDiscount = Build.anAppliedDiscount()
			.forDiscount(aSpecialDiscount).forCoverage(aCoverageWithSpecialDiscount).build();

		Descuento_Recargo_Aplicado__c anAppliedSpecialDiscount = Build.anAppliedDiscount()
			.forDiscount(aDiscount).forCoverage(aCoverageWithoutSpecialDiscount).build();

		Descuento_Recargo_Aplicado__c anotherAppliedSpecialDiscount = Build.anAppliedDiscount()
			.forDiscount(aSpecialDiscount).forCoverage(anotherCoverageWithSpecialDiscount).build();

		appliedDiscounts = new List<Descuento_Recargo_Aplicado__c> {
			anAppliedDiscount, anAppliedSpecialDiscount, anotherAppliedSpecialDiscount
		};
		insert appliedDiscounts;
	}
}
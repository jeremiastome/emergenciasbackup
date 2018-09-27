@isTest
private class Oportunidad_enviarAprobacionConTest {
	/*
	  private static testMethod void itShouldBePosibleToSendAnOpportunityForApproval() {
	  Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount)
	  .withWarningsValidated().withDischargeTypeNew().build();
	  insert anOpportunity;
	  addProductToOpportunity(anOpportunity);

	  String result = Oportunidad_enviarAprobacionController.sendForApproval(anOpportunity.Id);

	  System.assertEquals(Label.Oportunidad_enviada_a_aprobacion, result);

	  List<ProcessInstance> approvalStatuses = [
	  SELECT Id, TargetObjectId, Status
	  FROM ProcessInstance
	  ];

	  System.assertEquals(1, approvalStatuses.size());
	  System.assertEquals(anOpportunity.Id, approvalStatuses[0].TargetObjectId);
	  }
	 */
	static testMethod void ifTheAccountOpportunityDoesntHaveCertainFieldItShouldntBeSentForApproval() {

		anAccount.BillingCity = null;
		anAccount.Condicion_IVA__c = null;

		aPersonAccount.Tipo_de_Documento__c = null;
		aPersonAccount.Numero_de_Documento__c = null;
		update new Account[] { anAccount, aPersonAccount };

		Opportunity oppForAccount = Build.anOpportunity()
		.withWarningsValidated()
		.withDischargeTypeNew()
        .withSomeSalesHierarchy()
		.withSellersGroup('Z2')
		.forAccount(anAccount)
		.build();
		Opportunity oppForPersonAccount = Build.anOpportunity()
		.withWarningsValidated()
		.withDischargeTypeNew()
		.withSellersGroup('Z2')
		.forAccount(aPersonAccount)
        .withSomeSalesHierarchy()
		.build();

		insert new Opportunity[] { oppForAccount, oppForPersonAccount };


		addProductToOpportunity(oppForAccount);
		addProductToOpportunity(oppForPersonAccount);

		List<Cobertura__c> coverages = [Select id
		                                FROM Cobertura__c

		                               ];

		List<Beneficiario__c> recipients = [SELECT id
		                                    FROM Beneficiario__c
		                                   ];

		List<Cobertura_de_Beneficiario__c> relation = new List<Cobertura_de_Beneficiario__c> ();

		for (Beneficiario__c recipient : recipients) {
			for (Cobertura__c coverage : coverages) {
				Cobertura_de_Beneficiario__c recipientCoverage = Build.aCoverageRecipientRelation()
				.forCoverage(coverage)
				.forRecipient(recipient)
				.build();
				relation.add(recipientCoverage);
			}

		}
		insert relation;

		Test.startTest();
		String resultAcc = Oportunidad_enviarAprobacionController.sendForApproval(oppForAccount.Id);
		String resultPersonAcc = Oportunidad_enviarAprobacionController.sendForApproval(oppForPersonAccount.Id);
		Test.stopTest();



		List<ProcessInstance> approvalStatuses = [
		                                          SELECT Id, TargetObjectId
		                                          FROM ProcessInstance
		                                         ];

		System.assertEquals(0, approvalStatuses.size());
		System.assertEquals(
		                    String.format(
		                                  Label.EnviarAprobacionFaltanCampos,
		                                  new String[] { 'la cuenta', 'Dirección<br/> Condición de IVA' }
		),
		                    resultAcc
		);

		System.assertEquals(
		                    String.format(
		                                  Label.EnviarAprobacionFaltanCampos,
		                                  new String[] { 'la cuenta', 'Tipo de documento<br/> Numero de documento' }
		),
		                    resultPersonAcc
		);
	}

	static testmethod void ifTheContractHaveARecipientWithoutProduct() {

		Contrato__c contract = Build.aContract()
		.forAccount(anAccount)
		.withUniqueNumberLetter('A')
        .withUniqueNumber()
		.build();
		insert contract;

		Opportunity opp = Build.anOpportunity()
		.withWarningsValidated()
		.withSellersGroup('Z2')
        .withSomeSalesHierarchy()
		.forContract(contract)
		.forAccount(anAccount)
		.build();
		insert opp;


		Titular__c holder = Build.aHolder()
		.forAccount(anAccount)
		.forOpportunity(opp)
		.forContract(contract)
		.build();
		insert holder;

		Beneficiario__c recipient = Build.aRecipient()
		.forContract(contract)
		.forHolder(holder)
		.forOpportunity(opp)
		.build();

		Beneficiario__c otherRecipient = Build.aRecipient()
		.forContract(contract)
		.forHolder(holder)
		.forOpportunity(opp)
		.build();
		insert new Beneficiario__c[] { recipient, otherRecipient };
		addProductToOpportunity(opp);

		List<Cobertura__c> coverages = [Select id, Cantidad_de_capitas__c
		                         FROM Cobertura__c
		                         WHERE Contrato__c = :contract.Id];

        List<Cobertura_de_Beneficiario__c> recipientCoverages = new List<Cobertura_de_Beneficiario__c> ();

        for (Cobertura__c coverage : coverages) {
            Cobertura_de_Beneficiario__c coverageRecipient = Build.aCoverageRecipientRelation().forCoverage(coverage)
            .forRecipient(recipient)
            .build();
            recipientCoverages.add(coverageRecipient);
			System.debug(coverage.Cantidad_de_capitas__c);
        }

        insert recipientCoverages;

		Test.startTest();
		String result = Oportunidad_enviarAprobacionController.sendForApproval(opp.Id);
		Test.stopTest();



		List<ProcessInstance> approvalStatuses = [
		                                          SELECT Id, TargetObjectId
		                                          FROM ProcessInstance
		                                         ];

		System.assertEquals(Label.EnviarAprobacionSinBeneficiarioAsociado, result);

	}

	static testmethod void ifTheCoverageDontHaveRelationWithARecipient() {

		Contrato__c contract = Build.aContract()
		.forAccount(anAccount)
		.withUniqueNumberLetter('A')
        .withUniqueNumber()
		.build();
		insert contract;

		Opportunity opp = Build.anOpportunity()
		.withWarningsValidated()
        .withSomeSalesHierarchy()
		.withSellersGroup('Z2')
		.forContract(contract)
		.forAccount(anAccount)
		.build();
		insert opp;


		Titular__c holder = Build.aHolder()
		.forAccount(anAccount)
		.forOpportunity(opp)
		.forContract(contract)
		.build();
		insert holder;

		addProductToOpportunity(opp);
		addProductToOpportunity(opp);

		Cobertura__c coverage = [Select id
		                         FROM Cobertura__c
		                         WHERE Contrato__c = :contract.Id
		                         LIMIT 1];

		List<Beneficiario__c> recipients = [SELECT id
		                                    FROM Beneficiario__c
		                                    WHERE Titular__c = :holder.id];

		List<Cobertura_de_Beneficiario__c> relation = new List<Cobertura_de_Beneficiario__c> ();

		for (Beneficiario__c recipient : recipients) {
			Cobertura_de_Beneficiario__c recipientCoverage = Build.aCoverageRecipientRelation()
			.forCoverage(coverage)
			.forRecipient(recipient)
			.build();
			relation.add(recipientCoverage);

		}
		insert relation;

		Test.startTest();
		String result = Oportunidad_enviarAprobacionController.sendForApproval(opp.Id);
		Test.stopTest();

		List<ProcessInstance> approvalStatuses = [
		                                          SELECT Id, TargetObjectId
		                                          FROM ProcessInstance
		                                         ];

		System.assertEquals(Label.EnviarAprobacionFaltaProductos, result);
	}



	static testMethod void theOpportunityShouldHaveASellersGroupForItToBeSentForApproval() {
        anAccount.Comprobar_cierre_primera_oportunidad__c=true;
        update anAccount;

		Opportunity oppWithoutContract = Build.anOpportunity()
		.withWarningsValidated()
		.withDischargeTypeNew()
		.forAccount(anAccount)
        .withSomeSalesHierarchy()
		.build();
        oppWithoutContract.Grupo_de_Vendedores__c=null;
		insert oppWithoutContract;

		addProductToOpportunity(oppWithoutContract);
		Cobertura__c coverage = [Select id
		                         FROM Cobertura__c
                                 ORDER BY CreatedDate ASC
                                 LIMIT 1
		                        ];

		Beneficiario__c recipient = [SELECT id
		                             FROM Beneficiario__c
		                            ];
		Cobertura_de_Beneficiario__c relation = Build.aCoverageRecipientRelation().forCoverage(coverage).forRecipient(recipient).build();
		insert relation;

		Test.startTest();
		String result = Oportunidad_enviarAprobacionController.sendForApproval(oppWithoutContract.Id);
		Test.stopTest();


		List<ProcessInstance> approvalStatuses = [
		                                          SELECT Id, TargetObjectId
		                                          FROM ProcessInstance
		                                         ];

		System.assertEquals('Falta Grupo de vendedor en la oportunidad, dé aviso a su supervisor para contactarse con el administrador.'
                            ,result);
	}

	static testMethod void ifTheOpportunityIsASaleWithoutAContractItShouldHaveAnAmountForItToBeSentForApproval() {

		Opportunity oppWithoutContract = Build.anOpportunity()
		.withWarningsValidated()
		.withDischargeTypeNew()
		.forAccount(anAccount)
        .withSomeSalesHierarchy()
        .withSomeSalesHierarchy()
		.withSellersGroup('Z2')
		.saleWithoutContract()
		.build();
		insert oppWithoutContract;

		addProductToOpportunity(oppWithoutContract);

		List<Cobertura__c> coverages = [Select id
		                                FROM Cobertura__c

		                               ];

		List<Beneficiario__c> recipients = [SELECT id
		                                    FROM Beneficiario__c
		                                   ];

		List<Cobertura_de_Beneficiario__c> relation = new List<Cobertura_de_Beneficiario__c> ();

		for (Beneficiario__c recipient : recipients) {
			for (Cobertura__c coverage : coverages) {
				Cobertura_de_Beneficiario__c recipientCoverage = Build.aCoverageRecipientRelation()
				.forCoverage(coverage)
				.forRecipient(recipient)
				.build();
				relation.add(recipientCoverage);
			}

		}
		insert relation;
		Test.startTest();
		String result = Oportunidad_enviarAprobacionController.sendForApproval(oppWithoutContract.Id);
		Test.stopTest();

		List<ProcessInstance> approvalStatuses = [
		                                          SELECT Id, TargetObjectId
		                                          FROM ProcessInstance
		                                         ];

		System.assertEquals(
		                    String.format(
		                                  Label.EnviarAprobacionFaltanCampos,
		                                  new String[] { 'la oportunidad', 'Importe' }
		),
		                    result
		);
	}

	static testMethod void theOpportunitysContractShouldHaveCertainFieldsForItToBeSentForApproval() {

		Opportunity anOpportunity = Build.anOpportunity()
		.forAccount(anAccount)
		.withWarningsValidated()
        .withSomeSalesHierarchy()
		.withSellersGroup('Z2')
		.withDischargeTypeNew()
		.build();
		insert anOpportunity;

		addProductToOpportunity(anOpportunity);

		Contrato__c aContract = [
		                         SELECT Id
		                         FROM Contrato__c
		                         WHERE Id IN(SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		                        ];

		aContract.Condicion_de_pago__c = null;
		aContract.Forma_de_Pago__c = null;
		update aContract;


		List<Cobertura__c> coverages = [Select id
		                                FROM Cobertura__c

		                               ];

		List<Beneficiario__c> recipients = [SELECT id
		                                    FROM Beneficiario__c
		                                   ];

		List<Cobertura_de_Beneficiario__c> relation = new List<Cobertura_de_Beneficiario__c> ();

		for (Beneficiario__c recipient : recipients) {
			for (Cobertura__c coverage : coverages) {
				Cobertura_de_Beneficiario__c recipientCoverage = Build.aCoverageRecipientRelation()
				.forCoverage(coverage)
				.forRecipient(recipient)
				.build();
				relation.add(recipientCoverage);
			}

		}
		insert relation;

		Test.startTest();
		String result = Oportunidad_enviarAprobacionController.sendForApproval(anOpportunity.Id);
		Test.stopTest();

		List<ProcessInstance> approvalStatuses = [
		                                          SELECT Id, TargetObjectId
		                                          FROM ProcessInstance
		                                         ];

		System.assertEquals(
		                    String.format(
		                                  Label.EnviarAprobacionFaltanCampos,
		                                  new String[] { 'el contrato', 'Forma de pago<br/> Condicion de pago' }
		),
		                    result
		);
	}

	static testMethod void theOpportunitysContractShouldHaveRecipientsForItToBeSentForApproval() {

		Opportunity anOpportunity = Build.anOpportunity()
		.forAccount(anAccount)
		.withWarningsValidated()
		.withSellersGroup('Z2')
		.withDischargeTypeNew()
        .withSomeSalesHierarchy()
		.build();
		insert anOpportunity;

		addProductToOpportunity(anOpportunity);

		Beneficiario__c recipients = [
		                              SELECT Id
		                              FROM Beneficiario__c
		                              WHERE Contrato__c IN(SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		                             ];



		delete recipients;

		Test.startTest();
		String result = Oportunidad_enviarAprobacionController.sendForApproval(anOpportunity.Id);
		Test.stopTest();

		List<ProcessInstance> approvalStatuses = [
		                                          SELECT Id, TargetObjectId
		                                          FROM ProcessInstance
		                                         ];

		System.assertEquals(Label.EnviarAprobacionFaltanBeneficiarios, result);
	}

	private static testMethod void anOpportunityThatHasntHadItsWarningsValidatedShouldNotBeSentForApproval() {
		Opportunity anOpportunity = Build.anOpportunity()
		.forAccount(anAccount)
		.withoutWarningsValidated()
		.withSellersGroup('Z2')
        .withSomeSalesHierarchy()
		.withDischargeTypeNew()
		.build();
		insert anOpportunity;
		addProductToOpportunity(anOpportunity);

		List<Cobertura__c> coverages = [Select id
		                                FROM Cobertura__c

		                               ];

		List<Beneficiario__c> recipients = [SELECT id
		                                    FROM Beneficiario__c
		                                   ];

		List<Cobertura_de_Beneficiario__c> relation = new List<Cobertura_de_Beneficiario__c> ();

		for (Beneficiario__c recipient : recipients) {
			for (Cobertura__c coverage : coverages) {
				Cobertura_de_Beneficiario__c recipientCoverage = Build.aCoverageRecipientRelation()
				.forCoverage(coverage)
				.forRecipient(recipient)
				.build();
				relation.add(recipientCoverage);
			}

		}
		insert relation;

		String result = Oportunidad_enviarAprobacionController.sendForApproval(anOpportunity.Id);

		List<ProcessInstance> approvalStatuses = [
		                                          SELECT Id, TargetObjectId
		                                          FROM ProcessInstance
		                                         ];

		System.assertEquals(0, approvalStatuses.size());
		System.assertEquals(Label.Aprobacion_no_enviado_falta_validar_advertencias, result);
	}

	private static testMethod void ifTheOpportunityHasUnresolvedWarningsItShouldNotBeSentForApproval() {
		Opportunity anOpportunity = Build.anOpportunity()
		.forAccount(anAccount)
		.withSellersGroup('Z2')
		.withWarningsValidated()
		.withDischargeTypeNew()
        .withSomeSalesHierarchy()
		.build();
		insert anOpportunity;
		addProductToOpportunity(anOpportunity);
		Advertencia__c aWarning = Build.aWarning().forOpportunity(anOpportunity)
		.withWarningTypeNotProfitable().build();
		insert aWarning;

		List<Cobertura__c> coverages = [Select id
		                                FROM Cobertura__c

		                               ];

		List<Beneficiario__c> recipients = [SELECT id
		                                    FROM Beneficiario__c
		                                   ];

		List<Cobertura_de_Beneficiario__c> relation = new List<Cobertura_de_Beneficiario__c> ();

		for (Beneficiario__c recipient : recipients) {
			for (Cobertura__c coverage : coverages) {
				Cobertura_de_Beneficiario__c recipientCoverage = Build.aCoverageRecipientRelation()
				.forCoverage(coverage)
				.forRecipient(recipient)
				.build();
				relation.add(recipientCoverage);
			}

		}
		insert relation;

		String result = Oportunidad_enviarAprobacionController.sendForApproval(anOpportunity.Id);

		List<ProcessInstance> approvalStatuses = [
		                                          SELECT Id, TargetObjectId, ProcessDefinition.DeveloperName
		                                          FROM ProcessInstance
		                                         ];

		System.assertEquals(0, approvalStatuses.size());
		System.assertEquals(Label.Aprobacion_no_enviado_tiene_advertencias_sin_resolver, result);
	}

	private static testMethod void ifTheOpportunityHasUnresolvedWarningsButHasAJustificationItShouldBeSentForApproval() {
		Opportunity anOpportunity = Build.anOpportunity()
		.forAccount(anAccount)
		.withSellersGroup('Z2')
        .withSomeSalesHierarchy()
		.withWarningsValidated()
		.withDischargeTypeNew()
		.withWarningJustification('some excuse.')
		.build();
		insert anOpportunity;
		addProductToOpportunity(anOpportunity);
		Advertencia__c aWarning = Build.aWarning().forOpportunity(anOpportunity)
		.withWarningTypeNotProfitable().build();
		insert aWarning;

		List<Cobertura__c> coverages = [Select id
		                                FROM Cobertura__c

		                               ];

		List<Beneficiario__c> recipients = [SELECT id
		                                    FROM Beneficiario__c
		                                   ];

		List<Cobertura_de_Beneficiario__c> relation = new List<Cobertura_de_Beneficiario__c> ();

		for (Beneficiario__c recipient : recipients) {
			for (Cobertura__c coverage : coverages) {
				Cobertura_de_Beneficiario__c recipientCoverage = Build.aCoverageRecipientRelation()
				.forCoverage(coverage)
				.forRecipient(recipient)
				.build();
				relation.add(recipientCoverage);
			}

		}
		insert relation;

		String result = Oportunidad_enviarAprobacionController.sendForApproval(anOpportunity.Id);

		System.assertEquals(Label.Oportunidad_enviada_a_aprobacion, result);

		List<ProcessInstance> approvalStatuses = [
		                                          SELECT Id, TargetObjectId
		                                          FROM ProcessInstance
		                                         ];

		System.assertEquals(1, approvalStatuses.size());
		System.assertEquals(anOpportunity.Id, approvalStatuses[0].TargetObjectId);
		System.assertEquals(true, Approval.isLocked(anOpportunity.Id));
	}

	private static testMethod void ifTheOpportunityIsAlreadyWaitingForApprovalNoNewRequestShouldBeMade() {
		Opportunity anOpportunity = Build.anOpportunity()
		.forAccount(anAccount)
		.withSellersGroup('Z2')
		.withWarningsValidated()
        .withSomeSalesHierarchy()
		.withDischargeTypeNew()
		.withWarningJustification('some excuse.')
		.build();
		insert anOpportunity;
		addProductToOpportunity(anOpportunity);
		Advertencia__c aWarning = Build.aWarning().forOpportunity(anOpportunity)
		.withWarningTypeNotProfitable().build();
		insert aWarning;

		List<Cobertura__c> coverages = [Select id
		                                FROM Cobertura__c

		                               ];

		List<Beneficiario__c> recipients = [SELECT id
		                                    FROM Beneficiario__c
		                                   ];

		List<Cobertura_de_Beneficiario__c> relation = new List<Cobertura_de_Beneficiario__c> ();

		for (Beneficiario__c recipient : recipients) {
			for (Cobertura__c coverage : coverages) {
				Cobertura_de_Beneficiario__c recipientCoverage = Build.aCoverageRecipientRelation()
				.forCoverage(coverage)
				.forRecipient(recipient)
				.build();
				relation.add(recipientCoverage);
			}

		}
		insert relation;

		Oportunidad_enviarAprobacionController.sendForApproval(anOpportunity.Id);

		String result = Oportunidad_enviarAprobacionController.sendForApproval(anOpportunity.Id);

		System.assertEquals(Label.Error_la_oportunidad_ya_se_encuentra_esperando_aprobacion, result);

		List<ProcessInstance> approvalStatuses = [
		                                          SELECT Id, TargetObjectId
		                                          FROM ProcessInstance
		                                         ];

		System.assertEquals(1, approvalStatuses.size());
	}

	private static testMethod void ifTheOpportunityHasNoProductsItShouldntBeSentForApproval() {
		Opportunity anOpportunity = Build.anOpportunity()
		.forAccount(anAccount)
		.withSellersGroup('Z2')
		.withWarningsValidated()
        .withSomeSalesHierarchy()
		.withDischargeTypeNew()
		.build();
		insert anOpportunity;

		Contrato__c aContract = [
		                         SELECT Id
		                         FROM Contrato__c
		                         WHERE Id IN(SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		                        ];

		Titular__c holder = [
		                     SELECT Id
		                     FROM Titular__c
		                     WHERE Contrato__c = :aContract.Id
		                     LIMIT 1
		                    ];

		aContract.Condicion_de_pago__c = 'C010';
		aContract.Forma_de_Pago__c = 'B';
		update aContract;

		Beneficiario__c aRecipient = Build.aRecipient().forHolder(holder).forContract(aContract).forAccount(anAccount).build();
		insert aRecipient;

        Product2 aProduct = Build.aProduct().withName('Prod').build();
		insert aProduct;

		List<Cobertura__c> coverages = [Select id
		                                FROM Cobertura__c

		                               ];

		List<Beneficiario__c> recipients = [SELECT id
		                                    FROM Beneficiario__c
		                                   ];

		List<Cobertura_de_Beneficiario__c> relation = new List<Cobertura_de_Beneficiario__c> ();

		for (Beneficiario__c recipient : recipients) {
			for (Cobertura__c coverage : coverages) {
				Cobertura_de_Beneficiario__c recipientCoverage = Build.aCoverageRecipientRelation()
				.forCoverage(coverage)
				.forRecipient(recipient)
				.build();
				relation.add(recipientCoverage);
			}

		}
		insert relation;

		Test.startTest();
		String result = Oportunidad_enviarAprobacionController.sendForApproval(anOpportunity.Id);
		Test.stopTest();

		List<ProcessInstance> approvalStatuses = [
		                                          SELECT Id, TargetObjectId, ProcessDefinition.DeveloperName
		                                          FROM ProcessInstance
		                                         ];

		System.assertEquals(0, approvalStatuses.size());
		System.assertEquals(Label.Aprovacion_no_enviado_falta_agregar_productos, result);
	}

	static testmethod void ifTheOppRequiresDeliveryAndHasNoPostalCodeItShouldntBeSentForApproval(){
		Opportunity anOpportunity = Build.anOpportunity()
		.forAccount(anAccount)
		.withDischargeTypeNew()
        .withSomeSalesHierarchy()
		.withSellersGroup('Z2')
		.withWarningsValidated()
		.build();
		insert anOpportunity;

		addProductThatRequiresDeliveryToOpportunity(anOpportunity);
		List<Cobertura__c> coverages = [Select id
		                                FROM Cobertura__c

		                               ];

		List<Beneficiario__c> recipients = [SELECT id
		                                    FROM Beneficiario__c
		                                   ];

		List<Cobertura_de_Beneficiario__c> relation = new List<Cobertura_de_Beneficiario__c> ();

		for (Beneficiario__c recipient : recipients) {
			for (Cobertura__c coverage : coverages) {
				Cobertura_de_Beneficiario__c recipientCoverage = Build.aCoverageRecipientRelation()
				.forCoverage(coverage)
				.forRecipient(recipient)
				.createdInOpp(anOpportunity)
				.build();
				relation.add(recipientCoverage);
			}

		}
		insert relation;

		Oportunidad_enviarAprobacionController.sendForApproval(anOpportunity.Id);

		String result = Oportunidad_enviarAprobacionController.sendForApproval(anOpportunity.Id);

		System.assertEquals(String.format(Label.EnviarAprobacionFaltanCampos,
		                                  new String[] { 'la cuenta', 'Código Postal'}),
							result);

	}

	//==========================================================================
	private static void addProductToOpportunity(Opportunity anOpportunity) {
		Product2 aProduct = Build.aProduct().withName('Prod').build();
		insert aProduct;
		Contrato__c aContract = [
		                         SELECT Id
		                         FROM Contrato__c
		                         WHERE Id IN(SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		                        ];
		makeContractValid(aContract, anOpportunity);

		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract)
		.forProduct(aProduct).build();
		insert aCoverage;
	}

	private static void addProductThatRequiresDeliveryToOpportunity(Opportunity anOpportunity){
		Product2 aProduct = Build.aProduct().withName('Prod').build();
		aProduct.Requiere_envio_fisico__c = TRUE;
		insert aProduct;
		Contrato__c aContract = [
		                         SELECT Id
		                         FROM Contrato__c
		                         WHERE Id IN(SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		                        ];

		makeContractValid(aContract, anOpportunity);

		Cobertura__c aCoverage = Build.aCoverage().forContract(aContract)
		.forProduct(aProduct).build();
		insert aCoverage;
	}

	private static void makeContractValid(Contrato__c aContract, Opportunity opp) {

		Titular__c holder = [
		                     SELECT Id
		                     FROM Titular__c
		                     WHERE Contrato__c = :aContract.Id
		                     LIMIT 1
		                    ];

		aContract.Condicion_de_pago__c = 'C010';
		aContract.Forma_de_Pago__c = 'B';
		update aContract;

		Beneficiario__c recipient = Build.aRecipient().forHolder(holder).forContract(aContract).forAccount(anAccount).build();
		insert recipient;

        Product2 aProduct = Build.aProduct().withName('Prod').build();
		insert aProduct;

        Cobertura__c coverage = build.aCoverage().forContract(aContract).forProduct(aProduct).build();
        insert coverage;

       	Cobertura_de_beneficiario__c recipientCoverage = build.aCoverageRecipientRelation().build();
        recipientCoverage.Cobertura__c=coverage.id;
        recipientCoverage.Beneficiario__c=recipient.id;
        recipientCoverage.Creado_en_Oportunidad__c=opp.id;
        insert recipientCoverage;
	}
	//==========================================================================
	static Account anAccount, aPersonAccount;
	static Usuario_no_envia_a_SAP__c customSetting;
	static {
		anAccount = Build.anAccount()
		.withBillingCity('Test')
		.withBillingCountry('test')
		.withBillingStreet('test')
		.withBillingState('test')
		.withTaxCondition('02')
		.build();
        anAccount.Comprobar_cierre_primera_oportunidad__c =true;
        anAccount.Sociedad__c='0010';
		aPersonAccount = Build.anAccount().isPersonAccount()
		.withBillingCity('Test')
		.withBillingCountry('test')
		.withBillingStreet('test')
		.withBillingState('test')
		.withTaxCondition('05')
		.withDocumentType('DNI')
		.withDocumentNumber('41244244')
		.build();
        aPersonAccount.Sociedad__c='0010';
		insert new Account[] { anAccount, aPersonAccount };
		customSetting = new Usuario_no_envia_a_SAP__c();
		customSetting.Name = UserInfo.getUserName();
		customSetting.No_envia__c = true;
		insert customSetting;


	}
}
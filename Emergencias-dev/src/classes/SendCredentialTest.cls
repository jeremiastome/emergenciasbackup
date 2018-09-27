@isTest
public class SendCredentialTest {

	private static testMethod void whenAnEmailIsCreatedToBeSentToAClient_ItIsCreatedWithTheClientsMailAddress() {
		Opportunity anOpportunity = Build.anOpportunity().forAccount(accountTest).withDischargeTypeNew().build();

		insert anOpportunity;
		RecordType consumidorFinal = [SELECT ID
									  FROM RecordType
									  WHERE DeveloperName='Venta_consumidor_final'
									  LIMIT 1];

		Contrato__c aContract = [SELECT Id
					  FROM Contrato__c
					  WHERE Id IN(SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)];

		Test.StartTest();
		Messaging.SingleEmailMessage mail = SendCredential.buildSingleEmailMessage(aContract.id);
		Test.StopTest();

		EmailTemplate et=[Select id from EmailTemplate where name = 'Credencial provisoria v2' limit 1];
		System.assertEquals(1, mail.getToAddresses().size());
		System.assertEquals('account.test@gmail.com', mail.getToAddresses()[0]);
		System.assertEquals(et.id, mail.getTemplateId());
	}

	private static testMethod void ifAOppornityIsWon_aMailIsSendeToTheClientOfTheOpportunity() {
		instanciateCoverageRecipientRelation(accountTest);
		Cobertura_de_Beneficiario__c coberturaBeneficiario = [SELECT id
																	FROM Cobertura_de_Beneficiario__c
																	LIMIT 1];
		Id coberturaBeneficiarioId = [SELECT id FROM Contrato__c LIMIT 1].id;
		List<Id> idsCoberturaBeneficiario = new List<Id> {coberturaBeneficiario.id};
		SendCredential.sendEmail(coberturaBeneficiarioId , idsCoberturaBeneficiario);
	}

	private static testMethod void itShouldGenetateACredential() {
		instanciateCoverageRecipientRelation(accountTest);
		Cobertura_de_Beneficiario__c coberturaBeneficiario =
			[SELECT id
				FROM Cobertura_de_Beneficiario__c
				WHERE Cobertura__r.Requiere_Credencial_Provisoria__c = True
				LIMIT 1
			];
		System.assertEquals(null, SendCredential.generateCredential(coberturaBeneficiario.id));
	}

	private static testMethod void thisShouldKnowIfTheConfigurationAllowsToSendCredentials() {
		System.assertEquals(true, SendCredential.canSendProvisoryCredential());
	}

	private static testMethod void shouldBeAbleToFilterCoverageRecipientRelationByContractId() {
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		instanciateCoverageRecipientRelation(anAccount);
		Account anAccount2 = Build.anAccount().build();
		insert anAccount2;
		instanciateCoverageRecipientRelation(anAccount2);

		List<Cobertura_de_Beneficiario__c> coberturasBeneficiario = [SELECT id, Beneficiario__r.Contrato__c
																	FROM Cobertura_de_Beneficiario__c
																	WHERE Cobertura__r.Requiere_Credencial_Provisoria__c = True
																	];
		System.assertEquals(4, coberturasBeneficiario.size());

		Map<id, List<id>> idCoberturasPorIdContrato = SendCredential.filterByContract(coberturasBeneficiario);
		System.assertEquals(2, idCoberturasPorIdContrato.size());
	}

	static Account accountTest;
	static Product2 producto;

	static {
		Numeros_de_contratos__c numberSettings = new Numeros_de_contratos__c();
		numberSettings.Name = 'X';
		numberSettings.Numero_maximo__c = 453432;
		insert numberSettings;

		Numeros_de_contratos__c numberSettings2 = new Numeros_de_contratos__c();
		numberSettings2.Name = 'D';
		numberSettings2.Numero_maximo__c = 453432;
		insert numberSettings2;


		insert new Configuracion_para_envio_de_credenciales__c(Envia__c = true);
		accountTest = Build.anAccount().withEmail('account.test@gmail.com').build();
		accountTest.Comprobar_cierre_primera_oportunidad__c=true;
		insert accountTest;

		producto = Build.aProduct()
		.needsCredential()
		.build();

		insert producto;
	}

	private static void instanciateCoverageRecipientRelation(Account anAccount) {


		Product2 producto = Build.aProduct().needsCredential().build();

		insert producto;
		Opportunity anOpportunity = Build.anOpportunity().forAccount(anAccount).
			withDischargeTypeNew().build();

        insert anOpportunity;
		RecordType consumidorFinal = [SELECT ID
                                      FROM RecordType
                                      WHERE DeveloperName='Venta_consumidor_final'
                                      LIMIT 1];

		Contrato__c aContract = [SELECT Id
		              FROM Contrato__c
		              WHERE Id IN(SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)];

		Titular__c aHolder = [//Created by a process
			SELECT Id, Numero_de_Titular__c, Ult_Numero_de_beneficiario__c
			FROM Titular__c
			WHERE Contrato__c = :aContract.Id
		];

        Cobertura__c coverage = build.aCoverage().withName('Coverage ')
									.needsProvisoryCredential()
                					.forProduct(Producto).forContract(aContract).build();
        insert coverage;

        Beneficiario__c recipientTest = build.aRecipient()
											.withInactiveStatus()
                							.forContract(aContract)
                							.forHolder(aHolder)
            								.withProvince('Capital Federal')
            								.withIVATreatment('BE')
                							.build();
        insert recipientTest;

        Cobertura_de_beneficiario__c coverageRecipientRelation = build.aCoverageRecipientRelation()
                					.forRecipient(recipientTest)
                					.forCoverage(coverage)
									.CreatedInOpp(anOpportunity)
									.build();
        insert coverageRecipientRelation;

		Cobertura__c coverage2 = build.aCoverage().withName('Coverage ')
									.needsProvisoryCredential()
                					.forProduct(producto).forContract(aContract).build();
        insert coverage2;

        Beneficiario__c recipientTest2 = build.aRecipient()
											.withInactiveStatus()
                							.forContract(aContract)
                							.forHolder(aHolder)
            								.withProvince('Capital Federal')
            								.withIVATreatment('BE')
                							.build();
        insert recipientTest2;

        Cobertura_de_beneficiario__c coverageRecipientRelation2 = build.aCoverageRecipientRelation()
                					.forRecipient(recipientTest2)
                					.forCoverage(coverage2)
									.CreatedInOpp(anOpportunity)
									.build();
        insert coverageRecipientRelation2;
	}
}
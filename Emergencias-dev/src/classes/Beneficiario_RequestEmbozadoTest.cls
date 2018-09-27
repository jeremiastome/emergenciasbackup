@isTest
private class Beneficiario_RequestEmbozadoTest {

	@isTest
	private static void cuandoFuncionanLasQueriesQueSeNecesitanParaTraerATodosLosBeneficiarios() {

		List<Beneficiario_RequestEmbozadoController.wrapperBeneficiario> wrapper = new List<Beneficiario_RequestEmbozadoController.wrapperBeneficiario> ();

		wrapper = Beneficiario_RequestEmbozadoController.getWrapperList(String.valueOf(firstCaso.id));

		System.assertEquals(false, wrapper.isEmpty());

	}

	@IsTest
	private static void afterUpdateRecipentsWhenTheButtonSaveIsClicked() {
		
        List<Beneficiario__c> updateBeneficiarios = new List <Beneficiario__c>();
        
        updateBeneficiarios.add(aRecipient);
    
        string respuesta = Beneficiario_RequestEmbozadoController.updateSelectedBeneficiarios(updateBeneficiarios, firstCaso.Id);
    
        System.assertEquals('Success', respuesta );
        

	}

	//--------------Static content -----------------//
	static Account anAccount;
	static Case firstCaso;
	static Contrato__c firstContrato;
	static Titular__c aHolder;
	static Opportunity anOpportunity;
	static Cobertura_de_Beneficiario__c coberturaBeneficiario;
	static Cobertura__c cobertura;
	static Pedido_de_Embozado__c pedidoEmbozado;
	static Configuracion_embozados__c configuracion;
	static Beneficiario__c aRecipient;

	static {

		configuracion = Build.configEmbozado()
            .withName('Name')
            .withUltimoNumero(9)
		.build();

		anAccount = Build.anAccount()
			.build();
		insert anAccount;

		anOpportunity = Build.anOpportunity()
            .forAccount(anAccount)
            .build();
		insert anOpportunity;

		firstContrato = Build.aContract()
            .forAccount(anAccount)
            .build();
		insert firstContrato;

		aHolder = Build.aHolder()
            .forAccount(anAccount)
            .withUniqueCode('1234')
            .forContract(firstContrato)
            .forOpportunity(anOpportunity)
            .build();
		insert aHolder;
		
		firstCaso = Build.aCase()
            .forContract(firstContrato)
            .build();
		insert firstCaso;

		aRecipient = Build.aRecipient()
            .forContract(firstContrato)
            .forAccount(anAccount)
			.withStatus('Activo')
            .forHolder(aHolder)
            .forOpportunity(anOpportunity)
            .build();
		insert aRecipient;

		Product2 aProduct = Build.aProduct()
            .needsCredential()
            .build();
		insert aProduct;

		cobertura = Build.aCoverage()
            .forContract(firstContrato)
            .forProduct(aProduct)
            .build();

		insert cobertura;
		coberturaBeneficiario = Build.aCoverageRecipientRelation()
            .forRecipient(aRecipient)
            .forCoverage(cobertura)
            .build();

		insert coberturaBeneficiario;
	}

}
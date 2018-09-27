@IsTest public class CoberturaTriggerTest  {

    private static testMethod void ifACoverageThatHasMoreThan200BeneficiariesIsTriedToBeEliminated_ThenTheseWillBeEliminatedManually () { 
		
		System.assertEquals(300, [SELECT Id
								FROM Cobertura_de_Beneficiario__c
								WHERE Id IN :idsRecipientCoverages].size() );
		Test.startTest();
		delete coverages;
		Test.stopTest();

		System.assertEquals(0, [SELECT Id
								FROM Cobertura_de_Beneficiario__c
								WHERE Id IN :idsRecipientCoverages].size() );
	
	}
	//==========================================================================
    static Opportunity aOpportunity;
    static Account aAccount;
    static Titular__c aHolder;
    static List<Cobertura__c> coverages;
    static List<Beneficiario__c> recipients;
    static List<Cobertura_de_Beneficiario__c> recipientCoverages;
    static List<id> idsRecipientCoverages;
    static {
        
        RecordType consumidorFinal = [SELECT ID
                                      FROM RecordType
                                      WHERE DeveloperName='Venta_consumidor_final'
                                      LIMIT 1];
        
        aAccount = build.anAccount().build();
        aAccount.Comprobar_cierre_primera_oportunidad__c=true;
        insert aAccount;
        
        aOpportunity = build.anOpportunity()
            			.withRecordTypeId(consumidorFinal.id)
            			.forAccount(aAccount)
            			.withDischargeType('Nueva')
            			.build();
        
        insert aOpportunity;
        
        
        aOpportunity = [SELECT Id, Contrato__c
                        FROM Opportunity
                        WHERE Id=:aOpportunity.id];
        
        
        Contrato__c aContract = new Contrato__c();
        aContract.id = aOpportunity.Contrato__c;
        aContract.Numero_Unico_de_Contrato_Con_Sufijo__c='D12345600';
        update aContract;
        
        
        
        List<Product2> products = new List<Product2>();
        for (integer i=0; i<1; i++) {
            Product2 product = build.aProduct().withName('Test '+i).build();
            product.isActive=true;
            products.add( product );
        }
        insert products;
        
        coverages = new List<Cobertura__c>();
        for (integer i=0; i<1; i++) {
			Cobertura__c coverage = build.aCoverage().withName('Coverage '+i)
                					.forProduct(products[i]).forContract(aContract).build();
            coverages.add( coverage );
        }
        insert coverages;
        
        aHolder = [//Created by a process
			SELECT Id, Numero_de_Titular__c, Ult_Numero_de_beneficiario__c
			FROM Titular__c
			WHERE Contrato__c = :aContract.Id
		];

        recipients = new List<Beneficiario__c>();

        for (integer i=0; i<1; i++) {
        	Beneficiario__c recipient = build.aRecipient()
                							.forContract(aContract)
                							.forHolder(aHolder)
                							.build();
            recipients.add(recipient);
        }

        insert recipients;
       
        recipientCoverages = new List<Cobertura_de_Beneficiario__c>();

        for (integer i=0; i<300; i++) {
            
            recipientCoverages.add( build.aCoverageRecipientRelation()
                					.forRecipient(recipients[0])
                					.forCoverage(coverages[0])
									.build() );
            
        }
        insert recipientCoverages;


		idsRecipientCoverages= new List<Id>();
		for(Cobertura_de_Beneficiario__c recipientCoverage : recipientCoverages) {
			idsRecipientCoverages.add(recipientCoverage.id);
		}
        
    }
}
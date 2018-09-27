@isTest
private class CrearBeneficiarioControllerTest {
	@isTest
	private static void itShouldBePosibleToGetTheContractHolders() {
		//Prepare data
		Id opportunityType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Opportunity'
				AND IsActive = true
				AND DeveloperName = 'Venta_Consumidor_Final'
			LIMIT 1
		].Id;
		
		List<Account> accounts = new List<Account>();
		for(Integer i = 0; i < 5; i++) {
			accounts.add(Build.anAccount().withName('acc ' + String.valueOf(i)).build());
		}
		insert accounts;
		Opportunity anOpportunity = Build.anOpportunity().forAccount(accounts[0])
			.withDischargeTypeNew().withRecordTypeId(opportunityType).build();
		insert anOpportunity;
		Contrato__c aContract = [
			SELECT Id
			FROM Contrato__c
			WHERE Id IN (SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		];
		
		List<Titular__c> holders = new List<Titular__c>();
		for(Account anAccount : accounts) {
			holders.add(Build.aHolder().forContract(aContract).forAccount(anAccount).build());
		}
		insert holders;
		
		Map<Id, Titular__c> holdersById = new Map<Id, Titular__c>([
			SELECT Id, Cliente__r.Name
			FROM Titular__c
			WHERE Contrato__c = :aContract.Id
		]);
		
		//=========================================
		//Execution
		CrearBeneficiarioController controller = new CrearBeneficiarioController();
		controller.contractId = aContract.Id;
		
		//=========================================
		//Asserts
		System.assertEquals(holdersById.size(), controller.holders.size());
		for(SelectOption holder : controller.holders) {
			System.assert(holdersById.containsKey(holder.getValue()));
			System.assertEquals(
				holdersById.get(holder.getValue()).Cliente__r.Name,
				holder.getLabel()
			);
		}
	}
	
	@isTest
	private static void itShouldBePosibleToGetTheRecipientRecordTypesExceptMassive() {
		Map<Id, RecordType> recordTypes = new Map<Id, RecordType>([
			SELECT Id, Name
			FROM RecordType
			WHERE sObjectType = 'Beneficiario__c'
				AND IsActive = true
				AND DeveloperName != 'Padron'
		]);
		
		//=========================================
		//Execution
		CrearBeneficiarioController controller = new CrearBeneficiarioController();
		
		//=========================================
		//Asserts
		System.assertEquals(recordTypes.size(), controller.recipientTypes.size());
		for(SelectOption recipientType : controller.recipientTypes) {
			System.assert(recordTypes.containsKey(recipientType.getValue()));
			System.assertEquals(
				recordTypes.get(recipientType.getValue()).Name,
				recipientType.getLabel()
			);
		}
	}
	
	@isTest
	private static void itShouldBePosibleToPrepareTheFieldsToCreateACarRecipient() {
		//Prepare data
		CrearBeneficiarioController controller = new CrearBeneficiarioController();
		
		//=========================================
		//Execution
		ApexPages.Component generatedComponent = controller.getRecipientComponent();
		
		//=========================================
		//Asserts
		System.assertEquals(
			controller.recipientTypes.size(),
			generatedComponent.childComponents.size()
		);
	}
	
	@isTest
	private static void whenSettingARecipientWithoutContract_ItsContractIdShouldBeSet() {
		//Prepare data
		Id opportunityType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Opportunity'
				AND IsActive = true
				AND DeveloperName = 'Venta_Consumidor_Final'
			LIMIT 1
		].Id;
		
		List<Account> accounts = new List<Account>();
		for(Integer i = 0; i < 5; i++) {
			accounts.add(Build.anAccount().withName('acc ' + String.valueOf(i)).build());
		}
		insert accounts;
		Opportunity anOpportunity = Build.anOpportunity().forAccount(accounts[0])
			.withDischargeTypeNew().withRecordTypeId(opportunityType).build();
		insert anOpportunity;
		Contrato__c aContract = [
			SELECT Id
			FROM Contrato__c
			WHERE Id IN (SELECT Contrato__c FROM Opportunity WHERE Id = :anOpportunity.Id)
		];
		
		//=========================================
		//Execution
		CrearBeneficiarioController controller = new CrearBeneficiarioController();
		controller.contractId = aContract.Id;
		
		Beneficiario__c aRecipient = new Beneficiario__c();
		controller.recipientSo = aRecipient;
		
		//=========================================
		//Asserts
		System.assertEquals(aContract.Id, controller.recipientSo.Contrato__c);
	}
}
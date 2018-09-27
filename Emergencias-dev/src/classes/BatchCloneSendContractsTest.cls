@isTest
private class BatchCloneSendContractsTest {
	private static testMethod void itShouldBePosibleToCloneAndSendContracts() {
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir')
			.withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		TipoOperacionEnvioSAP__c contractConfig = new TipoOperacionEnvioSAP__c(
			Name = 'Contratos',
			Where_clause__c = 'Saltear_envio__c = 1',
			Operacion__c = 'A'
		);
		insert contractConfig;
		
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		
		RecordType contractType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Contrato__c'
				AND DeveloperName = 'Contrato'
		];
		Contrato__c aContract = Build.aContract().forAccount(anAccount)
			.withRecordType(contractType).withSkipSend(2).notWaitingToBeSent()
			.withSapSendStatus('Ok').withStatus('Baja').build();
		insert aContract;
		
		Test.startTest();
		Database.executeBatch(new BatchCloneSendContracts(), 1);
		Test.stopTest();
		
		Contrato__c theContractInDB = [
			SELECT Id, Numero_Unico_de_Contrato__c, Sufijo__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		List<Contrato__c> cloneContracts = [
			SELECT Id
			FROM Contrato__c
			WHERE Numero_Unico_de_Contrato__c = :theContractInDB.Numero_Unico_de_Contrato__c
				AND Sufijo__c = :(theContractInDB.Sufijo__c + 1)
		];
		
		System.assertEquals(1, cloneContracts.size());
		
		System.assertEquals(1, serverMock.soapRequests.size());
	}
	
	private static testMethod void ifTheOriginalContractWasntSentSuccessfullyItShouldntBeCloned() {
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir')
			.withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		TipoOperacionEnvioSAP__c contractConfig = new TipoOperacionEnvioSAP__c(
			Name = 'Contratos',
			Where_clause__c = 'Saltear_envio__c = 1',
			Operacion__c = 'A'
		);
		insert contractConfig;
		
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		
		RecordType contractType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Contrato__c'
				AND DeveloperName = 'Contrato'
		];
		Contrato__c aContract = Build.aContract().forAccount(anAccount)
			.withRecordType(contractType).withSkipSend(2).notWaitingToBeSent()
			.withSapSendStatus('Error').withStatus('Baja').build();
		insert aContract;
		
		Test.startTest();
		Database.executeBatch(new BatchCloneSendContracts(), 1);
		Test.stopTest();
		
		Contrato__c theContractInDB = [
			SELECT Id, Numero_Unico_de_Contrato__c, Sufijo__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		List<Contrato__c> cloneContracts = [
			SELECT Id
			FROM Contrato__c
			WHERE Numero_Unico_de_Contrato__c = :theContractInDB.Numero_Unico_de_Contrato__c
				AND Sufijo__c = :(theContractInDB.Sufijo__c + 1)
		];
		
		System.assertEquals(0, cloneContracts.size());
		
		System.assertEquals(0, serverMock.soapRequests.size());
	}
	
	private static testMethod void ifTheOriginalContractHasntBeenSentYetItShouldntBeCloned() {
		WebServiceSoapMock serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir')
			.withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		TipoOperacionEnvioSAP__c contractConfig = new TipoOperacionEnvioSAP__c(
			Name = 'Contratos',
			Where_clause__c = 'Saltear_envio__c = 1',
			Operacion__c = 'A'
		);
		insert contractConfig;
		
		Account anAccount = Build.anAccount().build();
		insert anAccount;
		
		RecordType contractType = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Contrato__c'
				AND DeveloperName = 'Contrato'
		];
		Contrato__c aContract = Build.aContract().forAccount(anAccount)
			.withRecordType(contractType).withSkipSend(2).waitingToBeSent()
			.withSapSendStatus('Ok').withStatus('Baja').build();
		insert aContract;
		
		Test.startTest();
		Database.executeBatch(new BatchCloneSendContracts(), 1);
		Test.stopTest();
		
		Contrato__c theContractInDB = [
			SELECT Id, Numero_Unico_de_Contrato__c, Sufijo__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		List<Contrato__c> cloneContracts = [
			SELECT Id
			FROM Contrato__c
			WHERE Numero_Unico_de_Contrato__c = :theContractInDB.Numero_Unico_de_Contrato__c
				AND Sufijo__c = :(theContractInDB.Sufijo__c + 1)
		];
		
		System.assertEquals(0, cloneContracts.size());
		
		System.assertEquals(0, serverMock.soapRequests.size());
	}
}
@isTest
public class SendContractToSAPBatchTest {
	public static testMethod void dummyTest() {
		TipoOperacionEnvioSAP__c contractConfig = new TipoOperacionEnvioSAP__c(
			Name = 'Contratos',
			Where_clause__c = 'Numero_Unico_de_Contrato_Con_Sufijo__c = \'asd\'',
			Operacion__c = 'A'
		);
		insert contractConfig;
		
		Test.startTest();
		Database.executeBatch(new SendContractToSAPBatch(), 1);
		Test.stopTest();
	}
}
@isTest
public class SendAccountToSAPBatchTest {
	public static testMethod void dummyTest(){
		TipoOperacionEnvioSAP__c contractConfig = new TipoOperacionEnvioSAP__c(
			Name = 'Cuentas',
			Where_clause__c = 'Lote_migracion__c = \'99\'',
			Operacion__c = 'A'
		);
		insert contractConfig;
		
		Test.startTest();
		Database.executeBatch(new SendAccountToSAPBatch(), 1);
		Test.stopTest();
	}
}
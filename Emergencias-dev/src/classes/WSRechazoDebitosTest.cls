@isTest
public class WSRechazoDebitosTest {
    private static testMethod void newCaseIsCreated(){
        String cuit = '20123456780';
        String cuitSAP = '2012345678'; //WITHOUT VERIFICATION CODE
        Account client = Build.anAccount().withCUILCUIT(cuit).build();
        insert client;
        
        customSetting = new Usuario_no_envia_a_SAP__c();
		customSetting.Name='emergencias@xappia.com';
		customSetting.No_envia__c=true;
		insert customSetting;
        
        String contractNumber = '112233';
        Contrato__c contract = Build.aContract().withUniqueNumberWithSufix(contractNumber).forAccount(client).build();
        insert contract;
        
        
        WSRechazoDebitos.RechazoDebito r = new WSRechazoDebitos.RechazoDebito();
        r.cliente = cuitSAP;
        r.contrato = contractNumber;
        r.codigo_tarjeta = '001';
        r.descripcion_tarjeta = 'VISA';
        r.codigo_rechazo = 'R';
        r.descripcion_rechazo = 'FALTA DE PAGO';
        
        List<WSRechazoDebitos.RechazoDebito> rech = new List<WSRechazoDebitos.RechazoDebito>();
        rech.add(r);
        
        Test.startTest();
        WSRechazoDebitos.Response res = WSRechazoDebitos.cargarRechazosDebito(rech);
        Test.stopTest();
        
        List<Case> cases = [SELECT Id, AccountId, Contrato__c, Codigo_de_Rechazo__c, Codigo_de_Tarjeta__c, Descripcion_de_Rechazo__c, Descripcion_de_Tarjeta__c, 
                            RecordType.DeveloperName FROM Case];
        system.assertEquals(1, cases.size());
        system.assertEquals(client.Id, cases[0].AccountId);
        system.assertEquals(contract.Id, cases[0].Contrato__c);
        system.assertEquals(r.codigo_tarjeta, cases[0].Codigo_de_Tarjeta__c);
        system.assertEquals(r.descripcion_tarjeta, cases[0].Descripcion_de_Tarjeta__c);
        system.assertEquals(r.codigo_rechazo, cases[0].Codigo_de_Rechazo__c);
        system.assertEquals(r.descripcion_rechazo, cases[0].Descripcion_de_Rechazo__c);
        system.assertEquals('Rechazo_de_Debito_Automatico', cases[0].RecordType.DeveloperName);
    }
    static Usuario_no_envia_a_SAP__c customSetting;
   
}
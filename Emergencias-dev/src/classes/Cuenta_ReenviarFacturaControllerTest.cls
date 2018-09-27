@isTest
public class Cuenta_ReenviarFacturaControllerTest {
    public static testMethod void laFacturaSePuedeReenviar(){
        Configuracion_SAP__c sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').build();
        insert sapSettings;
        
        WebServiceSoapMock mock = new WebServiceSoapMock();
        Test.setMock(System.WebServiceMock.class, mock);
        
        WSSAPReenvioFacturas.DT_Reenvio_Facturas_Response resp = new WSSAPReenvioFacturas.DT_Reenvio_Facturas_Response();
        resp.Msg = new WSSAPReenvioFacturas.Msg_element();
        
        mock.responseObj = resp;

        Test.startTest();
        Cuenta_ReenviarFacturaController.resendFact('1234', 'mail@test.com');
        Test.stopTest();
    }
}
@isTest
public class EstadoDeCuentaClienteTest  {
    
    // Estado de cuenta
    static testMethod void sePuedeObtenerElEstadoDeCuentaDeUnCliente() { 
        
        Test.setMock(System.WebServiceMock.class, mockSuccessEstado);

        Test.startTest();
        EstadoDeCuenta estado = EstadoDeCuentaCliente.obtener(cliente, Date.today(), Date.today().addMonths(2));
        Test.stopTest();

        System.debug(estado.saldo);
        System.assertEquals(null, estado.mensaje);
        System.assertEquals(cliente.Id, estado.cliente.Id);
        System.assertEquals(3, estado.documentos.size());
        
        
    }
    
    static testMethod void esNecesarioIndicarElCodigoDeLaSociedadAConsultar() { 
        
        cliente.Sociedad__c = null;

        Test.startTest();
        EstadoDeCuenta estado = EstadoDeCuentaCliente.obtener(cliente, Date.today(), Date.today().addMonths(2));
        Test.stopTest();

        System.assertEquals(Label.WSDocumentosContables_FaltaSociedad, estado.mensaje);
    }

    static testMethod void esNecesarioIndicarElNumeroDelClienteAConsultar() { 
        
        cliente.N_mero_nico_de_Cliente__c = null;

        Test.startTest();
        EstadoDeCuenta estado = EstadoDeCuentaCliente.obtener(cliente, Date.today(), Date.today().addMonths(2));
        Test.stopTest();

        System.assertEquals(Label.WSDocumentosContables_FaltaCliente, estado.mensaje);
    }
    
    static testMethod void esNecesarioIndicarUnRangoDeFechasAConsultar() { 
        
        Test.startTest();
        EstadoDeCuenta estado = EstadoDeCuentaCliente.obtener(cliente, null, null);
        Test.stopTest();

        System.assertEquals(Label.WSDocumentosContables_FaltaPeriodo, estado.mensaje);
    }

    static testMethod void enCasoDeErrorONoExistirInformacionParaLaConsultaSeGuardaElMensaje() {
        
        Test.setMock(System.WebServiceMock.class, mockNoPostingsEstado);

        Test.startTest();
        EstadoDeCuenta estado = EstadoDeCuentaCliente.obtener(cliente, Date.today(), Date.today().addMonths(2));
        Test.stopTest();

        System.assertEquals(msgError, estado.mensaje);
        System.assertEquals(cliente.Id, estado.cliente.Id);
        System.assertEquals(0, estado.documentos.size());
    }


    // Detalles documentos contables
    static testMethod void sePuedeObtenerElDetalleDeUnDocumentoContable() { 
        
        Test.setMock(System.WebServiceMock.class, mockSuccessDetalle);

        Test.startTest();
        DocumentoContable documento = EstadoDeCuentaCliente.obtenerDetalles(nroDocumento);
        Test.stopTest();

        System.assertEquals(null, documento.mensaje);
        System.assertEquals(3, documento.detalles.size());
    }
    
    static testMethod void esNecesarioIndicarElNumeroDeDocumentoContableAConsultar() { 
        
        Test.startTest();
        DocumentoContable documento = EstadoDeCuentaCliente.obtenerDetalles(null);
        Test.stopTest();

        System.assertEquals(Label.WSDetallesDocumentosContables_FaltaNroDocumento, documento.mensaje);
    }

    static testMethod void enCasoDeErrorONoExistirInformacionParaLaConsultaDeDetalleSeGuardaElMensaje() {
        
        Test.setMock(System.WebServiceMock.class, mockNoPostingsDetalle);

        Test.startTest();
        DocumentoContable documento = EstadoDeCuentaCliente.obtenerDetalles(nroDocumento);
        Test.stopTest();

        System.assertEquals(msgErrorDetalle, documento.mensaje);
        System.assertEquals(0, documento.detalles.size());
    }
    
    static Account cliente;
    static WebServiceSoapMock mockSuccessEstado, mockNoPostingsEstado, mockSuccessDetalle, mockNoPostingsDetalle;
    static String msgError, msgErrorDetalle, nroDocumento;

    static {
        
        cliente = Build.anAccount().withUniqueCustomerCode('134972656').withCompanyCode('0010').build();
        insert cliente;

        nroDocumento = '0040000019';

        // Armo mock success estado de cuenta
        mockSuccessEstado = new WebServiceSoapMock();

        WSSAPDocumentosContables.DT_Estado_de_Cuenta_Response_In successResponse = new WSSAPDocumentosContables.DT_Estado_de_Cuenta_Response_In();
        successResponse.LINEITEMS = new WSSAPDocumentosContables.LINEITEMS_element[] {};

        for (Integer i = 0; i < 3; i++) {
            
            WSSAPDocumentosContables.LINEITEMS_element lineItem = new WSSAPDocumentosContables.LINEITEMS_element();
            
            lineItem.BILL_DOC = String.valueOf(0040000019 + i);
            lineItem.DOC_DATE = '20150505';
            successResponse.LINEITEMS.add(lineItem);
        }

        mockSuccessEstado.responseObj = successResponse;

        // Armo mock error estado de cuenta
        msgError = 'FN518000000:Customer 0135972656 company code 0010, no postings exist within time interval';

        mockNoPostingsEstado = new WebServiceSoapMock();

        WSSAPDocumentosContables.DT_Estado_de_Cuenta_Response_In noPostsResponse = new WSSAPDocumentosContables.DT_Estado_de_Cuenta_Response_In();
        noPostsResponse.RETURN_x = new WSSAPDocumentosContables.RETURN_element[] {};

        WSSAPDocumentosContables.RETURN_element result = new WSSAPDocumentosContables.RETURN_element();
        result.TYPE_X = 'I';
        result.MESSAGE = msgError;
        noPostsResponse.RETURN_x.add(result);

        mockNoPostingsEstado.responseObj = noPostsResponse;

        // Armo mock success detalle
        mockSuccessDetalle = new WebServiceSoapMock();

        WSSAPDetallesDocumentoContable.DT_Documentos_de_Facturacion_Response_In successResponseDetalles = new WSSAPDetallesDocumentoContable.DT_Documentos_de_Facturacion_Response_In();
        successResponseDetalles.XVBRP = new WSSAPDetallesDocumentoContable.XVBRP_element[] {};

        for (Integer i = 0; i < 3; i++) {
            
            WSSAPDetallesDocumentoContable.XVBRP_element detalle = new WSSAPDetallesDocumentoContable.XVBRP_element();
            
            detalle.VBELN = nroDocumento;
            detalle.POSNR = String.valueOf(i);
            detalle.AUPOS = '200';
            
            successResponseDetalles.XVBRP.add(detalle);
        }

        mockSuccessDetalle.responseObj = successResponseDetalles;

        // Armo mock error detalle
        msgErrorDetalle = 'No se encontro el documentos';

        mockNoPostingsDetalle = new WebServiceSoapMock();

        WSSAPDetallesDocumentoContable.DT_Documentos_de_Facturacion_Response_In noPostsResponseDetalle = new WSSAPDetallesDocumentoContable.DT_Documentos_de_Facturacion_Response_In();
        noPostsResponseDetalle.RETURN_x = new WSSAPDetallesDocumentoContable.RETURN_element[] {};

        WSSAPDetallesDocumentoContable.RETURN_element resultDetalle = new WSSAPDetallesDocumentoContable.RETURN_element();
        resultDetalle.TYPE_X = 'E';
        resultDetalle.MESSAGE = msgErrorDetalle;
        noPostsResponseDetalle.RETURN_x.add(resultDetalle);

        mockNoPostingsDetalle.responseObj = noPostsResponseDetalle;
    }
}
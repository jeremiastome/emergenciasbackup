@isTest
private class Vista360ControllerTest {
	static testMethod void sePuedeObtenerElEstadoDeCuentaDelClienteConSuIdYIdSociedad() {
		Test.setMock(System.WebServiceMock.class, mockSuccessEstado);

		Test.startTest();
        System.debug(cliente.Id);
		EstadoDeCuenta estado = Vista360Controller.obtenerEstadoCuenta(cliente.Id, cliente.Sociedad__c);
		Test.stopTest();
		System.debug(estado);
		System.assertEquals(null, estado.mensaje);
		System.assertEquals(cliente.Id, estado.cliente.N_mero_nico_de_Cliente__c);
        System.assertEquals(3, estado.documentos.size());
		System.assertEquals(1, estado.facturas.size());
        System.assertEquals(1, estado.notasDeCredito.size());
        System.assertEquals(1, estado.pagos.size());
	}

 	static testMethod void sePuedeObtenerElEstadoDeContratoMedianteSuNumeroUnicoDeContratoSuSociedadYIdDelCliente() {
		Test.setMock(System.WebServiceMock.class, mockSuccessEstado);

		Test.startTest();
        System.debug(cliente.Id);
		EstadoDeCuenta estado = Vista360Controller.obtenerEstadoContrato(cliente.Id, cliente.Sociedad__c, contrato.Numero_Unico_de_Contrato_Con_Sufijo__c);
		Test.stopTest();

		System.debug(estado);
		System.assertEquals(null, estado.mensaje);
        System.assertEquals(3, estado.documentos.size());
		System.assertEquals(1, estado.facturas.size());
        System.assertEquals(1, estado.notasDeCredito.size());
        System.assertEquals(1, estado.pagos.size());
	}

	static testMethod void sePuedeObtenerElDetalleDeUnDocumentoContableConSuNroDeDocumento() {
		Test.setMock(System.WebServiceMock.class, mockSuccessDetalle);

		Test.startTest();
		DocumentoContable documento = Vista360Controller.obtenerDetallesDocumento(nroDocumento);
		Test.stopTest();

		System.assertEquals(null, documento.mensaje);
		System.assertEquals( 3, documento.detalles.size() );
	}


 	static testMethod void lasFacturasSeClasificanComoObjetosPropiosAdjuntadasConSusPagosYNotasDeCredito() {
		Test.setMock(System.WebServiceMock.class, mockSuccessEstado);

		Test.startTest();
        System.debug(cliente.Id);
		EstadoDeCuenta estado = Vista360Controller.obtenerEstadoContrato(cliente.Id, cliente.Sociedad__c, contrato.Numero_Unico_de_Contrato_Con_Sufijo__c);
		Test.stopTest();

		System.assertEquals(1, estado.facturasConAdjuntos.size() );
		System.assertEquals(1, estado.facturasConAdjuntos[0].notasDeCredito.size() );
		System.assertEquals(1, estado.facturasConAdjuntos[0].pagos.size());
	}


	static testMethod void sePuedeObtenerLosUltimosServiciosConsumidosDeUnCliente() {
		Test.setMock(HttpCalloutMock.class, mockSuccessServicios);

		Test.startTest();
		LegacySystemServiceList servicios = Vista360Controller.obtenerServiciosConsumidos(cliente.Id);
		Test.stopTest();

		System.assertEquals(null, servicios.mensaje);
		System.assert(servicios.RCDServiceList.isEmpty());
		System.assert(servicios.EmerphoneServiceList.isEmpty());
		System.assertEquals(1, servicios.GTEServiceList.size());
	}

	static testMethod void siNoSePuedenObtenerClavesDeSistemaSeGuardaElError() {
		delete contrato;

		Test.startTest();
		LegacySystemServiceList servicios = Vista360Controller.obtenerServiciosConsumidos(cliente.Id);
		Test.stopTest();

		System.assertEquals(Label.WSEmergencias_FaltanClavesDeSistema, servicios.mensaje);
	}

	static testMethod void siLaCuentaEsSoloClienteSeEnvianLasClavesDeSistemaDeSusContratos() {
		Test.startTest();
		String[] clavesSistema = Vista360Controller.obtenerClavesDeSistemaDeCliente(cliente.Id);
		Test.stopTest();

		System.assertEquals(1, clavesSistema.size());
		System.assertEquals('1 V000001', clavesSistema[0]);
	}

	static testMethod void siLaCuentaEsSoloTitularSeEnvianLasClavesDeSistemaDeSusBeneficiarios() {
		Test.startTest();
		String[] clavesSistema = Vista360Controller.obtenerClavesDeSistemaDeCliente(titular.Id);
		Test.stopTest();

		System.assertEquals(1, clavesSistema.size());
		System.assertEquals(benef.Clave_Sistema_Beneficiario_2__c, clavesSistema[0]);
	}

	static testMethod void siLaCuentaEsSoloBeneficiarioSeEnvianLasClavesDeSistemaDeLaCuentaComoBeneficiario() {
		Test.startTest();
		String[] clavesSistema = Vista360Controller.obtenerClavesDeSistemaDeCliente(beneficiario.Id);
		Test.stopTest();

		System.assertEquals(1, clavesSistema.size());
		System.assertEquals(benef.Clave_Sistema_Beneficiario_2__c, clavesSistema[0]);
	}

	static testMethod void siLaCuentaEsBeneficiarioYTitularALaVezSeEnvianLasClavesDeSistemaDeLaCuentaComoBeneficiario() {
		// Hago titular al beneficiario
		Titular__c otroTitular = Build.aHolder()
			.forContract(contrato)
			.forAccount(beneficiario)
			.withUniqueCode('V000004')
			.build();
		insert otroTitular;


		Test.startTest();
		String[] clavesSistema = Vista360Controller.obtenerClavesDeSistemaDeCliente(beneficiario.Id);
		Test.stopTest();


		System.assertEquals(1, clavesSistema.size());
		System.assertEquals(benef.Clave_Sistema_Beneficiario_2__c, clavesSistema[0]);
	}

	static testMethod void siLaCuentaEsBeneficiarioTitularYClienteALaVezSeEnvianLasClavesDeSistemaDeLaCuentaComoBeneficiario() {

		// Creo un contrato para el beneficiario
		Contrato__c otroContrato = Build.aContract()
			.forAccount(beneficiario)
			.withUniqueNumber('V000006')
			.build();

		// Hago titular al beneficiario
		Titular__c otroTitular = Build.aHolder()
			.forContract(contrato)
			.forAccount(beneficiario)
			.withUniqueCode('V000004')
			.build();
		insert new SObject[] { otroContrato, otroTitular };

		List<Account> clientes = new List<Account>([
			SELECT Id,
				(SELECT Clave_Sistema_Contrato__c FROM Contratos__r),
				(SELECT Clave_Sistema_Titular__c FROM Titulares__r),
				(SELECT Clave_Sistema_Beneficiario_2__c FROM Beneficiarios__r)
			FROM Account
			WHERE Id = :beneficiario.Id
		]);

        clientes[0].Beneficiarios__r[0].Cliente__c=null;
        update clientes[0].Beneficiarios__r[0];

        delete clientes[0].Contratos__r;

		Test.startTest();
		String[] clavesSistema = Vista360Controller.obtenerClavesDeSistemaDeCliente(beneficiario.Id);
		Test.stopTest();

		System.assertEquals(1, clavesSistema.size());
		System.assertEquals(benef.Clave_Sistema_Beneficiario_2__c, clavesSistema[0]);
	}

	static Account cliente, titular, beneficiario;
	static Beneficiario__c benef;
	static Contrato__c contrato;
	static WebServiceSoapMock mockSuccessEstado, mockSuccessDetalle;
	static WebServiceMock mockSuccessServicios;
	static String nroDocumento;

	static {
		cliente = Build.anAccount().withUniqueCustomerCode('134972656').withCompanyCode('0010').build();
		titular = Build.anAccount().withUniqueCustomerCode('134972657').withCompanyCode('0010').build();
		beneficiario = Build.anAccount().withUniqueCustomerCode('134972658').withCompanyCode('0010').build();
		insert new Account[] { cliente, titular, beneficiario };


		contrato = Build.aContract().forAccount(cliente).withUniqueNumber('V000001').withUniqueNumberWithSufix('V00000100').build();
		insert contrato;

		Titular__c titular = Build.aHolder()
			.forContract(contrato)
			.forAccount(titular)
			.build();
		insert titular;

		benef = Build.aRecipient()
			.forHolder(titular)
			.forAccount(beneficiario)
			.forContract(contrato)
			.build();
		insert benef;

		titular = [SELECT Clave_Sistema_Titular__c FROM Titular__c WHERE Id = :titular.Id];
		benef = [SELECT Clave_Sistema_Beneficiario_2__c FROM Beneficiario__c WHERE Id = :benef.Id];

		nroDocumento = '0040000019';

		// Armo mock success servicios consumidos
		mockSuccessServicios = new WebServiceMock();
		mockSuccessServicios.returnBody = '{"EmerphoneServiceList":[],"GTEServiceList":[{"Instante":"/Date(1497013256000-0300)/","NumeroServicio":"00787680","TipoServicio":"Traslado"}],"RCDServiceList":[]}';
		mockSuccessServicios.returnStatusCode = 200;
		mockSuccessServicios.returnStatus = 'OK';

		// Armo mock success estado de cuenta
		mockSuccessEstado = new WebServiceSoapMock();

		WSSAPDocumentosContables.DT_Estado_de_Cuenta_Response_In successResponse = new WSSAPDocumentosContables.DT_Estado_de_Cuenta_Response_In();
		successResponse.LINEITEMS = new WSSAPDocumentosContables.LINEITEMS_element[] {};

		for (Integer i = 0; i < 3; i++) {
			WSSAPDocumentosContables.LINEITEMS_element lineItem = new WSSAPDocumentosContables.LINEITEMS_element();
			lineItem.NRO_CONTRATO = 'V00000100';
			lineItem.BILL_DOC = String.valueOf(0040000019 + i);
			lineItem.DOC_DATE= '20170808';
			successResponse.LINEITEMS.add(lineItem);
        	lineItem.CLR_DOC_NO= '123';
		}
        successResponse.LINEITEMS[0].DOC_TYPE = 'DR';
        successResponse.LINEITEMS[1].DOC_TYPE = 'DG';
        successResponse.LINEITEMS[2].DOC_TYPE = 'DW';

		mockSuccessEstado.responseObj = successResponse;

		// Armo mock success detalle
		mockSuccessDetalle = new WebServiceSoapMock();

		WSSAPDetallesDocumentoContable.DT_Documentos_de_Facturacion_Response_In successResponseDetalles = new WSSAPDetallesDocumentoContable.DT_Documentos_de_Facturacion_Response_In();
		successResponseDetalles.XVBRP = new WSSAPDetallesDocumentoContable.XVBRP_element[] {};

		for (Integer i = 0; i < 3; i++) {
			WSSAPDetallesDocumentoContable.XVBRP_element detalle = new WSSAPDetallesDocumentoContable.XVBRP_element();

			detalle.VBELN = nroDocumento;
			detalle.POSNR = String.valueOf(i);
			detalle.FBUDA= '20150505';
            detalle.AUPOS='100';
			successResponseDetalles.XVBRP.add(detalle);
		}

		mockSuccessDetalle.responseObj = successResponseDetalles;
	}
}
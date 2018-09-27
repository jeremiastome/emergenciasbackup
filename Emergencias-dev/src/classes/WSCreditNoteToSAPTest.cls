@isTest
private class WSCreditNoteToSAPTest {
	private static testMethod void whenSendingACreditNoteToSAPTheAddressAndAuthorizationShouldBeTakenFromTheConfiguration() {
		Test.startTest();
		WSCreditNoteToSAP.sendCreditNote(aCase.Id);
		Test.stopTest();
		
		System.assertEquals(sapSettings.Url__c, serverMock.endpoint.split('\\?')[0]);
		
		String auth = EncodingUtil.base64Encode(
			blob.valueOf(
				sapSettings.Usuario__c + ':' + sapSettings.Contrasena__c
			)
		);
		
		WSSAPContratosPedidos.HTTPS_Port portStub;
		for(Object stub : serverMock.stubs) {
			if(stub instanceof WSSAPContratosPedidos.HTTPS_Port) {
				portStub = (WSSAPContratosPedidos.HTTPS_Port)stub;
				break;
			}
		}
		System.assertNotEquals(null, portStub);
		
		System.assertEquals('Basic ' + auth, portStub.inputHttpHeaders_x.get('authorization'));
		System.assertEquals('text/xml;charset=UTF-8', portStub.inputHttpHeaders_x.get('Content-Type'));
	}
	
	private static testMethod void itShouldBePosibleToSendTheCreditNotesDetails() {
		Test.startTest();
		WSCreditNoteToSAP.sendCreditNote(aCase.Id);
		Test.stopTest();
		
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out request;
		for(Object req : serverMock.soapRequests) {
			if(req instanceof WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out) {
				request = (WSSAPContratosPedidos.DT_Contratos_Pedidos_Request_Out)req;
				break;
			}
		}

		System.assertNotEquals(null, request);
		
		System.assertEquals(1, request.Pedido.size());
		System.assertNotEquals(null, request.Pedido[0].Cabecera);
		WSSAPContratosPedidos.Cabecera_element requestHeader = request.Pedido[0].Cabecera;
		
		System.assertEquals('A', requestHeader.TipoOperacion);
		System.assertEquals('NC', requestHeader.TipoDocumento);
		System.assertEquals('00', requestHeader.Sector);
		System.assertEquals(aContract.Organizacion_de_Ventas__c, requestHeader.OrganizacionVentas);
		System.assertEquals(aContract.Canal_de_Distribucion__c, requestHeader.CanalDistribucion);
		System.assertEquals(anAccount.N_mero_nico_de_Cliente__c, requestHeader.Solicitante);
		System.assertEquals(aCase.Motivo_de_nota_de_credito__c, requestHeader.MotivoDePedido);
		System.assertEquals(aCase.Nro_de_Factura__c, requestHeader.DocumentoRef);
	}
	
	//==========================================================================
	static WebServiceSoapMock serverMock;
	static Configuracion_SAP__c sapSettings;
	static Account anAccount;
	static Contrato__c aContract;
	static Case aCase;
	static Notas_de_credito_numeracion__c numeracion;
	
	static {
		serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		serverMock.responseObj = new WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In();
		
		sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		
		anAccount = Build.anAccount().build();
		insert anAccount;
		anAccount = [
			SELECT Id, N_mero_nico_de_Cliente__c
			FROM Account
			WHERE Id = :anAccount.Id
		];
		
		aContract = Build.aContract().forAccount(anAccount).withSalesOrganization('0010')
			.withDistributionChannel('30').withUniqueNumber().build();
		insert aContract;
		aContract = [
			SELECT Id, Organizacion_de_Ventas__c,
				Canal_de_Distribucion__c, Numero_Unico_de_Contrato_Con_Sufijo__c
			FROM Contrato__c
			WHERE Id = :aContract.Id
		];
		
		RecordType creditNoteCase = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Nota_de_Credito'
		];
		System.debug('');
        system.debug(anAccount);
        system.debug(aContract);
        system.debug(creditNoteCase);
		aCase = Build.aCase().forAccount(anAccount).forContract(aContract).withRecordType(creditNoteCase)
			.WithBillNumber('1').WithCreditNoteMotive('Z37').build();
        system.debug(aCase);
		insert aCase;

		numeracion = new Notas_de_credito_numeracion__c();
		numeracion.Name='Numero';
		numeracion.Numero__c=6561645;
		insert numeracion;
	}
}
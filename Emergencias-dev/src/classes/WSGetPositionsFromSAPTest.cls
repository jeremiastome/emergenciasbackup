@isTest
private class WSGetPositionsFromSAPTest {
	private static testMethod void itShouldBePosibleToSendTheCredentialsToSAP() {
		String contractNumber = '6ty7u8ik0';
		WSGetPositionsFromSAP positionsHandler = new WSGetPositionsFromSAP();
		
		Test.startTest();
		positionsHandler.getForContract(contractNumber);
		Test.stopTest();
		
		System.assertEquals(sapSettings.Url__c, serverMock.endpoint.split('\\?')[0]);
		
		String auth = EncodingUtil.base64Encode(
			blob.valueOf(
				sapSettings.Usuario__c + ':' + sapSettings.Contrasena__c
			)
		);
		
		WSSAPContratosPosiciones.HTTPS_Port portStub = (WSSAPContratosPosiciones.HTTPS_Port)serverMock.stub;
		System.assertEquals('Basic ' + auth, portStub.inputHttpHeaders_x.get('authorization'));
		System.assertEquals('text/xml;charset=UTF-8', portStub.inputHttpHeaders_x.get('Content-Type'));
		System.assertEquals(
			contractNumber,
			((WSSAPContratosPosiciones.DT_CONTRATO)serverMock.requestObj).CONTRATO
		);
		System.assertEquals(false, positionsHandler.hadError);
	}
	
	private static testMethod void ifNoSettingsAreFoundItShouldBePosibleToKnowTheSendingFailed() {
		delete sapSettings;
		
		WSGetPositionsFromSAP positionsHandler = new WSGetPositionsFromSAP();
		
		Test.startTest();
		positionsHandler.getForContract('piuweo8ju');
		Test.stopTest();
		
		System.assertEquals(true, positionsHandler.hadError);
		System.assertEquals(null, serverMock.stub);
	}
	
	private static testMethod void ifAnErrorOccursWhileGettingThePositionsItShouldBePosibleToKnowTheSendingFailed() {
		WSGetPositionsFromSAP positionsHandler = new WSGetPositionsFromSAP();
		positionsHandler.getForContract('piuweo8ju');
		
		System.assertEquals(true, positionsHandler.hadError);
	}
	
	private static testMethod void ifAPositionWasntInRecievedFromSAPWhenGettingTheNumberItShouldReturnMinusOne() {
		WSGetPositionsFromSAP positionsHandler = new WSGetPositionsFromSAP();
		
		Test.startTest();
		positionsHandler.getForContract('piuweo8ju');
		Test.stopTest();
		
		System.assertEquals(
			-1,
			positionsHandler.getPosNumber('Prod2', 'BE', 'prov2', true)
		);
		
		System.assertEquals(
			-1,
			positionsHandler.getPosNumber('Prod2', '102')
		);
	}
	
	private static testMethod void itShouldBePosibleToGetThePositionNumberForANewPosition() {
		WSGetPositionsFromSAP positionsHandler = new WSGetPositionsFromSAP();
		
		Test.startTest();
		positionsHandler.getForContract('piuweo8ju');
		Test.stopTest();
		
		System.assertEquals(
			(returnedPositions.size() + 1) * 100,
			positionsHandler.getNextNumber()
		);
		
		System.assertEquals(
			(returnedPositions.size() + 2) * 100,
			positionsHandler.getNextNumber()
		);
	}
	
	private static testMethod void itShouldBePosibleToGetTheOldNumberForAPosition() {
		WSGetPositionsFromSAP positionsHandler = new WSGetPositionsFromSAP();
		
		Test.startTest();
		positionsHandler.getForContract('piuweo8ju');
		Test.stopTest();
		
		System.assertEquals(300, positionsHandler.getPosNumber('Prod', '001'));
	}
	
	private static testMethod void itShouldBePosibleToGetThePositionsThatWerentUsed() {
		WSGetPositionsFromSAP positionsHandler = new WSGetPositionsFromSAP();
		
		Test.startTest();
		positionsHandler.getForContract('piuweo8ju');
		Test.stopTest();
		
		positionsHandler.getPosNumber('Prod', 'BG', 'Dest', false);//100
		positionsHandler.getPosNumber('Prod', '001');//300
		
		List<WSSAPContratosPedidos.Posicion_element> result = positionsHandler.generateDeletePositions();
		System.assertEquals(1, result.size());
		
		System.assertEquals('B', result[0].TipoOperacion);
		System.assertEquals('200', result[0].NumeroPosicion);
		System.assertEquals('Prod', result[0].CodigoMaterial);
		System.assertEquals('', result[0].Cantidad);
		System.assertEquals('', result[0].Sector);
		System.assertEquals('', result[0].GrupoDeClientes);
		System.assertEquals('BA', result[0].MotivoDeRechazo);
		System.assertEquals('', result[0].Cobrador);
		System.assertEquals('', result[0].Radio);
	}
	
	private static testMethod void itShouldBePosibleToGetAUnusedPositionForANonAddressRecipient() {
		WSGetPositionsFromSAP positionsHandler = new WSGetPositionsFromSAP();
		
		Test.startTest();
		positionsHandler.getForContract('piuweo8ju');
		Test.stopTest();
		
		positionsHandler.getPosNumber('Prod', 'BG', 'Dest', false);//100
		positionsHandler.getPosNumber('Prod', '001');//300
		
		List<WSSAPContratosPedidos.Posicion_element> result = positionsHandler.generateDeletePositions();
		System.assertEquals(1, result.size());
		
		System.assertEquals('BG', result[0].CondIVABenef);
		System.assertEquals('Dest', result[0].DestinatarioMercancias);
		System.assertEquals('', result[0].ZonaDeVentas);
	}
	
	private static testMethod void itShouldBePosibleToGetAUnusedPositionForAnAddressRecipient() {
		WSGetPositionsFromSAP positionsHandler = new WSGetPositionsFromSAP();
		
		Test.startTest();
		positionsHandler.getForContract('piuweo8ju');
		Test.stopTest();
		
		positionsHandler.getPosNumber('Prod', 'BG', 'Dest', false);//100
		positionsHandler.getPosNumber('Prod', 'BG', 'Dest', true);//200
		
		List<WSSAPContratosPedidos.Posicion_element> result = positionsHandler.generateDeletePositions();
		System.assertEquals(1, result.size());
		
		System.assertEquals('', result[0].CondIVABenef);
		System.assertEquals('', result[0].DestinatarioMercancias);
		System.assertEquals('001', result[0].ZonaDeVentas);
	}
    //==========================================================================
   
    
    private static testMethod void whenAPositionSEditorStartedThePositionsAreCreated() {
		Account anAccount = Build.anAccount().build();
		insert anAccount;
        
		Contrato__c aContract = Build.aContract().withUniqueNumberWithSufix('piuweo8ju').forAccount(anAccount).build();
        insert aContract;
        
       	RecordType creditNoteCase = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Nota_de_Credito'];
            
        
        Case aCase = Build.aCase().forAccount(anAccount).withRecordType(creditNoteCase)
						.withReason('Nota de credito').forContract(aContract).build();
		insert aCase;
        
		Test.startTest();
		String response = WSGetPositionsFromSAP.createPositionByCreditNote(aCase.id);
		Test.stopTest();
        
        List<Posicion__c> positions = [SELECT Id
                                       FROM Posicion__c
                                       WHERE Caso__c=:aCase.id];
        
        System.assertEquals(3, positions.size());
        
    }
    
    
    private static testMethod void whenAPositionSEditorStartedThePositionsAreCreatedIfTheyAreNot() {
		Account anAccount = Build.anAccount().build();
		insert anAccount;
        
		Contrato__c aContract = Build.aContract().withUniqueNumberWithSufix('piuweo8ju').forAccount(anAccount).build();
        insert aContract;
        
       	RecordType creditNoteCase = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Nota_de_Credito'];
            
        
        Case aCase = Build.aCase().forAccount(anAccount).withRecordType(creditNoteCase)
						.withReason('Nota de credito').forContract(aContract).build();
		insert aCase;
        

		Posicion__c newPos = new Posicion__c();
        newPos.caso__c = acase.Id;
        newPos.Posicion__c = '100';
        newPos.Producto__c = 'Prod';                      
        newPos.Iva__c = 'BG';
        insert newPos;
        
		Test.startTest();
		String response = WSGetPositionsFromSAP.createPositionByCreditNote(aCase.id);
		Test.stopTest();
        
        List<Posicion__c> positions = [SELECT Id
                                       FROM Posicion__c
                                       WHERE Caso__c=:aCase.id];
        
        System.assertEquals(3, positions.size());
        
    }
    
    
    private static testMethod void ifTheResponseFromSAPDontContainAPositionCreatedYet_ItWillBeEliminated() {
		Account anAccount = Build.anAccount().build();
		insert anAccount;
        
		Contrato__c aContract = Build.aContract().withUniqueNumberWithSufix('piuweo8ju').forAccount(anAccount).build();
        insert aContract;
        
       	RecordType creditNoteCase = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Nota_de_Credito'];
            
        
        Case aCase = Build.aCase().forAccount(anAccount).withRecordType(creditNoteCase)
						.withReason('Nota de credito').forContract(aContract).build();
		insert aCase;
        

		Posicion__c newPos = new Posicion__c();
        newPos.caso__c = acase.Id;
        newPos.Posicion__c = '700';
        newPos.Producto__c = 'Prod';                      
        newPos.Iva__c = 'BG';
        insert newPos;
        
		Test.startTest();
		String response = WSGetPositionsFromSAP.createPositionByCreditNote(aCase.id);
		Test.stopTest();
        
        List<Posicion__c> positions = [SELECT Id
                                       FROM Posicion__c
                                       WHERE Caso__c=:aCase.id
                                       AND Posicion__c='700'];
        
        System.assertEquals(0, positions.size());
    }
	
	//==========================================================================
	private static List<WSSAPContratosPosiciones.POSICIONES_element> generateResponse() {
		List<WSSAPContratosPosiciones.POSICIONES_element> result = new List<WSSAPContratosPosiciones.POSICIONES_element>();
		
		for(Integer i = 0; i < 4; i++) {
			WSSAPContratosPosiciones.POSICIONES_element pos = new WSSAPContratosPosiciones.POSICIONES_element();
			
			pos.POSICION = String.valueof((i + 1) * 100);
			pos.CONTRATO = 'piuweo8ju';
			pos.BOM = 'Prod';
			pos.COND_IVA = 'BG';
			pos.DESTINATARIO = 'Dest';
			pos.SUFIJO = i == 2?'001':'';
			pos.MENOR_S_CARGO = i == 1?'ZDV1':'';
			pos.MOTIVO_RECHAZO = i == 3?'BA':'';
			
			result.add(pos);
		}
		
		return result;
	}
	
	//==========================================================================
	static WebServiceSoapMock serverMock;
	static Configuracion_SAP__c sapSettings;
	static List<WSSAPContratosPosiciones.POSICIONES_element> returnedPositions;
	
	static {
		serverMock = new WebServiceSoapMock();
		Test.setMock(System.WebServiceMock.class, serverMock);
		sapSettings = Build.SAPSettings().withUrl('http://some.url/dir').withUsername('Testmin').withPassword('S0M3-P455w@Rd').build();
		insert sapSettings;
		
		returnedPositions = generateResponse();
		WSSAPContratosPosiciones.DT_CONTRATO_RESP responseObj = new WSSAPContratosPosiciones.DT_CONTRATO_RESP();
		responseObj.POSICIONES = returnedPositions;
		serverMock.responseObj = responseObj;
	}
}
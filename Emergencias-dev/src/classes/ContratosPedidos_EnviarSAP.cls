public class ContratosPedidos_EnviarSAP {
	public static integer CONTACTO_DELIVERY = 0;
	public static integer CONTACTO_FACTURACION = 1;
	public static integer CONTACTO_COBRANZA = 2;
	
	public static void sendContract(Id contractId, String operation) {
		Configuracion_SAP__c sapSettings = Configuracion_SAP__c.getInstance();
		if(String.isBlank(sapSettings.Url__c)) {
			return;
		}
		String auth = EncodingUtil.base64Encode(
			blob.valueOf(
				sapSettings.Usuario__c + ':' + sapSettings.Contrasena__c
			)
		);
		Contrato__c conToUpdate = [
			SELECT Id, Estado__c
			FROM Contrato__c
			WHERE Id = :contractId
		];
		conToUpdate.Saltear_envio__c = 2;
		conToUpdate.Esperando_envio__c = false;
		
		ContractToSAPConverter converter = new ContractToSAPConverter(contractId, operation);
		if(converter.oldPositionNumbersFailed) {
			conToUpdate.Request_SF__c = null;
			conToUpdate.Status_Envio__c = '-1';
			conToUpdate.Estado_de_Envio_a_SAP__c = 'Error: No se pudo obtener los numeros de posiciones desde SAP';
			update conToUpdate;
			return;
		}
		
		List<WSSAPContratosPedidos.Pedido_element> request = new List<WSSAPContratosPedidos.Pedido_element>();
		request.add(converter.generateRequest());
		
		WSSAPContratosPedidos.HTTPS_Port ws = new WSSAPContratosPedidos.HTTPS_Port();
		ws.inputHttpHeaders_x = new Map<String, String>();
		ws.inputHttpHeaders_x.put('authorization', 'Basic ' + auth);
		ws.inputHttpHeaders_x.put('Content-Type', 'text/xml;charset=UTF-8');
		
		system.debug(request);
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In result;
		
		conToUpdate.Request_SF__c = String.valueOf(request);
		if(operation == 'A' && conToUpdate.Estado__c != 'Activo'){
			conToUpdate.Estado__c = 'Activo';
			conToUpdate.Fecha_Alta__c = Date.today();
		}
		try{
			//Call the SAP webservice.
			result = ws.SI_Contratos_Pedidos_Request(request);
			system.debug(result);
			conToUpdate.Status_Envio__c = '200';
            if(result.Msg.size()!=0) {
            	conToUpdate.Descripcion_de_respuesta_de_SAP__c=result.Msg[0].Descripcion;
            }
			conToUpdate.Response_SAP__c = String.valueOf(result)+'\n'+Datetime.now();
			if(!String.valueOf(result).contains('Tipo=S,')){
				conToUpdate.Estado_de_Envio_a_SAP__c = 'Error en el impacto a SAP';
			}
			else{
				conToUpdate.Estado_de_Envio_a_SAP__c = 'Ok';
				//Update the discount relations so that it can be known which discounts
				// were already sent in future contract sends.
				converter.updateDiscountRelations();
			}
		}
		catch(Exception ex){
			conToUpdate.Status_Envio__c = '-1';
			conToUpdate.Response_SAP__c = 'Exception: ' + ex.getMessage();
			conToUpdate.Estado_de_Envio_a_SAP__c = 'Error de comunicacion';
			conToUpdate.Descripcion_de_respuesta_de_SAP__c='Exception: ' + ex.getMessage();
            
		}
		
		update conToUpdate;
	}
}
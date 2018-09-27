public class ContractSAPSendSimulate {
	public static WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In sendSimulation(
		WSSAPContratosPedidos.Pedido_element req
	) {
		Configuracion_SAP__c sapSettings = Configuracion_SAP__c.getInstance();
		if(String.isBlank(sapSettings.Url__c)) {
			return generateErrorResponse('ESF3', Label.Error_SAP_Falta_credenciales);
		}
		String auth = EncodingUtil.base64Encode(
			blob.valueOf(
				sapSettings.Usuario__c + ':' + sapSettings.Contrasena__c
			)
		);
		
		List<WSSAPContratosPedidos.Pedido_element> requestList = new List<WSSAPContratosPedidos.Pedido_element>();
		requestList.add(req);
		
		WSSAPContratosPedidos.HTTPS_Port ws = new WSSAPContratosPedidos.HTTPS_Port();
		ws.inputHttpHeaders_x = new Map<String, String>();
		ws.inputHttpHeaders_x.put('authorization', 'Basic ' + auth);
		ws.inputHttpHeaders_x.put('Content-Type', 'text/xml;charset=UTF-8');
		
		system.debug(requestList);
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In result;
		
		try{
			//Call the SAP webservice.
			result = ws.SI_Contratos_Pedidos_Request(requestList);
			system.debug(result);
			if(result == null || result.Msg == null || result.Msg.size() == 0) {
				//Failed requeest
				result = generateErrorResponse(
					'ESF1',
					Label.Error_SAP_Mensaje_vacio
				);//No message from SAP
			}
		}
		catch(Exception ex){
			result = generateErrorResponse(
				'ESF2',
				Label.Error_SAP_de_comunicacion + ex.getMessage()
			);//SAP response error
		}
		
		return result;
	}
	
	public static ProductSimulationResult simulateProductPositions(
		Id contractId,
		List<AgregarProductosController.ProductToAddWrapper> products
	) {
		Map<String, Producto_Transito__c> transitSeparations = Producto_Transito__c.getAll();
		
		List<SimulationPosition> simPositions = new List<SimulationPosition>();
		for(AgregarProductosController.ProductToAddWrapper prodWrap : products) {
			Product2 prod = prodWrap.MainProduct;
			for(SimulationPosition pos : prodWrap.Positions) {
				if(pos.amount != null && pos.amount != 0) {
					pos.productNumber = getPositionProductNumber(
						prod.Numero__c,
						pos.isInTransit,
						transitSeparations
					);
					pos.productSector = prod.Sector__c;
					
					pos.discountsToSend = new List<AgregarProductosController.DiscountToAddWrapper>();
					for(AgregarProductosController.DiscountToAddWrapper disc : prodWrap.Discounts) {
						if(disc.IsActive) {
							pos.discountsToSend.add(disc);
						}
					}
					
					simPositions.add(pos);
					
					for(String additionalId : prodWrap.SelectedAdditionals) {
						if(String.IsNotBlank(additionalId)) {
							SimulationPosition additPos = pos.clone();
							Product2 addP = prodWrap.AvailableAdditionals.get(additionalId);
							additPos.productNumber = getPositionProductNumber(
								addP.Numero__c,
								additPos.isInTransit,
								transitSeparations
							);
							additPos.productSector = addP.Sector__c;
							
							simPositions.add(additPos);
						}
					}
				}
			}
		}
		
		ContractToSAPSimulation converter = new ContractToSAPSimulation(contractId, simPositions);
		
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In response =
			sendSimulation(converter.generateRequest());
		
		ProductSimulationResult result = new ProductSimulationResult();
		
		result.status = response.Msg[0];
		if(result.status.Tipo == 'S') {
			result.positions = converter.applyReceivedPrices(response.Documento.Posiciones);
		}
		else {
			result.positions = new List<SimulationPosition>();
		}
		
		return result;
	}
	
	public static decimal numberFromSAPValue(String sapVal) {
		sapVal = sapVal.replace(' ', '');
		if(sapVal.right(1) == '-') {
			return - Decimal.valueOf(sapVal.left(sapVal.length() - 1));
		}
		else {
			return Decimal.valueOf(sapVal);
		}
	}
	
	private static WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In generateErrorResponse(
		String errType,
		String description
	) {
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In result;
		
		result = new WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In();
		result.Msg = new List<WSSAPContratosPedidos.Msg_element>();
		WSSAPContratosPedidos.Msg_element message = new WSSAPContratosPedidos.Msg_element();
		message.Tipo = errType;
		message.Descripcion = description;
		result.Msg.add(message);
		
		return result;
	}
	
	private static String getPositionProductNumber(
		String productNumber,
		Boolean isInTransit,
		Map<String, Producto_Transito__c> transitSeparations
	) {
		String result = productNumber;
		if(isInTransit && transitSeparations.containsKey(productNumber)) {
			result += ' TRA';
		}
		return result;
	}
	
	public class ProductSimulationResult {
		public WSSAPContratosPedidos.Msg_element status;
		public List<SimulationPosition> positions;
	}
}
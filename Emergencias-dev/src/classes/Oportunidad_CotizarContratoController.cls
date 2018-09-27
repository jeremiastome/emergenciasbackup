public class Oportunidad_CotizarContratoController {
	@AuraEnabled
	public static boolean canBeSimulated(Id contractId) {
		List<Cobertura_de_Beneficiario__c> rcr = [
			SELECT Id
			FROM Cobertura_de_Beneficiario__c
			WHERE Cobertura__r.Contrato__c = :contractId
		];
		
		return rcr.size() != 0;
	}
	
	@AuraEnabled
	public static String simulateContract(Id contractId) {
		return JSON.serialize(simulateContractInternal(contractId));
	}
	
	private static ContractSAPSendSimulate.ProductSimulationResult simulateContractInternal(Id contractId) {
		ContractToSAPConverter converter = new ContractToSAPConverter(contractId, 'S');
		
		WSSAPContratosPedidos.Pedido_element request = converter.generateRequest();
		
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In response =
			ContractSAPSendSimulate.sendSimulation(request);
		
		ContractSAPSendSimulate.ProductSimulationResult result =
			new ContractSAPSendSimulate.ProductSimulationResult();
		
		result.status = response.Msg[0];
		
		if(result.status.Tipo == 'S') {
			prepareStaticCollections();
			result.positions = new List<SimulationPosition>();
			
			Map<Integer, WSSAPContratosPedidos.Posicion_element> positionByNumber =
				new Map<Integer, WSSAPContratosPedidos.Posicion_element>();
			for(WSSAPContratosPedidos.Posicion_element pos : request.ListaPosiciones.Posicion) {
				positionByNumber.put(Integer.valueOf(pos.NumeroPosicion), pos);
			}
			
			for(WSSAPContratosPedidos.Posiciones_element resPos : response.Documento.Posiciones) {
				WSSAPContratosPedidos.Posicion_element reqPos =
					positionByNumber.get(Integer.valueOf(resPos.Posicion));
				if(reqPos != null) {
					result.positions.add(generateSimulatedPosition(reqPos, resPos));
				}
			}
		}
		
		return result;
	}
	
	private static SimulationPosition generateSimulatedPosition(
		WSSAPContratosPedidos.Posicion_element reqPos,
		WSSAPContratosPedidos.Posiciones_element resPos
	) {
		SimulationPosition pos = new SimulationPosition();
		
		pos.ivaTreatment = ivaCodeToName.get(reqPos.CondIVABenef);
		pos.provinceCode = provinceCodeToName.get(reqPos.DestinatarioMercancias);
		pos.amount = Integer.valueOf(reqPos.Cantidad);
		pos.productNumber = reqPos.CodigoMaterial;
		pos.isInTransit = transitProducts.contains(reqPos.CodigoMaterial);
		pos.productSector = reqPos.Sector;
		
		pos.generatePriceFromConditions(resPos.Condiciones);
		
		return pos;
	}
	
	//Static collections for use preparing the simulated positions to be shown
	private static Map<String, String> provinceCodeToName;
	private static Map<String, String> ivaCodeToName;
	private static Set<String> transitProducts;
	
	private static void prepareStaticCollections() {
		provinceCodeToName = new Map<String, String>();
		ivaCodeToName = new Map<String, String>();
		transitProducts = new Set<String>();
		
		for(Interlocutor_Provincia__c ilp : Interlocutor_Provincia__c.getAll().values()) {
			provinceCodeToName.put(ilp.Codigo_SAP__c, ilp.Name);
		}
		
		for(Schema.PicklistEntry iva :
			Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()
		) {
			ivaCodeToName.put(iva.getValue(), iva.getLabel());
		}
		
		for(Producto_Transito__c pt : Producto_Transito__c.getAll().values()) {
			transitProducts.add(pt.Name + ' TRA');
		}
	}
}
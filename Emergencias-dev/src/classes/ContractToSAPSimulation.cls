public class ContractToSAPSimulation extends ContractToSAPConverterBase {
	private Map<Integer, SimulationPosition> positionsToSend;
	
	public ContractToSAPSimulation(Id contractId, List<SimulationPosition> posToSend) {
		super(contractId, 'S');
		
		positionsToSend = new Map<Integer, SimulationPosition>();
		integer i = 1;
		for(SimulationPosition pos : posToSend) {
			positionsToSend.put(i * 100, pos);
			i++;
		}
	}
	
	public override WSSAPContratosPedidos.Pedido_element generateRequest() {
		WSSAPContratosPedidos.Pedido_element result = super.generateRequest();
		
		result.ListaPosiciones = new WSSAPContratosPedidos.ListaPosiciones_element();
		result.ListaPosiciones.Posicion = generatePositions();
		
		return result;
	}
	
	public List<SimulationPosition> applyReceivedPrices(
		List<WSSAPContratosPedidos.Posiciones_element> responsePositions
	) {
		for(WSSAPContratosPedidos.Posiciones_element respPos : responsePositions) {
			SimulationPosition posSent =
				positionsToSend.get(Integer.valueOf(respPos.Posicion));
			
			if(respPos.Condiciones != null) {
				posSent.generatePriceFromConditions(respPos.Condiciones);
			}
		}
		
		return positionsToSend.values();
	}
	
	private List<WSSAPContratosPedidos.Posicion_element> generatePositions() {
		List<WSSAPContratosPedidos.Posicion_element> result =
			new List<WSSAPContratosPedidos.Posicion_element>();
		
		for(Integer posNum : positionsToSend.keySet()) {
			SimulationPosition posToSend = positionsToSend.get(posNum);
			WSSAPContratosPedidos.Posicion_element pos = new WSSAPContratosPedidos.Posicion_element();
			
			pos.TipoOperacion = operation;
			pos.NumeroPosicion = String.valueOf(posNum);
			pos.CondIVABenef = posToSend.ivaTreatment;
			pos.Cantidad = ContractToSAPConverterBase.formatNumber(posToSend.amount, 3);
			pos.Sector = posToSend.productSector;
			pos.CodigoMaterial = posToSend.productNumber;
			pos.DestinatarioMercancias = posToSend.provinceCode;
			
			pos.Condiciones = new List<WSSAPContratosPedidos.Condiciones_element>();
			for(AgregarProductosController.DiscountToAddWrapper discWrp :
				posToSend.discountsToSend
			) {
				if(discWrp.Discount.Codigo_de_descuento__c != 'ZDV1') {
					pos.Condiciones.add(generateCondition(discWrp));
				}
			}
			
			result.add(pos);
		}
		
		return result;
	}
	
	private WSSAPContratosPedidos.Condiciones_element generateCondition(
		AgregarProductosController.DiscountToAddWrapper wrp
	) {
		WSSAPContratosPedidos.Condiciones_element result =
			new WSSAPContratosPedidos.Condiciones_element();
		
		result.TipoOperacion = 'S';
		result.ClaseCondicion = wrp.Discount.Codigo_de_descuento__c;
		if(result.ClaseCondicion == 'ZDV0' || result.ClaseCondicion == 'ZDR0') {
			result.Importe = ContractToSAPConverterBase.formatNumber(wrp.Relation.Valor__c, 2);
		}
		else {
			result.Importe = ContractToSAPConverterBase.formatNumber(wrp.Discount.Valor__c, 2);
		}
		result.Unidad = wrp.Discount.Unidad__c;
		
		if(wrp.Relation.Fecha_inicio__c != null) {
			result.FechaInicioValidez =
				ContractToSAPConverterBase.formatDate(wrp.Relation.Fecha_inicio__c);
		}
		else {
			result.FechaInicioValidez = ContractToSAPConverterBase.formatDate(System.today());
		}
		if(wrp.Relation.Fecha_Fin__c != null) {
			result.FechaFinValidez =
				ContractToSAPConverterBase.formatDate(wrp.Relation.Fecha_Fin__c);
		}
		else {
			result.FechaFinValidez = '99991231';
		}
		
		return result;
	}
}
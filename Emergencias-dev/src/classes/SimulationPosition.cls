public class SimulationPosition {
	public String ivaTreatment {get; set;}
	public String provinceCode {get; set;}
	public Boolean isInTransit {get; set;}
	public Integer index {get; set;}
	public Integer amount {get; set;}
	
	public Decimal basePrice {get; set;}
	public Decimal noIvaPrice {get; set;}
	public Decimal priceIVA {get; set;}
	
	public String productNumber {get; set;}
	public String productSector;
	
	public List<SimulationCondition> discounts {get; set;}
	public List<SimulationCondition> surcharges {get; set;}
	
	public List<AgregarProductosController.DiscountToAddWrapper> discountsToSend;
	
	public SimulationPosition() {
		index = -1;
		productNumber = null;
		productSector = null;
		discountsToSend = new List<AgregarProductosController.DiscountToAddWrapper>();
		discounts = new List<SimulationCondition>();
		surcharges = new List<SimulationCondition>();
	}
	
	public void generatePriceFromConditions(
		List<WSSAPContratosPedidos.Condicion_IN_element> conditions
	) {
		discounts = new List<SimulationCondition>();
		surcharges = new List<SimulationCondition>();
		priceIVA = 0;
		basePrice = 0;
		noIvaPrice = 0;
		
		if(conditions != null) {
			for(WSSAPContratosPedidos.Condicion_IN_element cond : conditions) {
				decimal conditionValue = numberFromSAPValue(cond.Importe);
				if(cond.Condicion == 'ZPR0'
					|| cond.Condicion == 'ZPVS'
					|| cond.Condicion == 'ZPR2'
				) {// Base price conditions
					basePrice += conditionValue;
					noIvaPrice += conditionValue;
				}
				else if(cond.Condicion == 'J1AX') {//Iva condition
					priceIVA = conditionValue;
				}
				else {
					noIvaPrice += conditionValue;
					SimulationCondition simCond = new SimulationCondition(
						cond.Condicion,
						conditionValue
					);
					if(conditionValue < 0) {
						discounts.add(simCond);
					}
					else {
						surcharges.add(simCond);
					}
				}
			}
		}
	}
	
	private decimal numberFromSAPValue(String sapVal) {
		sapVal = sapVal.replace(' ', '');
		if(sapVal.right(1) == '-') {
			return - Decimal.valueOf(sapVal.left(sapVal.length() - 1));
		}
		else {
			return Decimal.valueOf(sapVal);
		}
	}
	
	public class SimulationCondition {
		public String code {get; set;}
		public Decimal price {get; set;}
		
		public SimulationCondition(String code, Decimal price) {
			this.code = code;
			this.price = price;
		}
	}
}
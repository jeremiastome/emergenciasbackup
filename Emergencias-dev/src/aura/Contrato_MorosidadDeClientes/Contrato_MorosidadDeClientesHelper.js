({
	getBgColorForContract: function(contract) {
		if(contract.Cliente__r.Morosidad_SAP__c == '30') {
			return "yellowBg";
		}
		else if(contract.Cliente__r.Morosidad_SAP__c == '60') {
			return "orangeBg";
		}
		else if(contract.Cliente__r.Morosidad_SAP__c == '90') {
			return "redBg";
		}
		else {
			return "greenBg";
		}
	}
})
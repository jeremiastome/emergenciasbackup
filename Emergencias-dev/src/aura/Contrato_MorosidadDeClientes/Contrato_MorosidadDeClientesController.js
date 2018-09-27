({
	checkPayment : function(component, event, helper) {
		component.set("v.isLoading", true);
		XappiaUtils.callApex(
			component,
			"getContractsWithSamePaymentMethod",
			function(succeed, contracts, errors) {
				if(succeed) {
					for (var i = 0; i < contracts.length; i++) {
						contracts[i].Cliente__r.bgColor = helper.getBgColorForContract(contracts[i]);
					}
					component.set("v.contractsWithSamePayment", contracts);
				}
				else {
					XappiaUtils.showToast("Error", $A.get("$Label.c.Error_trayendo_datos_contratos_similares"), {"type":"error"});
					console.log(errors);
				}
				component.set("v.isLoading", false);
			},
			{contractId:component.get("v.recordId")}
		);
	},
	
	onClickLink : function(component, event, helper) {
		event.preventDefault();
		var navEvt = $A.get("e.force:navigateToSObject");
		navEvt.setParams({
			"recordId": event.getSource().get('v.href')
		});
		navEvt.fire();
	}
})
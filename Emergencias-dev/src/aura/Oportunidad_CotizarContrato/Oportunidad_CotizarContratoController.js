({
	doInit: function (component, event, helper) {
		if(!(XappiaUtils && component.get("v.oppRecord"))) {
			return;
		}
		
		XappiaUtils.callApex(
			component,
			"canBeSimulated",
			function(success, result, errors) {
				if(success) {
					component.set("v.canSimulate", result);
				}
				else {
					XappiaUtils.showToast(
						"Error",
						$A.get("$Label.c.Error_buscando_datos_de_oportunidad"),
						{type: "error"}
					);
					console.log(errors);
				}
			},
			{"contractId": component.get("v.oppRecord").Contrato__c}
		);
	},
	
	closeModal: function (component, event, helper) {
		component.set("v.showModal", false);
	},
	
	simulate: function (component, event, helper) {
		component.set("v.isLoading", true);
		XappiaUtils.callApex(
			component,
			"simulateContract",
			function(success, simResultJSON, errors) {
				if(success) {
					var simResult = JSON.parse(simResultJSON);
					var simSuccess = simResult.status.Tipo == "S";
					component.set("v.showModal", simSuccess);
					
					if(simSuccess) {
						simResult.totalPrice = 0;
						for (var i = 0; i < simResult.positions.length; i++) {
							simResult.totalPrice += helper.preparePosition(simResult.positions[i]);
						}
						
						simResult.totalPrice = simResult.totalPrice.toFixed(2);
						
						component.set("v.simulationResult", simResult);
					}
					else {
						XappiaUtils.showToast(
							"Error",
							simResult.status.Descripcion,
							{type: "error"}
						);
					}
				}
				else {
					XappiaUtils.showToast(
						"Error",
						$A.get("$Label.c.Error_buscando_datos_de_oportunidad"),
						{type: "error"}
					);
					console.log(errors);
				}
				component.set("v.isLoading", false);
			},
			{"contractId": component.get("v.oppRecord").Contrato__c}
		);
	},
	
	toggleSimDetails: function (component, event, helper) {
		console.log(event);
		var i = event.target.getAttribute("data-posindex");
		if(i == null) {
			i = event.target.parentElement.getAttribute("data-posindex");
		}
		
		var simRes = component.get("v.simulationResult");
		simRes.positions[i].showDetails = !simRes.positions[i].showDetails;
		component.set("v.simulationResult", simRes);
	}
})
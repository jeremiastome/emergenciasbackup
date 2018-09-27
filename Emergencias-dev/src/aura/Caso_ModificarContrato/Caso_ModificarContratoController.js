({
	init: function (component, event, helper) {
		var recordId = component.get("v.recordId");
		var callsInProgress = 2;
		XappiaUtils.callApex(
			component,
			"getClonedContract",
			function(success, contract, errors) {
				if(success) {
					component.set("v.hasContract", !!contract);
					if(contract) {
						component.set("v.contractId", contract.Id);
						component.set("v.contractIsMassive", contract.Contrato_de_Padrones__c);
						component.set("v.contractDistChannel", contract.Canal_de_Distribucion__c);
						
						var holders = [];
						for (var i = 0; i < contract.Titulares__r.length; i++) {
							holders[i] = {
								value: contract.Titulares__r[i].Id,
								label: contract.Titulares__r[i].Cliente__r.Name
							};
						}
						
						component.set("v.holders", holders);
						component.set("v.holderId", holders[0].value);
					}
				}
				else {
					XappiaUtils.showToast(
						"Error",
						$A.get("$Label.c.Error_obteniendo_datos_del_caso"),
						{type:"error"}
					);
					console.log(errors);
				}
				callsInProgress--;
				if(!callsInProgress) {
					component.set("v.isLoading", false);
				}
			},
			{caseId: recordId}
		);
		
		XappiaUtils.callApex(
			component,
			"getSettingsType",
			function(success, caseSettings, errors) {
				if(success) {
					component.set("v.caseSettingsType", caseSettings);
				}
				else {
					XappiaUtils.showToast(
						"Error",
						$A.get("$Label.c.Error_obteniendo_datos_del_caso"),
						{type:"error"}
					);
					console.log(errors);
				}
				callsInProgress--;
				if(!callsInProgress) {
					component.set("v.isLoading", false);
				}
			},
			{caseId: recordId}
		);
	},
	
	goToAddProducts: function (component, event, helper) {
		var url = "/apex/AgregarProductos"
			+ "?id=" + component.get("v.contractId")
			+ "&retId=" + component.get("v.recordId");
		if(component.get("v.AddProductsOnlyDiscounts")) {
			url += "&onlyDisc=T";
		}
		
		var urlEvent = $A.get("e.force:navigateToURL");
		urlEvent.setParams({"url":url});
		urlEvent.fire();
	},
	
	goToAddRecipients: function (component, event, helper) {
		var url;
		if(component.get("v.contractIsMassive")) {
			url = "AsignacionDePadrones"
		}
		else {
			url = "AsignacionDeBeneficios";
		}
		var urlEvent = $A.get("e.force:navigateToURL");
		urlEvent.setParams({
			"url": "/apex/" + url
				+ "?id=" + component.get("v.contractId")
				+ "&retId=" + component.get("v.recordId")
		});
		urlEvent.fire();
	}
})
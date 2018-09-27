({
	init: function (component, event, helper) {
        
		var contractId = component.get("v.recordId");
        var contract;
		XappiaUtils.callApex(
			component,
			"getContractFields",
			function(success, contract, errors) {
				if(success) {
                    component.set("v.contractRecord", contract);
                    console.log(contract);
					helper.getContacts(component, contract);
                } else {
                	component.set("v.showFields", false);
					component.set("v.severity", "error");
                    component.set("v.message", "Puede no tener permisos para usar este componente.");
					console.log(errors);
                }
                component.set("v.isLoading", false);
			},
			{contractId: contractId}
		);
	},

	
	save: function (component, event, helper) {
		XappiaUtils.callApex(
			component,
			"saveContacts",
			function(succeed, result, errors) {
                if(succeed) {
					if(result=='Se han guardado correctamente los cambios.') {
						component.set("v.severity", "success");
						component.set("v.message", result);
					} else {
						component.set("v.severity", "error");
						component.set("v.message", "Ha ocurrido un error al intentar guardar los cambios: "+result);
					}

				} else {
					component.set("v.severity", "error");
                    component.set("v.message", "Ha ocurrido un error al intentar guardar los cambios.");
					console.log(errors);
				}
				component.set("v.isLoading", false);
			},
			{contract:component.get("v.contractRecord")}
		);
	}
})
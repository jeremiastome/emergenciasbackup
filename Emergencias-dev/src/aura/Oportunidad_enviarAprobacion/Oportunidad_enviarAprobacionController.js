({
	startApproval: function (component, event, helper) {
		component.set("v.isLoading", true);
		component.set("v.severity", null);
		component.set("v.message", null);
		XappiaUtils.callApex(
			component,
			"sendForApproval",
			function(succeed, result, errors) {
				if(succeed) {
					if (result == $A.get("$Label.c.Oportunidad_enviada_a_aprobacion")) {
						component.set("v.severity", "success");
					} else {
						component.set("v.severity", "warning");
					}

					component.set("v.message", result);
						
				} else {
				
					var errorMessage = '';
					try {
						errorMessage = errors[0].pageErrors[0].message;
					}
					catch (err){
						errorMessage = errors[0].message;
					}
					console.log(errors[0]);
					component.set("v.severity", "error");
                    component.set("v.message", errorMessage);
						//$A.get("$Label.c.Error_enviando_oportunidad_a_aprobacion") + '' + errorMessage);
					
				}

				component.set("v.isLoading", false);
			},
			{oppId:component.get("v.recordId")}
		);
	}
})
({   
    callSAP: function (component, event, helper) {
		component.set("v.isLoading", true);
		component.set("v.severity", null);
		component.set("v.message", null);
		XappiaUtils.callApex(
			component,
			"createPositionByCreditNote",
			function(succeed, result, errors) {

				if(succeed) {
					if (result =='Ok' ) {
						component.set("v.severity", "success");
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            "url":"/apex/EditorPosiciones?id=" + component.get("v.recordId")
                        });
                        urlEvent.fire();
						component.set("v.isLoading", false);
					} else {
						component.set("v.severity", "warning");
						component.set("v.isLoading", false);
                    	component.set("v.message", result);
					}
				} else {
					component.set("v.severity", "error");
                    component.set("v.message", "Error: Ha ocurrido un error en la conexion. Intente mas tarde.");
					console.log(errors);
					component.set("v.isLoading", false);
				}

			},
			{CaseId:component.get("v.recordId")}
		);
	}
})
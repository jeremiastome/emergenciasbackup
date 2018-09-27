({
	init: function (component, event, helper) {
		var recordId = component.get("v.recordId");
		XappiaUtils.callApex(
			component,
			"getContract",
			function(success, contractId, errors) {
				if(success) {
					component.set("v.contractId", contractId);
					component.set("v.hasContract", !!contractId);
				}
				else {
					XappiaUtils.showToast(
						"Error",
						$A.get("$Label.c.Error_obteniendo_datos_del_caso"),
						{type:"error"}
					);
					console.log(errors);
				}
				component.set("v.isLoading", false);
			},
			{caseId: recordId}
		);
	},
	
	onClick: function (component, event, helper) {
		var urlEvent = $A.get("e.force:navigateToURL");
		urlEvent.setParams({
			"url":"/apex/BajaParcial"
				+ "?caseId=" + component.get("v.recordId")
				+ "&contractId=" + component.get("v.contractId")
		});
		urlEvent.fire();
	}
})
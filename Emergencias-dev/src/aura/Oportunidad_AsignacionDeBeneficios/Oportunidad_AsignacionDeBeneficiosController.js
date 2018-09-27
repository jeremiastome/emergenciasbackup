({
	init: function (component, event, helper) {
		XappiaUtils.callApex(
			component,
			"getContractId",
			function(success, result, errors) {
				if(success) {
					component.set("v.contractId", result);
					component.set("v.hasContractId", !!result);
				}
				else {
					console.log(errors);
				}
			},
			{oppId: component.get("v.recordId")}
		);
	},

	BringAsignmentPage: function (component, event, helper) {
		var urlEvent = $A.get("e.force:navigateToURL");
		urlEvent.setParams({
			"url":"/apex/AsignacionDeBeneficios?id=" + component.get("v.contractId") + "&opp=" + component.get("v.recordId")
		});
		urlEvent.fire();
	}
})
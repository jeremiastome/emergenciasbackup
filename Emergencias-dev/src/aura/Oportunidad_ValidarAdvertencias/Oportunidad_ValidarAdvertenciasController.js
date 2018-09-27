({
	getOppWarnings: function (component, event, helper) {
		component.set("v.isLoading", true);
		var calls = 2;
		XappiaUtils.callApex(
			component,
			"getWarnings",
			function(succeed, warnings, errors) {
				if(succeed) {
					component.set("v.oppWarnings", warnings);
				}
				else {
					XappiaUtils.showToast("Error", $A.get("$Label.c.Error_trayendo_advertencias"), {"type":"error"});
					console.log(errors);
				}
				calls--;
				component.set("v.isLoading", calls != 0);
			},
			{oppId:component.get("v.recordId")}
		);

		XappiaUtils.callApex(
			component,
			"wasOpportunityValidated",
			function(succeed, validated, errors) {
				if(succeed) {
					component.set("v.oppValidated", validated);
				}
				else {
					XappiaUtils.showToast("Error", $A.get("$Label.c.Error_trayendo_advertencias"), {"type":"error"});
					console.log(errors);
				}

				calls--;
				component.set("v.isLoading", calls != 0);
			},
			{oppId:component.get("v.recordId")}
		);
	},

	validateOppWarnings: function (component, event, helper) {
		component.set("v.isLoading", true);
		XappiaUtils.callApex(
			component,
			"validateWarnings",
			function(succeed, warnings, errors) {
				if(succeed) {
					component.set("v.oppWarnings", warnings);
					component.set("v.oppValidated", true);
					$A.get('e.force:refreshView').fire();
				}
				else {
					XappiaUtils.showToast("Error", $A.get("$Label.c.Error_validar_advertencias"), {"type":"error"});
					console.log(errors);
				}
				console.log(warnings);
				component.set("v.isLoading", false);
			},
			{oppId:component.get("v.recordId")}
		);
	}
})
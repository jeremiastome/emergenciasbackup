({
	init: function (component, event, helper) {
		component.set("v.isLoading", false);
	},

	validateZone: function (component, event, helper) {
		component.set("v.isLoading", true);

		XappiaUtils.callApex(
			component,
			"getZoneForAccount",
			function(success, retVal, errors) {
				if(success) {
					$A.get("e.force:refreshView").fire();
					var strs = retVal.split("|");
					XappiaUtils.showToast("", strs[1], {type: strs[0]});
				}
				else {
					console.log(errors);
					XappiaUtils.showToast("", "Error", {type: "error"});
				}
				component.set("v.isLoading", false);
			},
			{accountId: component.get("v.recordId")}
		);
	}
})
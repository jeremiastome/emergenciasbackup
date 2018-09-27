({
	init: function (component, event, helper) {
		XappiaUtils.callApex(
			component,
			"contractHasProducts",
			function(success, hasProducts, errors) {
				if(success) {
					component.set("v.loaded", true);
					component.set("v.hasProducts", hasProducts);
					
					if(hasProducts) {
						XappiaUtils.callApex(
							component,
							"isForMasiveRecipients",
							function(success, isMasive, errors) {
								if(success) {
									component.set("v.loaded", true);
									component.set("v.isMasive", isMasive);
									
									if(component.get("v.clicked")) {
										helper.goToAsigner(component);
									}
								}
								else {
									XappiaUtils.showToast(
										"Error",
										"",
										{type:"error"}
									);
									console.log(errors);
								}
							},
							{contractId: component.get("v.recordId")}
						);
					}
				}
				else {
					XappiaUtils.showToast(
						"Error",
						"",
						{type:"error"}
					);
					console.log(errors);
				}
			},
			{contractId: component.get("v.recordId")}
		);
	},
	
	BringAsignmentPage: function (component, event, helper) {
		if(component.get("v.loaded")) {
			helper.goToAsigner(component);
		}
		else {
			component.set("v.clicked", true);
		}
	}
})
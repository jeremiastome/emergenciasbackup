({
	init: function (component, event, helper) {
		XappiaUtils.callApex(
			component,
			"getRecipientTypes",
			function(success, result, errors) {
				if(success) {
					var rts = [];
					for (var i = 0; i < result.length; i++) {
						var parts = result[i].split(";");
						rts[i] = {
							Name: parts[1],
							Id: parts[0]
						};
					}
					component.set("v.recipientTypes", rts);
				}
				else {
					console.log(errors);
					XappiaUtils.showToast(null, "Error", {type: "error"})
				}
				component.set("v.isLoading", false);
			}
		);
	},
	
	createRecipient: function (component, event, helper) {
		var createAcountContactEvent = $A.get("e.force:createRecord");
		var defaultVals = {
			"Titular__c" : component.get("v.holderId"),
			"Contrato__c" : component.get("v.contractId")
		};
		
		if(component.get("v.distributionChannel") === '10') {
			defaultVals.Tratamiento_IVA__c = 'BG';
		}
		var caseId = component.get("v.caseId");
		if(caseId) {
			defaultVals.Caso__c = caseId;
		}
		
		createAcountContactEvent.setParams({
			"entityApiName": "Beneficiario__c",
			"defaultFieldValues": defaultVals,
			"recordTypeId": event.target.getAttribute("value")
		});
		createAcountContactEvent.fire();
	}
})
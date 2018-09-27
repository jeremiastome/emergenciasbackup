({

	init: function (component, event, helper) {
		XappiaUtils.callApex(
			component,
			"getRecordTypes",
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
					component.set("v.RecordTypes", rts);
                    console.log(rts);
				}
				else {
					console.log(errors);
					XappiaUtils.showToast(null, "Error", {type: "error"})
				}
				component.set("v.isLoading", false);
			}
		);
	},

    toggle : function(component, event, helper) {
        component.set("v.isOpen", true);
		console.log("vamooos");
    },

	as : function(component, event, helper){
        component.set("v.isOpen", false);
	},

	createRecipient: function (component, event, helper) {
		var createAcountContactEvent = $A.get("e.force:createRecord");
		var defaultVals = {
			"Origin" : component.get("v.caseFields.Origin"),
			"Contrato__c" : component.get("v.caseFields.Contrato__c"),
			"AccountId" : component.get("v.caseFields.AccountId"),
			"Caso_maestro__c" : component.get("v.caseFields.Id"),
			"ParentId" : component.get("v.caseFields.Id")
		};
		
		//if(component.get("v.newCase.Id") === '10') {
		//	defaultVals.Tratamiento_IVA__c = 'BG';
		//}
		
		//var caseId = component.get("v.recordId");
		//if(caseId) {
		//	defaultVals.RecordTypeId = caseId;
		//}
		//console.log(event.getSource().get("v.recordId"));
		createAcountContactEvent.setParams({
			"entityApiName": "Case",
			"defaultFieldValues": defaultVals,
			"recordTypeId": component.get("v.recordId")
		});
		createAcountContactEvent.fire();
	},

	onChange: function (component, event, helper){
        var value = event.getSource().get("v.text");
		component.set('v.recordId', value);
	}

})
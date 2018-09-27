({
	goToNextCase: function (component, event, helper) {
		component.set("v.isLoading", true);
		XappiaUtils.callApex(
			component,
			"getNextCase",
			function(succeed, nextCase, errors) {
				if(succeed) {
					if(nextCase) {
						var navEvt = $A.get("e.force:navigateToSObject");
						navEvt.setParams({
						  "recordId": nextCase.Id,
						  "slideDevName": "detail"
						});
						navEvt.fire();
					}
					else {
						XappiaUtils.showToast("", $A.get("$Label.c.No_hay_caso_para_asignacion"), {type:"warning"});
					}
				}
				else {
					console.log(errors);
					XappiaUtils.showToast("Error", $A.get("$Label.c.Error_buscando_caso_de_cola"), {type:"error"});
				}
				component.set("v.isLoading", false);
			},
			{
				queueName: component.get("v.QueueName"),
				reason: component.get("v.CaseReason"),
				allowMultipleCases: component.get("v.allowMultipleCases")
			}
		);
	}
})
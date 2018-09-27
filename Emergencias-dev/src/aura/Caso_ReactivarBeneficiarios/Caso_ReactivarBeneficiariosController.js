({
	init: function (component, event, helper) {
		var caseId = component.get("v.recordId");
		XappiaUtils.callApex(
			component,
			"getRecipients",
			function(success, recipients, errors) {
				if(success) {
					for (var i = 0; i < recipients.length; i++) {
						recipients[i].isActive = recipients[i].Caso__c == caseId;
						
						if(recipients[i].Coberturas__r) {
							for (var j = 0; j < recipients[i].Coberturas__r.length; j++) {
								recipients[i].Coberturas__r[j].isActive =
									recipients[i].Coberturas__r[j].Caso__c == caseId;
							}
						}
					}
					
					component.set("v.recipients", recipients);
				}
				else {
					console.log(errors);
					XappiaUtils.showToast(
						"Error",
						$A.get("$Label.c.Error_obteniendo_datos_del_caso"),
						{type:"error"}
					);
				}
			},
			{caseId: caseId}
		);
	},
	
	save: function (component, event, helper) {
		var caseId = component.get("v.recordId");
		var recipients = component.get("v.recipients");
		var coverages = [];
		
		for (var i = 0; i < recipients.length; i++) {
			if(recipients[i].isActive) {
				recipients[i].Caso__c = caseId;
			}
			else {
				recipients[i].Caso__c = null;
			}
			
			if(recipients[i].Coberturas__r) {
				for (var j = 0; j < recipients[i].Coberturas__r.length; j++) {
					if(recipients[i].Coberturas__r[j].isActive) {
						recipients[i].Coberturas__r[j].Caso__c = caseId;
					}
					else {
						recipients[i].Coberturas__r[j].Caso__c = null;
					}
					coverages.push(recipients[i].Coberturas__r[j]);
				}
			}
		}
		console.log(coverages);
		XappiaUtils.callApex(
			component,
			"saveRecipients",
			function(success, result, errors) {
				if(success) {
					XappiaUtils.showToast(
						"",
						$A.get("$Label.c.Caso_guardado_excitosamente"),
						{type:"success"}
					);
				}
				else {
					console.log(errors);
					XappiaUtils.showToast(
						"Error",
						$A.get("$Label.c.Error_guardando_caso"),
						{type:"error"}
					);
				}
			},
			{recipients: recipients, coverages: coverages}
		);
	},
	
	onCoverageChange: function (component, event, helper) {
		var eventSource = event.getSource();
		var recId = eventSource.getElement().parentElement.getAttribute("data-rec");
		var recipients = component.get("v.recipients");
		
		if(eventSource.get("v.value")) {
			for (var i = 0; i < recipients.length; i++) {
				if(recipients[i].Id === recId) {
					recipients[i].isActive = true;
					break;
				}
			}
			component.set("v.recipients", recipients);
		}
	},
	
	onRecipientChange: function (component, event, helper) {
		var eventSource = event.getSource();
		var recId = eventSource.getElement().parentElement.getAttribute("data-rec");
		var recipients = component.get("v.recipients");
        
        console.log(recipients);
		
		if(!eventSource.get("v.value")) {
			for (var i = 0; i < recipients.length; i++) {
				if(recipients[i].Id === recId) {
                    
                    try {
                        for (var j = 0; j < recipients[i].Coberturas__r.length; j++) {
                            recipients[i].Coberturas__r[j].isActive = false;
                        }
                    } catch (err) {
                        console.log('No hay coberturas en ese beneficiario');
                    }
                    
					break;
				}
			}
			component.set("v.recipients", recipients);
		}
	}
})
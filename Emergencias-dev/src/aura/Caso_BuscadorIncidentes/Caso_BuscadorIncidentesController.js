({
	init: function (component, event, helper) {
		XappiaUtils.callApex(
			component,
			"getSavedIncidents",
			function(status, result, errors) {
				if(status) {
					var incidentNumbers = {};
					for (var i = 0; i < result.length; i++) {
						incidentNumbers[result[i].Numero_de_Servicio__c] = true;
					}
					
					component.set("v.savedIncidents", result);
					component.set("v.savedIncidentNumbers", incidentNumbers);
				}
				else {
					XappiaUtils.showToast("Error", $A.get("$Label.c.Error_buscando_incidentes"), {"type":"error"});
					console.log(errors);
				}
				component.set("v.isLoading", false);
			},
			{caseId: component.get("v.recordId")}
		)
	},
	
	GetIncidents: function (component, event, helper) {
		var params = {
			"entityType": component.get("v.entityType"),
			"entityNumber": component.get("v.entityNumber"),
			"timeTo": component.get("v.dateTo"),
			"timeFrom": component.get("v.dateFrom")
		};
		
		if(helper.areFieldsValid(component, params)) {
			component.set("v.isLoading", true);
			XappiaUtils.callApex(
				component,
				"SearchIncidents",
				function(status, result, errors) {
					if(status) {
						var resp;
						try {
							resp = JSON.parse(result);
						}
						catch(err) {
							XappiaUtils.showToast("Error", $A.get("$Label.c.Error_buscando_incidentes"), {"type":"error"});
							console.log(result);
							resp = false;
						}
						
						if(resp) {
							//Keep active incidents in the new list
							var savedIncidentNumbers = component.get("v.savedIncidentNumbers");
							var incidents = helper.getActiveIncidents(component.get("v.incidents"));
							var incidentNumbers = helper.getIncidentNumberSet(incidents);
							for (var i = 0; i < resp.RCDServiceList.length; i++) {
								var num = resp.RCDServiceList[i].NumServicio;
								if(!(incidentNumbers[num] || savedIncidentNumbers[num])) {
									incidents[incidents.length] = helper.prepareIncident(resp.RCDServiceList[i]);
									incidentNumbers[num] = true;
								}
							}
							
							component.set("v.incidents", incidents);
							component.set("v.selectAll", helper.areAllActive(incidents));
						}
					}
					else {
						XappiaUtils.showToast("Error", $A.get("$Label.c.Error_buscando_incidentes"), {"type":"error"});
						console.log(errors);
					}
					component.set("v.isLoading", false);
				},
				params
			);
		}
	},
	
	OnSelectAll: function (component, event, helper) {
		var incidents = component.get("v.incidents");
		var activeVal = component.get("v.selectAll");
		
		for (var i = 0; i < incidents.length; i++) {
			incidents[i].isActive = activeVal;
		}
		
		component.set("v.incidents", incidents);
	},
	
	OnSelectOne: function (component, event, helper) {
		var incidents = component.get("v.incidents");
		
		component.set("v.selectAll", helper.areAllActive(incidents));
	},
	
	Save: function (component, event, helper) {
		var incidents = helper.getActiveIncidents(component.get("v.incidents"));
		if(incidents.length > 0) {
			component.set("v.isLoading", true);
			
			var incidentsSObj = [];
			for (var i = 0; i < incidents.length; i++) {
				incidentsSObj[incidentsSObj.length] = helper.transformToSalesforceIncident(incidents[i]);
			}
			var params = {
				incidentsJSON: JSON.stringify(incidentsSObj),
				caseId: component.get("v.recordId")
			};
			XappiaUtils.callApex(component, "saveIncidents",
				function(status, result, errors) {
					if(status) {
						XappiaUtils.showToast("", $A.get("$Label.c.Guardado_de_incidentes_exitoso"), {"type":"success"});
						helper.updateIncidentLists(component, incidentsSObj);
					}
					else {
						XappiaUtils.showToast("Error", $A.get("$Label.c.Error_al_guardar_incidentes"), {"type":"error"});
						console.log(errors);
					}
					component.set("v.isLoading", false);
				},
				params
			);
		}
		else {
			XappiaUtils.showToast("Error", $A.get("$Label.c.Error_no_hay_incidentes_para_guardar"), {"type":"error"});
		}
	}
})
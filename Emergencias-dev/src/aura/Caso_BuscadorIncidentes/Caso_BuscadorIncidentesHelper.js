({
	getActiveIncidents: function(incidents) {
		var result = [];
		for (var i = 0; i < incidents.length; i++) {
			if(incidents[i].isActive) {
				result[result.length] = incidents[i];
			}
		}
		
		return result;
	},
	
	transformToSalesforceIncident: function(inc) {
		return {
			"Clasificacion__c": inc.Clasificacion,
			"Estado__c": inc.Estado,
			"Instante__c": inc.Instante,
			"Nombre_de_Paciente__c": inc.NomPaciente,
			"Numero_de_Entidad__c": inc.NumEntidad,
			"Numero_de_Servicio__c": inc.NumServicio,
			"Detalles__c": inc.DetalleUrl
		};
	},
	
	areFieldsValid: function(component, params) {
		var validFields = true;
		var dates = {
			"from": new Date(params.timeFrom),
			"to": new Date(params.timeTo)
		}
		
		if(!params.entityNumber) {
			component.find("inputEntityNumber").set("v.errors", $A.get("$Label.c.Error_no_cargo_numero_de_entidad"));
			component.set("v.showEntityNumError", true);
			validFields = false;
		}
		else {
			component.find("inputEntityNumber").set("v.errors", null);
			component.set("v.showEntityNumError", false);
		}
		
		if(params.timeTo && params.timeFrom && dates.to.getTime() < dates.from.getTime()) {
			component.find("inputDateFrom").set("v.errors", $A.get("$Label.c.Error_fecha_desde_mayor_que_fecha_hasta"));
			component.set("v.showDateError", true);
			validFields = false;
		}
		else {
			component.find("inputDateFrom").set("v.errors", null);
			component.set("v.showDateError", false);
		}
		
		return validFields;
	},
	
	areAllActive: function(incidents) {
		var activeVal = true;
		
		for (var i = 0; i < incidents.length; i++) {
			if(!incidents[i].isActive) {
				activeVal = false;
				break;
			}
		}
		
		return activeVal;
	},
	
	updateIncidentLists: function(component, newIncidents) {
		var savedIncidentNumbers = component.get("v.savedIncidentNumbers");
		var incidents = component.get("v.incidents");
		var savedIncidents = component.get("v.savedIncidents");
		var inactiveIncidents = [];
		
		//Add the newly saved incidents to the list
		for (var i = 0; i < newIncidents.length; i++) {
			savedIncidents[savedIncidents.length] = newIncidents[i];
			savedIncidentNumbers[newIncidents[i].Numero_de_Servicio__c] = true;
		}
		//refresh the list of not saved incidents
		for (var i = 0; i < incidents.length; i++) {
			if(!incidents[i].isActive) {
				inactiveIncidents[inactiveIncidents.length] = incidents[i];
			}
		}
		
		component.set("v.incidents", inactiveIncidents);
		component.set("v.savedIncidents", savedIncidents);
		component.set("v.savedIncidentNumbers", savedIncidentNumbers);
	},
	
	getIncidentNumberSet: function(incidents) {
		var result = {};
		for (var i = 0; i < incidents.length; i++) {
			result[incidents[i].NumServicio] = true;
		}
		return result;
	},
	
	prepareIncident: function(baseIncident) {
		baseIncident.isActive = false;
		baseIncident.Instante = new Date(
			parseInt(
				baseIncident.Instante.split("(")[1].split("-")[0]
			)
		);
		baseIncident.DetalleUrl =
			"http://ersitiosweb/PropiedadesAsistenciaRCD/ConsultaAsistencia.aspx?NumAsistencia="
			+ baseIncident.NumServicio;
		return baseIncident;
	}
})
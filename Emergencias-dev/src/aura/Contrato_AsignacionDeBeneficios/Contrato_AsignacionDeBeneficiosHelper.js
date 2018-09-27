({
	goToAsigner: function(component) {
		var apexPage;
		if(component.get("v.isMasive")) {
			apexPage = "AsignacionDePadrones";
		}
		else {
			apexPage = "AsignacionDeBeneficios";
		}
		
		var urlEvent = $A.get("e.force:navigateToURL");
		urlEvent.setParams({
			"url":"/apex/" + apexPage + "?id=" + component.get("v.recordId")
		});
		urlEvent.fire();
	}
})
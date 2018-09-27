({
	ResendFactJS : function(component, event, helper) {
		
		component.set("v.isLoading", true);
		
		var msgError = $A.get("$Label.c.ReenvioFacturasError") || "Reenvio fallido";
		var msgExito = $A.get("$Label.c.ReenvioFacturasExito") || "Reenvio programado";

		XappiaUtils.callApex(
			component,
			"resendFact",
			function(status, result, errors) {
				if(status) {
					XappiaUtils.showToast("Terminado", msgExito, {"type":"success"});
				}
				else {
					XappiaUtils.showToast("Error", msgError, {"type":"error"});
					console.log(errors);
				}
				component.set("v.isLoading", false);
			},
			{facNum: component.get("v.facNumber"), mail: component.get("v.altMail")}
		)		
	}
})
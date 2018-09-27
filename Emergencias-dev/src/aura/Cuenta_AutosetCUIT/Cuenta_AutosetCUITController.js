({
	AutosetCUIT : function(component, event, helper) {
		
		component.set("v.isLoading", true);
		
		var msgError = "Ocurrio un error con la generacion";
		var msgExito = "Generado con exito";
		var recordId = component.get("v.recordId");
		XappiaUtils.callApex(
			component,
			"AutosetCUITToAcc",
			function(status, result, errors) {                
				if(status) {
                    console.log(result);
                    if (result=='')
                    {
						XappiaUtils.showToast("Success", msgExito, {"type":"success"});                    
                    	$A.get('e.force:refreshView').fire();
                    }
                    else
                    {
                        XappiaUtils.showToast("Warning", result, {"type":"warning"});
                    }
				}
				else {
					XappiaUtils.showToast("Error", msgError, {"type":"error"});
					console.log(errors);
				}
				component.set("v.isLoading", false);
			},
			{accountId: recordId}
		)		
	}
})
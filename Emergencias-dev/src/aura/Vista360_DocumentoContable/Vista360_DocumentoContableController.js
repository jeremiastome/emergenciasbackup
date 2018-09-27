({
  verDetalles: function (component, event, helper) {
    var nroDoc = component.get("v.documento.numeroDocumento");
    component.set("v.nroDocumentoRemoto", nroDoc || '');
    component.set("v.showModal", "true");
  },     
    
    createCase: function(component, event, helper) {
        var createRecordEvent = $A.get("e.force:createRecord");
        var documento = component.get("v.documento");
        console.log(documento.Contrato);
        
        createRecordEvent.setParams({
            "entityApiName": "Case",
            "defaultFieldValues": {
               'Nro_de_Factura__c' : documento.numeroDocumento,
                'Contrato__c' : documento.Contrato,
				'Con_referencia_a_factura__c' : 'Si'
    		},
            "recordTypeId" : documento.recordTypeId
            
        });
        createRecordEvent.fire();
    
    },
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
({
  obtenerEstado: function (component) {

    this.toggleSpinner(component, true);

    var action = component.get('c.obtenerEstadoContrato');
	console.log(component.get('v.contractRecord.fields.Cliente__c.value'));
	console.log(component.get('v.contractRecord.fields.Sociedad__c.value'));
	console.log(component.get('v.contractRecord.fields.Numero_Unico_de_Contrato_Con_Sufijo__c.value'));
      
      
      
    action.setParams({
      idCliente: component.get('v.contractRecord.fields.Cliente__c.value'),
      idSociedad: component.get('v.contractRecord.fields.Sociedad__c.value'),
      numContrato: component.get('v.contractRecord.fields.Numero_Unico_de_Contrato_Con_Sufijo__c.value')
    });

    action.setCallback(this, function(response) {
      
      if (response.getState() === 'SUCCESS') {

        var estado = response.getReturnValue();
        console.log(estado);
          console.log(estado.pagos);
          console.log(estado.notasDeCredito);
        component.set('v.estado', estado);
        component.set('v.RecordTypeId', estado.recordTypeId);
        var childCmp = component.find("cSaldo")
 		childCmp.darSaldo();

      } else {
        
        console.log(response.getState());
          
        console.log(response);
      }

      this.toggleSpinner(component, false);
    });

    $A.enqueueAction(action);
  },

  toggleSpinner: function (component, show) {
    
    var spinner = component.find("spinner");
    
    if (show) {
      $A.util.removeClass(spinner, "slds-hide");
    } else {
      $A.util.addClass(spinner, "slds-hide");
    }
  }
})
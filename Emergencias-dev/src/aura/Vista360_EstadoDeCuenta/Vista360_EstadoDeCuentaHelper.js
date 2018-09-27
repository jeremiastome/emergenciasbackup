({
  obtenerEstado: function (component) {

    this.toggleSpinner(component, true);

    var action = component.get('c.obtenerEstadoCuenta');

    action.setParams({
      idCliente: component.get('v.clienteRecord.fields.N_mero_nico_de_Cliente__c.value'),
      idSociedad: component.get('v.clienteRecord.fields.Sociedad__c.value')
    });

    action.setCallback(this, function(response) {
      
      if (response.getState() === 'SUCCESS') {

        var estado = response.getReturnValue();
        console.log(estado);
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
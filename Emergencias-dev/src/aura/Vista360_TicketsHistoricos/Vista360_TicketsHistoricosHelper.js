({
  obtenerTickets: function (component) {

    this.toggleSpinner(component, true);

    var action = component.get('c.obtenerTicketsHistoricos');

    action.setParams({
      idCliente: component.get('v.recordId')
    });

    action.setCallback(this, function(response) {
      
      if (response.getState() === 'SUCCESS') {

        var tickets = response.getReturnValue();
        console.log(tickets);
        component.set('v.tickets', tickets);

      } else {
        
        console.log(response.getState());
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
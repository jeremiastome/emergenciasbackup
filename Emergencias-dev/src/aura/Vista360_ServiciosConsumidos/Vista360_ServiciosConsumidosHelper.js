({
  doInit: function (component) {
      this.setDate(component);
      this.obtenerServicios(component);
  },

  obtenerServicios: function (component) {
    this.toggleSpinner(component, true);
    var action = component.get('c.obtenerServiciosConsumidos');

    action.setParams({
      idCliente: component.get('v.recordId'),
      dateTo: component.get('v.dateTo'),
      dateFrom: component.get('v.dateFrom')
    });

    action.setCallback(this, function(response) {

      if (response.getState() === 'SUCCESS') {

        var listasServicios = response.getReturnValue();
        console.log('Lista de servicios: '+listasServicios);
        component.set('v.listasServicios', listasServicios);

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
  },

  setDate: function (component) {
    var dateTo = new Date();
    var dateFrom = new Date();
    dateFrom.setHours(0);
    dateFrom.setMinutes(0);
    dateFrom.setSeconds(0);
    component.set('v.dateTo', dateTo.toISOString());
    component.set('v.dateFrom', dateFrom.toISOString());
  }
})
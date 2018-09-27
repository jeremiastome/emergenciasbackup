({
  showHideModal : function(component) {
    
    var modal = component.find("detailModal");
    $A.util.toggleClass(modal, 'slds-fade-in-open');
    
    var overlay = component.find("overlay");
    $A.util.toggleClass(overlay, 'slds-backdrop--open');
    
    component.set("v.showModal", "false");

    // Esto se utiliza para poder renderizar el modal por encima del header global de lightning.
    // Si no se hace la parte superior del modal queda oculta y no permite cerrar el mismo.
    var modalCSS = component.get("v.modalCSS");
    component.set("v.modalCSS", (modalCSS) ? "" : ".forceStyle .viewport .oneHeader {z-index:0; } .slds-global-header_container {position: static;} .forceStyle.desktop .viewport{overflow:hidden}");
  },

  obtenerDetalles: function (component) {
    
    //this.toggleSpinner(component, true);

    var action = component.get('c.obtenerDetallesDocumento');

    action.setParams({
      nroDocumento: component.get('v.nroDocumentoRemoto')
    });

    action.setCallback(this, function(response) {
      
      if (response.getState() === 'SUCCESS') {

        var documento = response.getReturnValue();
        console.log(documento);
        component.set('v.documento', documento);

      } else {
        
        console.log(response.getState());
      }

      //this.toggleSpinner(component, false);
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
({
	helperFun : function(component,event,secId) {
	  var acc = component.find(secId);
        	for(var cmp in acc) {
        	$A.util.toggleClass(acc[cmp], 'slds-show');  
        	$A.util.toggleClass(acc[cmp], 'slds-hide');  
       }
	},
    
    hideFacturasNoPagas : function(component, event) {
        var facturas=component.get('v.facturas');
        for(var i=0; i<facturas.length;i++) {
            var factura = document.getElementById('li'+i);
            if(facturas[i].documento.pagado) {
        		$A.util.addClass(factura, 'slds-hide');
            } else {
                $A.util.removeClass(factura, 'slds-hide');
            }
        }
        
    },
    
    hideFacturasPagas : function(component, event) {
        var facturas=component.get('v.facturas');
        for(var i=0; i<facturas.length;i++) {
            var factura = document.getElementById('li'+i);
            if(!facturas[i].documento.pagado) {
        		$A.util.addClass(factura, 'slds-hide');
            } else {
                $A.util.removeClass(factura, 'slds-hide');
            }
        }
        
    },
    showFacturas : function(component, event) {
        var facturas=component.get('v.facturas');
        for(var i=0; i<facturas.length;i++) {
            var factura = document.getElementById('li'+i);
            
        	$A.util.removeClass(factura, 'slds-hide');
        }
        
    }

,
	 showOrHide: function (component, event) {
    	 var acordeonSection = event.target.parentNode.parentNode.parentNode.parentNode;
         $A.util.toggleClass(acordeonSection, 'slds-is-open');  
         

		}

})
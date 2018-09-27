({
    
    doInit : function(component, event, helper){
        var caseId = component.get("v.recordId");
        var actionOne = component.get("c.getWrapperList");
        actionOne.setParams({"idCase" : caseId});    
        actionOne.setCallback(this, function(result){
            var result = result.getReturnValue();
            component.set("v.beneficiariosWrapper", result);
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(actionOne);
    },
    
    checkAll: function(component, event, helper) {
        var master = component.find("master");
        var boxPack = component.find("dependent");
    
        var val = master.get("v.value");
    
        if (val == true) {
    
            for (var i = 0; i < boxPack.length; i++) {
				if(boxPack[i].getElement().type != null) {
					boxPack[i].set("v.value", true);
				}
            }
        } else {
            for (var i = 0; i < boxPack.length; i++) {
				if(boxPack[i].getElement().type != null) {
					boxPack[i].set("v.value", false);
				}
            }
        }
    },
    
    save: function (component, event, helper) {
        var btn = event.getSource();
		btn.set("v.disabled",true);
        component.set("v.showSpinner", true);
        var getList = component.get("v.beneficiariosWrapper");
        var recordId = component.get("v.recordId");
        var selectedItems = new Array();
        console.log(getList);
        // itero lista, me guardo los beneficiarios__c seleccionados
        for (var i = 0; i < getList.length; i++){
            if(getList[i].selected && !getList[i].created){
                selectedItems.push(getList[i].beneficiario);
            }
        }
        var actionOne = component.get("c.updateSelectedBeneficiarios");
        actionOne.setParams({"recipients" : selectedItems, "caseId" : recordId});  
        actionOne.setCallback(this, function(a) {
            console.log('State del callback es Success, entro a mostrar msj');
            var result = a.getReturnValue();
            var showToast = $A.get('e.force:showToast');
            if(result == 'Success'){
                showToast.setParams(
                    {
                        'title': '¡Correcto!',
                        'message': 'Se creó el pedido de embozado.',
                        'type' :'success',
                        'key' : 'check'
                    }
                );
                showToast.fire();
                $A.get("e.force:refreshView").fire();
            }else{
                showToast.setParams(
                    {
                        'title': 'Hubo un error al realizar el pedido de embozado.',
                        'message': 'Error: ' + result,
                        'type' :'error',
                        'key' : 'error'
                    }
                );
                showToast.fire();
            }
			btn.set("v.disabled",false);
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(actionOne);
    },
})
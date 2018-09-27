({
	doInit: function(component, event, helper) {
		helper.show(component);
        var action = component.get("c.getProducts");
        action.setParams({ titularId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
				var result = response.getReturnValue();
				component.set("v.products", result);
				var pageSize = component.get("v.pageSize");
				component.set("v.startPage",0);
                component.set("v.endPage",pageSize-1);
				component.set("v.totalRecords", component.get("v.products").length);
                var PaginationList = [];
                for(var i=0; i< pageSize; i++){
                    if(component.get("v.products").length> i) {
                        PaginationList.push(response.getReturnValue()[i]);
					}
                }
                component.set('v.PaginationList', PaginationList);
				helper.hide(component);
            }
            else {
				helper.hide(component);
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },

    checkAll:function(component,event,helper){
		var check = component.find("master");
		var isSelected = check.get("v.value");
		var items = component.find('item');
		console.log("Items: "+items.length);
		if(items.length > 0) {
			for (var i = 0; i < items.length; i++) {
				var check = items[i].find('checkbox');
				check.set("v.value", isSelected);
			}
		}
		else {
			var check = items.find('checkbox');
			check.set("v.value", isSelected);
		}
        helper.checkAll(component, isSelected);
    },

    click : function(component,event,helper){
        var actionName = event.getParam("actionName");
        var childComponent = component.find("uploadFile");
        childComponent.buttonClicked(actionName);
    },

    onFileUploaded:function(component,event,helper){
		var recordTypeName = component.find("selectRecordType").get("v.selectedValue");
		var files = event.getParam("file");
		var existFile = event.getParam("existFile");
		if(!existFile) {
			helper.showMessage(component, "No cargó ningún archivo.");
			return;
		}

        if (files && files[0].length > 0) {
            helper.show(component);
            var file = files[0][0];
            var reader = new FileReader();
            reader.onloadend = function() {
				var dataURL = reader.result;
                var content = dataURL.match(/,(.*)$/)[1];
                var stringBody = atob(content);
                var bodyLines = stringBody.split('\n');
                bodyLines = bodyLines.slice(1, bodyLines.length);
                bodyLines = bodyLines.slice(0 , -1);
                helper.upload(component, file, bodyLines, recordTypeName, 0, '');
            }
            reader.readAsDataURL(file);
        }
        else{
            helper.hide(component);
        }
    },

	next: function (component, event, helper) {
		helper.next(component, event);
	},
	previous: function (component, event, helper) {
		helper.previous(component, event);
	}
})
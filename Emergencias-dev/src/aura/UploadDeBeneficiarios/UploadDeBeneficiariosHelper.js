({
    upload: function(component, file, lines, recordTypeName, offset, documentId) {
        var productIds = this.getProductIds(component);
        if(productIds.length == 0) {
            this.showMessage(component, "Debe seleccionar al menos un producto.");
			return;
        }
        var action = component.get("c.uploadFile");
        var titularId = component.get("v.recordId");
        var size = 50;
        var take200 = lines;
        console.log(offset + size);
        if(lines.length > size) {
            take200 = lines.slice(0, size);
            console.log(take200[0]);
            lines = lines.slice(size, lines.length);
        }
        else {
            lines = [];
        }

        console.log(lines.length);

        action.setParams({
            fileName: file.name,
            bodyLines: take200,
            contentType: file.type,
            titularId: titularId,
            productIds: productIds,
            recordTypeName: recordTypeName,
            offset : offset,
            documentId: documentId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if(lines.length > 0) {
                    console.log(result.documentId);
                    this.upload(component, file, lines, recordTypeName, offset + size, result.documentId);
                }
                else {
                    $A.get("e.force:closeQuickAction").fire();
                    this.hide(component);
                    if(result.isSuccess) {
                        this.showToast('success', 'Success!', result.message);
                    }
                    else {
                        this.showToast('error', 'Error!', result.message);
                    }
                }
            }
            else {
                $A.get("e.force:closeQuickAction").fire();
                this.hide(component);
                this.showToast('error', 'Error!', 'Hubo un error al cargar los datos!');
            }
        });
        $A.enqueueAction(action);
    },

    getProductIds: function (component) {
        var productIds = [];
        var products = component.get("v.products");
        for(var i=0; i< products.length ; i++){
            var isSelected = products[i].isSelected;
            if(isSelected) {
                var productId = products[i].id;
                productIds.push(productId);
            }
        }
        return productIds;
    },

    show: function (cmp, event) {
        var spinner = cmp.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
    },

    hide:function (cmp, event) {
        var spinner = cmp.find("mySpinner");
        $A.util.removeClass(spinner, "slds-show");
        $A.util.addClass(spinner, "slds-hide");
    },

    showToast : function(type, title, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "title": title,
            "message": message,
            "mode" : "sticky"
        });
        toastEvent.fire();
    },

    checkAll : function(component, isSelected){
        var products = component.get("v.products");
        for (var i = 0; i < products.length; i++) {
            products[i].isSelected = isSelected;
        }
    },

    showMessage : function(component, message) {
        $A.createComponents([
            ["ui:message",{
                "title" : "Error",
                "severity" : "error",
                "closable" : "true"
            }],
            ["ui:outputText",{
                "value" : message
            }]
            ],
            function(components, status, errorMessage){
                if (status === "SUCCESS") {
                    var message = components[0];
                    var outputText = components[1];
                    message.set("v.body", outputText);
                    var divMessage = component.find("divMessage");
                    divMessage.set("v.body", message);
                }
            }
        );
    },

    next : function(component, event){
        var sObjectList = component.get("v.products");
        var end = component.get("v.endPage");
        var start = component.get("v.startPage");
        var pageSize = component.get("v.pageSize");
        var Paginationlist = [];
        var counter = 0;
        for(var i=end+1; i<end+pageSize+1; i++){
            if(sObjectList.length > i){
                Paginationlist.push(sObjectList[i]);
            }
            counter ++ ;
        }
        start = start + counter;
        end = end + counter;
        component.set("v.startPage",start);
        component.set("v.endPage",end);
        component.set('v.PaginationList', Paginationlist);
    },

    previous : function(component, event){
        var sObjectList = component.get("v.products");
        var end = component.get("v.endPage");
        var start = component.get("v.startPage");
        var pageSize = component.get("v.pageSize");
        var Paginationlist = [];
        var counter = 0;
        for(var i= start-pageSize; i < start ; i++){
            if(i > -1){
                Paginationlist.push(sObjectList[i]);
                counter ++;
            }else{
                start++;
            }
        }
        start = start - counter;
        end = end - counter;
        component.set("v.startPage",start);
        component.set("v.endPage",end);
        component.set('v.PaginationList', Paginationlist);
    }
})
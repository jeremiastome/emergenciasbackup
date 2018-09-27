({
    upload: function(component, file, lines, recordTypeName, offset, documentId) {
        console.log('Document id: ' +documentId);
        var action = component.get("c.uploadFile");
        var contractId = component.get("v.recordId");
        var size = 200;
        var take200 = lines;
        if(lines.length > size) {
            take200 = lines.slice(0, size);
            lines = lines.slice(size, lines.length);
        }
        else {
            lines = [];
        }
        action.setParams({
            fileName: file.name,
            bodyLines: take200,
            contentType: file.type,
            contractId: contractId,
            offset : offset,
            recordTypeName: recordTypeName,
            documentId: documentId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log('Document id res: ' +result.documentId);
                if(lines.length > 0) {
                    console.log(offset + size);
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

    show: function (cmp) {
        var spinner = cmp.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
    },

    hide:function (cmp) {
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
    }
})
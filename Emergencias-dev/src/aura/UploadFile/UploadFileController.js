({
    buttonClicked: function(component, event, helper) {
        var actionName = event.getParam('arguments').actionName;
        if(actionName == 'Aceptar') {
            var files = component.get("v.fileToBeUploaded");
            if (files && files[0].length > 0) {
                helper.upload(component, files, true);
            }
            else{
                helper.upload(component, files, false);
            }
        }
        else if(actionName == 'Cancelar') {
            $A.get("e.force:closeQuickAction").fire();
        }
    },

    handleUploadFinished:function(component,event,helper){
        var files = component.get("v.fileToBeUploaded");
        if(files[0].length > 0) {
            component.set("v.archivoCargado", files[0][0].name);
        }
    }
})
({
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

    click : function(component,event,helper) {
        var actionName = event.getParam("actionName");
        var childComponent = component.find("uploadFile");
        childComponent.buttonClicked(actionName);
    }
})
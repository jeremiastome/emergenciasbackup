({
    upload: function(component, files, existFile) {
        var uploadFileEvent = component.getEvent("fileUploaded");
        uploadFileEvent.setParams({
            "existFile": existFile,
            "file": files
         });
        uploadFileEvent.fire();
    }
})
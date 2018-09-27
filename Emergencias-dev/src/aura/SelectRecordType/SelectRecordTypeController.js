({
    doInit: function (component, event, helper) {
        var action = component.get("c.getRecordOptions");        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.selectedValue", result[0].value);
                component.set("v.options", response.getReturnValue());
            }
            else {
                console.log("Failed with state: " + state);
            }
        });        
        $A.enqueueAction(action);
    }
})
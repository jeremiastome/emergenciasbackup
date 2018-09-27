({
    click: function(component, event, helper) {         
        var buttonClickedEvent = component.getEvent("buttonClicked");
        var buttonLabel = component.get("v.buttonLabel");
        console.log('Button: '+buttonLabel);
        buttonClickedEvent.setParam("actionName", buttonLabel);
        buttonClickedEvent.fire();
    }
})
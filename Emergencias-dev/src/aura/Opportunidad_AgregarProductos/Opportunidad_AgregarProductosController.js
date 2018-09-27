({
	goToAddProducts: function (component, event, helper) {
		var urlEvent = $A.get("e.force:navigateToURL");
		urlEvent.setParams({
			"url":"/apex/AgregarProductos?id=" + component.get("v.recordId")
		});
		urlEvent.fire();
	}
})
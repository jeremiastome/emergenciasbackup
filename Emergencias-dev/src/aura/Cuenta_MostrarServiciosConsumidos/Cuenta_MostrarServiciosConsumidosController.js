({
	init: function (component, event, helper) {
		component.set("v.services", Array(50));//TODO get the services from the server.
		component.set("v.isLoading", false);
	}
})
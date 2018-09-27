({
	doInit : function(component, event, helper) {
        console.log('funciona?');
		var profUrl = $A.get("$Resource.PruebaIndex") + "/index.html";
        console.log(profUrl);
        component.set("v.staticResourceURL", profUrl);
	}
})
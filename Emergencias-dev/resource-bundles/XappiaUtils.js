window.XappiaUtils = (function() {
	return {
		//Component: standard lightning component.
		//Action: the name of the apex function to execute.
		//Callback: javascript function to return to, called with parameters:
		//	success: boolean, true if the no exception or connection error happened.
		//	return value: the return value of the apex function.
		//	errors: Vector of errors encountered when calling the function.
		//Params: optional, an object containing the parameters for the apex function.
        callApex: function(component, action, callback, params) {
            var recordId = component.get("v.recordId");
            var action = component.get("c." + action);
            
            if(params) {
                action.setParams(params);
            }
            action.setCallback(this, function(response) {
                callback(response.getState() === "SUCCESS", response.getReturnValue(), response.getError());
            });
            console.log(action);
            $A.enqueueAction(action);
        },
		
		showToast : function(title, message, otherParams) {
			var params = {};
			if(otherParams) {
				//Other params may include:
				// "type" = "error"|"warning"|"success"|"info"|"other" //this controls the color of the toast
				// "mode" = "sticky"|"dismissible"|"pester" //this indicates if the toast will stay until manually closed, or must be waited out
				// "duration" = number //time in milliseconds that the toast will remain visible (if not sticky)
				// for more info: https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/ref_force_showToast.htm
				params = otherParams;
			}
			params.title = title;
			params.message = message;
			var toastEvent = $A.get("e.force:showToast");
			toastEvent.setParams(params);
			toastEvent.fire();
		}
    };
})();

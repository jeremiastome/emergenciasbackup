({
	init: function (component, event, helper) {
		XappiaUtils.callApex(
			component,
			"getContracts",
			function(success, contracts, errors) {
				var contractIds = [];
				for (var i = 0; i < contracts.length; i++) {
					contractIds.push(contracts[i].Id);
				}
				if(success) {
					XappiaUtils.callApex(
						component,
						"getHoldersAndRecipients",
						function(success2, holders, errors2) {
							if(success2) {
								//holders = JSON.parse(holdersJson);
								for (var i = 0; i < contracts.length; i++) {
									contracts[i].holders = holders[contracts[i].Id];
								}
								component.set("v.contracts", contracts);
							}
							else {
								XappiaUtils.showToast(
									"Error",
									$A.get("$Label.c.Error_obteniendo_detalles_de_contratos_asociados"),
									{type:"error"}
								);
								console.log(errors2);
							}
							component.set("v.isLoading", false);
						},
						{contractIds: contractIds}
					);
				}
				else {
					XappiaUtils.showToast(
						"Error",
						$A.get("$Label.c.Error_obteniendo_detalles_de_contratos_asociados"),
						{type:"error"}
					);
					console.log(errors);
					component.set("v.isLoading", false);
				}
			},
			{accId: component.get("v.recordId")}
		);
		// component.set("v.contracts", [{
		// 	Id:'qwe123',
		// 	Numero_Unico_de_Contrato__c:'123-zxc'
		// }]);
		// console.log(component);
	},
	
	goToRecord: function(component, event, helper) {
		var navEvt = $A.get("e.force:navigateToSObject");
		navEvt.setParams({
			"recordId": event.target.record,
			"slideDevName": "related"
		});
		navEvt.fire();
	},
	
	toggleHolderDetails: function(component, event, helper) {
		var contracts = component.get("v.contracts");
		var c = event.target.contract;
		var h = event.target.holder;
		var target = event.target;
		
		//If the user clicks the svg element
		while(target && !(target.contract || target.contract === 0)) {
			target = target.parentElement;
		}
		if(target) {
			c = target.contract;
			h = target.holder;
			contracts[c].holders[h].showDetails = !contracts[c].holders[h].showDetails;
			
			component.set("v.contracts", contracts);
		}
		else {
			
		}
	}
})
({

	getContacts: function (component, contract){
		XappiaUtils.callApex(
			component,
			"getContacts",
			function(success, contacts, errors) {
				if(success) {
					console.log('Contatos: ');
					console.log(contacts);
					var selOpts = [];
					for (var i = 0; i < contacts.length; i++) {
						var opt = {
							value: contacts[i].ContactId,
							label: contacts[i].Contact.Name
							};
						selOpts[i] = opt;
					}
					selOpts.unshift({
						value: "",
						label: "--Ninguno--"
					});
					component.set("v.contacts", selOpts);
				}else {
					XappiaUtils.showToast("Error", $A.get("$Label.c.Error_obteniendo_contactos"), {"type":"error"});
					console.log(errors);
				}
				component.set("v.isLoading", false);
			},
			{accId: contract.Cliente__c}
		);        
	}
})
trigger Contact on Contact (before insert, after insert, before update, after update) {	
	if(Trigger.isBefore) {
		string fatherId;
		for(Contact c : Trigger.new) {
			c.Saltear_envio__c--;
			if (Trigger.isInsert)
			{							
				if (String.isBlank(c.accountId))
				{
					if (String.isBlank(fatherId))
						fatherId = Parametros_Operativos__c.getValues('Contact_Father').valor__c;
					c.accountId = fatherId;
				}
			}
            if(c.Provincia__c!=null) {
                c.MailingState = c.Provincia__c;
            }
		}		
	}
	else {//isAfter
		String operationType;
		if(Trigger.isInsert) {
			operationType = 'A';
		}
		else if(Trigger.isUpdate) {
			operationType = 'M';
		}
		Usuario_no_envia_a_SAP__c usr = Usuario_no_envia_a_SAP__c.getValues(UserInfo.getUserName());
		List<Contact> contactsToUpdate = new List<Contact>();
		for(Contact c : Trigger.new) {
			if(Trigger.isInsert && c.Codigo_SAP_contacto__c == null) {
				//HACK the autonumeric field is not loaded in the before insert trigger.
				Contact con = new Contact();
				con.Id = c.Id;

				con.Codigo_SAP_contacto__c = '' + c.Numero_unico_de_contacto__c;
				con.Saltear_envio__c = 2;
				contactsToUpdate.add(con);
			}
            
			if(c.Saltear_envio__c <= 0  && (usr == null || !usr.No_envia__c)) {
				ContactTriggerHelper.sendContactToSAP(c, operationType);
			}
		}
		if(contactsToUpdate.size() > 0) {
			update contactsToUpdate;
		}
	}
}
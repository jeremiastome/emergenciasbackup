trigger CBU on CBU__c (before insert, before update)  {
	for(CBU__c c : Trigger.new) {
		if(!Validate.cbu(c.Name)) {
			c.Name.addError(Label.CBU_invalido);
		}
	}
}
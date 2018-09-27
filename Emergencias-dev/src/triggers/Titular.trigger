trigger Titular on Titular__c (before insert) {
	List<Titular__c> titularsToPrepareNumber = new List<Titular__c>();
	for(Titular__c t : Trigger.new) {
		titularsToPrepareNumber.add(t);
	}
	
	if(titularsToPrepareNumber.size() != 0) {
		TitularTriggerHelper.prepareUniqueNumber(titularsToPrepareNumber);
	}
}
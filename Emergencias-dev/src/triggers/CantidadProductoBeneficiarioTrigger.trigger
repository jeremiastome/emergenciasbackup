trigger CantidadProductoBeneficiarioTrigger on Cantidad_de_producto_de_beneficiaro__c (after insert, after update) {
	List<Cantidad_de_producto_de_beneficiaro__c> changedAmounts =
		new List<Cantidad_de_producto_de_beneficiaro__c>();
	List<Cantidad_de_producto_de_beneficiaro__c> activatedAmounts =
		new List<Cantidad_de_producto_de_beneficiaro__c>();
	for(Cantidad_de_producto_de_beneficiaro__c c : Trigger.new) {
		if(c.Activo__c) {
			changedAmounts.add(c);
			if(Trigger.isInsert || !Trigger.oldMap.get(c.Id).Activo__c) {
				activatedAmounts.add(c);
			}
		}
	}
	
	if(changedAmounts.size() > 0) {
		CantidadProductoBeneficiarioTrigHelper.updateCoverageRecipientRelations(changedAmounts);
	}
	if(activatedAmounts.size() > 0) {
		CantidadProductoBeneficiarioTrigHelper.deactivateOldAmountDetails(activatedAmounts);
	}
}
trigger Tarjeta on Tarjeta__c (before insert, before update) {
	for(Tarjeta__c t : Trigger.new) {
		if(Trigger.isInsert || t.Numero_de_tarjeta__c != Trigger.oldMap.get(t.Id).Numero_de_tarjeta__c) {
			if(!Validate.cardNumber(t.Numero_de_tarjeta__c)) {
				t.Numero_de_tarjeta__c.addError(Label.Tarjeta_invalida);
			}
		}
	}
}
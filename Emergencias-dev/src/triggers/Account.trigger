trigger Account on Account (before insert, after insert, before update, after update, after delete) {
	if(Trigger.isAfter) {

		Map<String, Set<Id>> accountsToSendByOperation = new Map<String, Set<Id>>();
		if(Trigger.isDelete) {
			Set<Id> accountsToSend = new Set<Id>();

			for(Account acc : Trigger.old) {
				if(acc.Dado_de_alta__c) {
					accountsToSend.add(acc.Id);
				}
			}

			accountsToSendByOperation.put('B', accountsToSend);
		}
		else {
			for(Account acc : Trigger.new) {
				if(acc.Saltear_envio__c <= 0 && acc.Es_cliente__c ) {//Skip sending if in a batch process
					if(acc.Dado_de_alta__c) {
						if(Trigger.isInsert || !Trigger.oldMap.get(acc.Id).Dado_de_alta__c) {
							if(!accountsToSendByOperation.containsKey('A')) {
								accountsToSendByOperation.put('A', new Set<Id>());
							}
							accountsToSendByOperation.get('A').add(acc.Id);
						}
						else {
							if(!accountsToSendByOperation.containsKey('M')) {
								accountsToSendByOperation.put('M', new Set<Id>());
							}
							accountsToSendByOperation.get('M').add(acc.Id);
						}
					}
					else {
						if(!Trigger.isInsert && Trigger.oldMap.get(acc.Id).Dado_de_alta__c) {
							if(!accountsToSendByOperation.containsKey('B')) {
								accountsToSendByOperation.put('B', new Set<Id>());
							}
							accountsToSendByOperation.get('B').add(acc.Id);
						}
					}
				}
			}
		if(Trigger.isUpdate){
			List<Account> accountUpdate = new List<Account>();
			for(Account acc : Trigger.new){
				if(acc.Contratos_vigentes__c == 0 && Trigger.oldMap.get(acc.Id).Contratos_vigentes__c > 0){
					List<Contrato__c> listcon = [SELECT id, Estado__c, Motivo_de_baja__c, Detalle_de_motivo_de_baja__c, Fecha_baja__c, LastModifiedDate
												FROM Contrato__c ORDER BY LastModifiedDate DESC LIMIT 1];
					if(listcon.size() > 0){
						Contrato__c con = listcon[0];
						Account newAcc = new Account();
						newAcc.Id = acc.Id;
                        newAcc.Dado_de_alta__c=false;
                        newAcc.Estado__c='Baja';
						newAcc.Motivo_de_baja__c = con.Motivo_de_Baja__c;
						newAcc.Detalle_motivo_de_baja__c = con.Detalle_de_Motivo_de_Baja__c;
						newAcc.Fecha_de_baja__c = con.Fecha_baja__c;
						accountUpdate.add(newAcc);
					}
				}
			}
			update accountUpdate;
		}
		}
		Usuario_no_envia_a_SAP__c usr = Usuario_no_envia_a_SAP__c.getValues(UserInfo.getUserName());
		if(usr == null || !usr.No_envia__c) {
			for(String op : accountsToSendByOperation.keySet()) {
				AccountTriggerHelper.sendAccountsToSAP(accountsToSendByOperation.get(op), op);
			}
		}
	}
	else {//isBefore
		for(Account acc : Trigger.new) {
		string t = 'tr';
			if(!String.isBlank(acc.CUIL_CUIT__c) && String.isBlank(acc.N_mero_nico_de_Cliente__c)) {
				acc.N_mero_nico_de_Cliente__c = acc.CUIL_CUIT__c.left(acc.CUIL_CUIT__c.length() - 1);
			}

			if(acc.IsPersonAccount && (
					Trigger.isInsert ||
					acc.N_mero_nico_de_Cliente__c != Trigger.oldMap.get(acc.Id).N_mero_nico_de_Cliente__c
				)
			) {
				acc.Codigo_SAP_contacto__pc = acc.N_mero_nico_de_Cliente__c;
			}

			acc.Saltear_envio__c--;
		}
	}
}
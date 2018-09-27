trigger Contrato on Contrato__c(before insert, before update, after update, after insert) {
	if (Trigger.isBefore) {
		Usuario_no_envia_a_SAP__c usr = Usuario_no_envia_a_SAP__c.getValues(UserInfo.getUserName());
		List<Contrato__c> contractsToCheckCard = new List<Contrato__c> ();
		List<Contrato__c> validContracts = new List<Contrato__c> ();
		List<Contrato__c> contractsToMoveCBU = new List<Contrato__c>();
        
		for (Contrato__c con : Trigger.new) {
			if (con.Numero_de_Tarjeta__c != null) {
				if (Trigger.isInsert || con.Numero_de_Tarjeta__c != Trigger.oldMap.get(con.Id).Numero_de_Tarjeta__c) {
					contractsToCheckCard.add(con);
				}
			}
			else {
				con.Tarjeta_sin_cifrar__c = null;
			}
			if (con.CBU_cifrado__c != null) {
                if (Trigger.isInsert || con.CBU_cifrado__c != Trigger.oldMap.get(con.Id).CBU_cifrado__c){
                    if (!Validate.cbu(con.CBU_cifrado__c)) {
                        con.CBU_cifrado__C.addError(Label.CBU_invalido);
                    }
                    else {
                        validContracts.add(con);
                        contractsToMoveCBU.add(con);            
                    }
                }
            }                         
            
			if (con.Numero_de_Tarjeta__c == null && con.CBU__c == null) {
				validContracts.add(con);
			}
			
			//SAP sending
			con.Saltear_envio__c--;
			
			if(con.Saltear_envio__c <= 0
				&& con.Forma_de_Facturaci_n__c != 'No Factura'
				&& (usr == null || !usr.No_envia__c)
			) {
				con.Esperando_envio__c = true;
			}
		}
		
		if (contractsToCheckCard.size() != 0) {
			List<Contrato__c> contractsWithValidCards = ContratoTriggerHelper.checkCardNumbers(contractsToCheckCard);
			if (contractsWithValidCards.size() != 0) {
				validContracts.addAll(contractsWithValidCards);
				ContratoTriggerHelper.moveCardNumbers(contractsWithValidCards);
			}
		}
        if (contractsToMoveCBU.size() != 0){
            ContratoTriggerHelper.moveCBUNumbers(contractsToMoveCBU);
        }
		if (validContracts.size() != 0) {
			List<Contrato__c> contractsToCheckNumbers = new List<Contrato__c> ();
			if (Trigger.isInsert) {
				contractsToCheckNumbers = validContracts;
			}
			else {
				for (Contrato__c c : validContracts) {
					if (c.Numero_unico_de_contrato__c != Trigger.oldMap.get(c.Id).Numero_unico_de_contrato__c) {
						contractsToCheckNumbers.add(c);
					}
				}
			}
			ContratoTriggerHelper.checkContractNumbers(contractsToCheckNumbers);
		}
	}
	else {
		if (Trigger.isUpdate) {
			Usuario_no_envia_a_SAP__c usr = Usuario_no_envia_a_SAP__c.getValues(UserInfo.getUserName());
			for (Contrato__c con : Trigger.new) {
				System.debug('Contrato: ' + con);
				if (con.Saltear_envio__c <= 0 && (usr == null || !usr.No_envia__c)) {
					Contrato__c oldContrato = Trigger.oldMap.get(con.Id);
					
					if (con.Forma_de_Facturaci_n__c != 'No Factura') {
						if (con.Estado__c == 'Activo' && oldContrato.Estado__c != 'Activo') {
							System.debug('El estado del contrato paso a ser activo');
							
							if (oldContrato.Morosidad_SAP__c != con.Morosidad_SAP__c & con.Morosidad_SAP__c == null) {
								ContratoTriggerHelper.sendContractToSAP(con.Id, 'M');
								System.debug('El contrato se envio como Modificacion');
							} else {
								ContratoTriggerHelper.sendContractToSAP(con.Id, 'A');
								System.debug('El contrato se envio como Alta');
							}
						}
						else if (con.Estado__c == 'Activo') {
							System.debug('El estado del contrato ya era activo');
							ContratoTriggerHelper.sendContractToSAP(con.Id, 'M');
							System.debug('El contrato se envio como Modificacion');
						}
						else if (con.Estado__c == 'Baja' && oldContrato.Estado__c != 'Baja') {
							System.debug('El estado del contrato paso a baja');
							ContratoTriggerHelper.sendContractToSAP(con.Id, 'B');
							System.debug('El contrato se envio como Modificacion');
						}
						//// Aca estaba el condicional de getContratZoneData
						//// Se elimino la parte del condiconal "  con.Estado__c != 'Activo' && "
					}
					
					if (!Test.isRunningTest() &&
						con.Tipo_de_Cobrador__c != null && (
							con.Tipo_de_Cobrador__c != oldContrato.Tipo_de_Cobrador__c
							|| con.Forma_de_Pago__c != oldContrato.Forma_de_Pago__c
						)
					) {
						ContratoTriggerHelper.getContractZoneData(con.Id);
						System.debug('Se busco la zona del contrato');
					}
				}	
			}
		}
	}
}
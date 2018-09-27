trigger Opportunity on Opportunity(before insert, before update) {
	if (Trigger.isInsert) {
		List<Opportunity> oppsCreatedByLead = new List<Opportunity>();
		List<Opportunity> oppsToCreateContract = new List<Opportunity> ();
		for (Opportunity o : Trigger.new) {
			if (o.Tipo_de_oportunidad_por_prospecto__c != null) {
				oppsCreatedByLead.add(o);
			}
			if (o.Tipo_de_Alta__c == 'Nueva') {
				oppsToCreateContract.add(o);
			}
		}
		// if (oppsToCreateContract.size() != 0) {
		// 	OpportunityTriggerHelper.putRecordTypeToOpportunity(oppsCreatedByLead);
		// }

		if (oppsToCreateContract.size() != 0) {
			system.debug('Crear contratos a :' +oppsToCreateContract);
			OpportunityTriggerHelper.createContracts(oppsToCreateContract);
		}
	}
	else { //Trigger.isUpdate
		Map<Id, Opportunity> rejectedOpps = new Map<Id, Opportunity> ();
		Map<Id, Opportunity> oppsForApprovalAndWithoutJustification = new Map<Id,Opportunity>();
		for (Opportunity o : Trigger.new) {
			if (o.Rechazada__c) {
				rejectedOpps.put(o.Id, o);
				o.Rechazada__c = false;
			}
			if(o.StageName == 'Pendiente de Aprobación'
				&& Trigger.oldMap.get(o.Id).StageName != 'Pendiente de Aprobación'
				&& String.isBlank(o.Justificacion_de_descuentos_a_medida__c)
			) {
				oppsForApprovalAndWithoutJustification.put(o.Id, o);				
			}
		}
		if (rejectedOpps.size() != 0) {
			OpportunityTriggerHelper.checkCommentOnRejection(rejectedOpps);
		}
		if(oppsForApprovalAndWithoutJustification.size() > 0) {
			OpportunityTriggerHelper.checkSpecialDiscountJustification(
				oppsForApprovalAndWithoutJustification
			);
		}

		List<Opportunity> wonOpps = new List<Opportunity> ();
		List<id> wonOppIds = new List<id>(); 

		for(Opportunity opp: Trigger.new){
			Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
			if(opp.IsWon && !oldOpp.IsWon){
				wonOpps.add(opp);
				wonOppIds.add(opp.id);
		   	}
		}

		if(wonOppIds.size()>0) {
			OpportunityTriggerHelper.activeRecipients(wonOppIds);
			OpportunityTriggerHelper.createEmbozado(wonOpps);
			
			// Cuando gano la oportunidad envio el cliente y la oportunidad EN EL ORDEN CORRECTO!!!
			Usuario_no_envia_a_SAP__c usr = Usuario_no_envia_a_SAP__c.getValues(UserInfo.getUserName());
			if(usr == null || !usr.No_envia__c) {
				OpportunityTriggerHelper.sendClientAndContract(wonOpps);
			}
		}
	}
}
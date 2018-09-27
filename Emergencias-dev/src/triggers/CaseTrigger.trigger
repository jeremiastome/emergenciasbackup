trigger CaseTrigger on Case (before insert, before update, after update, after insert) {
	if(Trigger.isBefore) {
		List<Case> casesToCheckCard = new List<Case>();
		List<Case> validCases = new List<Case>();
		for(Case caso : Trigger.new) {
			if(caso.Numero_de_Tarjeta__c != null) {
				if(Trigger.isInsert ||
					caso.Numero_de_Tarjeta__c != Trigger.oldMap.get(caso.Id).Numero_de_Tarjeta__c
				) {
					casesToCheckCard.add(caso);
				}
			}
			if(caso.CBU__c != null) {
				if(!Validate.cbu(caso.CBU__c)) {
					caso.CBU__c.addError(Label.CBU_invalido);
				}
				else {
					validCases.add(caso);
				}
			}
			if(caso.Numero_de_Tarjeta__c == null && caso.CBU__c == null) {
				validCases.add(caso);
			}
			if (caso.Reason == 'Bonificaciones'
				&& caso.Motivo_de_Finalizacion__c == 'Procesado'
				&& caso.Status == 'Cerrado'
			) {
				if(Trigger.isInsert) {
					caso.addError(Label.La_bonificacion_no_tiene_descuentos);
				}
				List<Descuento_recargo_aplicado__c> discounts = [
					SELECT Id
					FROM Descuento_recargo_aplicado__c
					WHERE Caso__c = :caso.id
				];
				if(discounts.size() == 0 && trigger.OldMap.get(caso.id).Status != caso.Status) {
					caso.addError(Label.La_bonificacion_no_tiene_descuentos);
				}
			}
		}
		
		if(casesToCheckCard.size() != 0) {
			List<Case> casesWithValidCards = CaseTriggerHelper.checkCardNumbers(casesToCheckCard);
			if(casesWithValidCards.size() != 0) {
				validCases.addAll(casesWithValidCards);
			}
		}
		
		if(Trigger.isInsert) {
			Map<String, Grupos_para_casos__c> settings = Grupos_para_casos__c.getAll();
			Set<Id> typesThatCloneContract = CaseTriggerHelper.getCloneContractSettings().keySet();
			List<Case> casesToCloneContract = new List<Case>();
			List<Case> casesToSetMaster = new List<Case>();
			Map<String, List<Case>> casesByReason = new Map<String, List<Case>>();
			List<Case> casesToSetAccount = new List<Case>();
			for(Case c : Trigger.new) {
				if(settings.containsKey(c.Reason)) {
					if(!casesByReason.containsKey(c.Reason)) {
						casesByReason.put(c.Reason, new List<Case>());
					}
					casesByReason.get(c.Reason).add(c);
				}
				if(c.ParentId != null) {
					casesToSetMaster.add(c);
				}
				if (typesThatCloneContract.contains(c.RecordTypeId)) {
					casesToCloneContract.add(c);
				}
				if(c.AccountId == null && c.Contrato__c != null){
					casesToSetAccount.add(c);
				}
			}
			//================================
			if(casesByReason.size() > 0) {
				List<Grupos_para_casos__c> usedSettings = new List<Grupos_para_casos__c>();
				for(String reason : casesByReason.keySet()) {
					usedSettings.add(settings.get(reason));
				}
				CaseTriggerHelper.assignCasesToUsers(casesByReason, usedSettings);
			}
			
			if(casesToSetMaster.size() > 0) {
				CaseTriggerHelper.setMasterCase(casesToSetMaster);
			}
			
			if(casesToCloneContract.size() > 0) {
				RecordType coverageChangeRecordtype = [
					SELECT Id
					FROM RecordType
					WHERE DeveloperName = 'Cambio_de_cobertura'
				];
				Map<Id, Case> contractsByCase = new Map<Id, Case>();
				List<Id> MainCases = new List<Id>();
				for (Case c : casesToCloneContract) {
					contractsByCase.put(c.Contrato__c, c);
					MainCases.add(c.Caso_maestro__c);
				}
				System.debug(contractsByCase);
				List<Contrato__c> contractsToBeCloned = [
					SELECT Id, (
							SELECT Id
							FROM Oportunidades__r
							WHERE IsClosed=false
						), (
							SELECT Id FROM Cases__r
						 	WHERE IsClosed=false
							 	AND Id NOT IN :contractsByCase.values()
								AND Id NOT IN :MainCases
								AND RecordType.DeveloperName!='Cambio_de_cobertura'
						)
					FROM Contrato__c
					WHERE Id IN :contractsByCase.keySet()
				];
				
				Boolean errors = false;
				for (Contrato__c con : contractsToBeCloned) {
					if (con.Oportunidades__r.size() != 0 || con.Cases__r.size() != 0) {
						if (contractsByCase.get(con.id).Recordtypeid == coverageChangeRecordtype.id) {
							contractsByCase.get(con.id).addError(
								Label.Cambio_de_cobertura_con_otros_casos_abiertos
							);
							errors = true;
						}
					}
				}
				
				if (!errors) {
					CaseTriggerHelper.cloneContracts(casesToCloneContract);
				}
			}
			
			if(casesToSetAccount.size() > 0) {
				CaseTriggerHelper.assignAccountToCase(casesToSetAccount);
			}
		}//=========================================================================
		else {//Update
			Map<Id, RecordType> recordTypesNotToActivate = new Map<Id, RecordType>([
				SELECT Id
				FROM RecordType
				WHERE DeveloperName = 'Cambio_de_cobertura'
					OR DeveloperName = 'Cambio_de_Cliente'
			]);
			
			Map<Id, Caso_generador__c> typesThatCloneContract =
				CaseTriggerHelper.getCloneContractSettings();
			Map<Id, Casos_Beneficiarios_Descuentos__c> typesThatModifyContract =
				CaseTriggerHelper.getContractModificationSettings();
			List<Case> casesToDeleteContract = new List<Case>();
			List<Case> casesToActivateContract = new List<Case>();
			List<Case> casesToEraseModifications = new List<Case>();
			List<Case> casesToActivateModifications = new List<Case>();
			for(Case c : Trigger.new) {
				if(c.Status == 'Cerrado' && Trigger.oldMap.get(c.Id).Status != 'Cerrado') {
					if(typesThatCloneContract.containsKey(c.RecordTypeId)) {
						if(c.Motivo_de_Finalizacion__c ==
							typesThatCloneContract.get(c.RecordTypeId).Motivo_cierre_incorrecto__c
						) {
							casesToDeleteContract.add(c);
						}
						else if(!recordTypesNotToActivate.containsKey(c.RecordTypeId)
							&& c.Motivo_de_Finalizacion__c ==
								typesThatCloneContract.get(c.RecordTypeId).Motivo_cierre_correcto__c
						) {
							casesToActivateContract.add(c);
						}
					}
					else if(typesThatModifyContract.containsKey(c.RecordTypeId)) {
						if(c.Motivo_de_Finalizacion__c ==
							typesThatModifyContract.get(c.RecordTypeId).Motivo_cierre_incorrecto__c
						) {
							System.debug('No se modifica');
							casesToEraseModifications.add(c);
						}
						else if(c.Motivo_de_Finalizacion__c ==
							typesThatModifyContract.get(c.RecordTypeId).Motivo_cierre_correcto__c
						) {
							System.debug('Se modifica');
							casesToActivateModifications.add(c);
						}
					}
				}
			}
			
			if(casesToDeleteContract.size() > 0) {
				CaseTriggerHelper.deleteCloneContracts(casesToDeleteContract);
			}
			if(casesToActivateContract.size() > 0) {
				CaseTriggerHelper.activateCloneContracts(casesToActivateContract);
			}
			if(casesToEraseModifications.size() > 0) {
				CaseTriggerHelper.eraseCaseModifications(casesToEraseModifications);
			}
			if(casesToActivateModifications.size() > 0) {
				System.debug('Se activo el triggerHelper de modificacion');
				CaseTriggerHelper.activateCaseModifications(casesToActivateModifications);
			}
		}
	}
	else {
		//==============================================================================
		//Is After
		RecordType creditNoteCase = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Nota_de_Credito'
		];
		List<id> creditNoteCasesId = new List<id>();
		for(Case c : Trigger.new) {
			if(c.RecordTypeId == creditNoteCase.Id
				&& c.Motivo_de_Finalizacion__c == 'Procesado'
				&& c.Status == 'Cerrado'
				&& !c.Enviado_a_SAP__c
			) {
				CaseTriggerHelper.sendCreditNote(c);
			}
		}
	}
}
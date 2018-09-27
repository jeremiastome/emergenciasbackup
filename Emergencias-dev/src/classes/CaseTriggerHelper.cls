public class CaseTriggerHelper {

	public static Map<Id, Caso_generador__c> getCloneContractSettings() {
		Map<String, Caso_generador__c> settings = Caso_generador__c.getAll();
		Set<String> devNames = settings.keySet();

		Map<Id, Caso_generador__c> result = new Map<Id, Caso_generador__c>();
		for(RecordType rt : [
			SELECT Id, DeveloperName
			FROM RecordType
			WHERE DeveloperName IN :devNames
		]) {
			result.put(rt.Id, settings.get(rt.DeveloperName));
		}
		return result;
	}

	public static Map<Id, Casos_Beneficiarios_Descuentos__c> getContractModificationSettings() {
		Map<String, Casos_Beneficiarios_Descuentos__c> settings = Casos_Beneficiarios_Descuentos__c.getAll();
		Set<String> devNames = settings.keySet();

		Map<Id, Casos_Beneficiarios_Descuentos__c> result = new Map<Id, Casos_Beneficiarios_Descuentos__c>();
		for(RecordType rt : [
			SELECT Id, DeveloperName
			FROM RecordType
			WHERE DeveloperName IN :devNames
		]) {
			result.put(rt.Id, settings.get(rt.DeveloperName));
		}
		return result;
	}

	public static void setMasterCase(List<Case> cases) {
		Set<Id> parentIds = new Set<Id>();
		for(Case c : cases) {
			parentIds.add(c.ParentId);
		}

		Map<Id, Case> parentsById = new Map<Id, Case>([
			SELECT Id, Caso_maestro__c
			FROM Case
			WHERE Id IN :parentIds
		]);

		for(Case c : cases) {
			Case parent = parentsById.get(c.ParentId);
			if(parent.Caso_maestro__c != null) {
				c.Caso_maestro__c = parent.Caso_maestro__c;
			}
			else {
				c.Caso_maestro__c = parent.Id;
			}
		}
	}

	public static void cloneContracts(List<Case> cases) {
		Map<Id, Case> masterCases = getMasterCases(cases);
		Set<Id> contractIds = new Set<Id>();
		Set<Id> repeatedContracts = new Set<Id>();
		Map<Id, Case> caseByContract = new Map<Id, Case>();
        System.debug(JSON.serialize(cases));
		for(Case c : cases) {
            System.debug(c);
			Case master = masterCases.get(c.Caso_maestro__c);
			Id contractId = null;
			//Get the contract to clone Id
			if(master != null) {
				if(master.Contrato_clonado__c == null) {
					contractId = master.Contrato__c;

					c.Contrato__c = master.Contrato__c;
				}
				else {
					c.Contrato_clonado__c = master.Contrato_clonado__c;
				}
			}
			else {
				contractId = c.Contrato__c;
			}
			if(contractId != null) {
				//Check the contract isn't repeated
				System.debug(contractId);
                System.debug(JSON.serialize(contractIds));
				if(contractIds.contains(contractId)) {
					repeatedContracts.add(contractId);
					c.addError(Label.Error_multiples_casos_para_mismo_contrato);
				}
				else {
					contractIds.add(contractId);
					caseByContract.put(contractId, c);
				}
			}
		}
		//Remove cases with repeated contracts
		contractIds.removeAll(repeatedContracts);
		for(Id conId : repeatedContracts) {
			caseByContract.remove(conId);
		}

		List<Case> casesToCloneContract = filterForContractsAlreadyCloned(
			contractIds,//XXX by ref!
			masterCases.keySet(),
			caseByContract.values()
		);

		Map<Id, Contrato__c> contractsByOldId = ClonarContrato.clonar(contractIds, true);

		for(Case c : casesToCloneContract) {
			Case master = masterCases.get(c.Caso_maestro__c);
			if(master != null) {
				Contrato__c contract = contractsByOldId.get(master.Contrato__c);
				c.Contrato_clonado__c = contract.Id;
				master.Contrato_clonado__c = contract.Id;
			}
			else {
				Contrato__c contract = contractsByOldId.get(c.Contrato__c);
				c.Contrato_clonado__c = contract.Id;
			}
		}

		if(masterCases.size() > 0 && casesToCloneContract.size() > 0) {
			update masterCases.values();
		}
	}

	public static void assignCasesToUsers(Map<String, List<Case>> casesByReason, List<Grupos_para_casos__c> groupCaseSettings) {
		for(Grupos_para_casos__c settings : groupCaseSettings) {
			//HACK
			//	the amount of lists should never reach a point
			//	where the query in the loop becomes too much,
			//	while the amount of work to keep it out of the
			//	loop can't be done at the moment.
			assignCasesOfReason(casesByReason.get(settings.Name), settings);
		}
	}

	public static void deleteCloneContracts(List<Case> cases) {
		Set<Id> contractIds = new Set<Id>();
		for(Case c : cases) {
			contractIds.add(c.Contrato_clonado__c);
		}

		delete [SELECT Id FROM Contrato__c WHERE Id IN :contractIds];
	}

	public static void activateCloneContracts(List<Case> cases) {
		Set<Id> originalsIds = new Set<Id>();
		Set<Id> clonesIds = new Set<Id>();
		for(Case c : cases) {
			clonesIds.add(c.Contrato_clonado__c);
			originalsIds.add(c.Contrato__c);
		}
		Set<Id> contractIds = new Set<Id>();
		contractIds.addAll(clonesIds);
		contractIds.addAll(originalsIds);

		List<Contrato__c> contracts = [
			SELECT Id, Estado__c
			FROM Contrato__c
			WHERE Id IN :contractIds
		];

		for(Contrato__c con : contracts) {
			if(clonesIds.contains(con.Id)) {
				con.Estado__c = 'Activo';
			}
			else {//if(originalsIds.contains(con.Id))
				con.Estado__c = 'Baja';
			}
		}

		update contracts;
	}

	public static void sendCreditNote(Case aCase) {
		CaseCreditNoteSenderQueable csq = new CaseCreditNoteSenderQueable(aCase.Id);
		System.enqueueJob(csq);
	}

	public static void assignAccountToCase(List<Case> cases) {
        Set<Id> contractIds = new Set<Id>();
        for(Case c : cases){
            contractIds.add(c.Contrato__c);
        }
        List<Contrato__c> contracts = [SELECT Id, Cliente__c FROM Contrato__c WHERE Id = :contractIds];
        for(Case caso : cases){
            for(Contrato__c contrato : contracts){
                if(caso.Contrato__c == contrato.Id){
                    caso.AccountId = contrato.Cliente__c;
                    break;
                }
            }
        }
	}

	public static void eraseCaseModifications(List<Case> cases) {
		List<Contrato__c> contracts = new List<Contrato__c>();
		Set<Id> caseIds = new Set<Id>();
		for(Case c : cases) {
			caseIds.add(c.Id);
			if(c.Contrato__c!=null) {
				contracts.add(new Contrato__c(
								Id=c.Contrato__c,
								Saltear_envio__c=-2
								));
			}
		}

		eraseCaseModificationsDiscounts(caseIds);
		eraseCaseModificationsRecipientCoverageRelation(caseIds);
		eraseCaseModificationsRecipients(caseIds);

		update contracts;
	}

	public static void activateCaseModifications(List<Case> cases) {
		List<Contrato__c> contracts = new List<Contrato__c>();
		Set<Id> caseIds = new Set<Id>();
		for(Case c : cases) {
			caseIds.add(c.Id);

			if(c.Contrato__c!=null) {
				contracts.add(new Contrato__c(
								Id=c.Contrato__c,
								Saltear_envio__c=-2,
								Estado__c='Activo',
                    			Bloqueo_Factura__c = null
								));
			}
		}
        System.debug(cases);

		activateCaseModificationsDiscounts(caseIds);
		activateCaseModificationsRecipientCoverageRelation(caseIds);
		activateCaseModificationsRecipients(caseIds);

		update contracts;
	}

	private static List<Case> filterForContractsAlreadyCloned(Set<Id> contractIds, Set<Id> masterCaseIds, List<Case> cases) {
		Map<Id, Id> caseIdByContract = new Map<Id, Id>();
		for(Case c : [
			SELECT Id, Contrato__c
			FROM Case
			WHERE Contrato__c IN :contractIds
				AND Contrato_clonado__c != null
				AND Id NOT IN :masterCaseIds
				AND Caso_maestro__c NOT IN :masterCaseIds
		]) {
			caseIdByContract.put(c.Contrato__c, c.Id);

		}


		List<Case> result;
		if(caseIdByContract.size() != 0) {
			result = new List<Case>();
			for(Case c : cases) {

				if(caseIdByContract.containsKey(c.Contrato__c)) {
					c.addError(Label.Error_caso_ya_hay_clon_de_contrato.replace('{0}', caseIdByContract.get(c.Contrato__c)));
					contractIds.remove(c.Contrato__c);
				}
				else {
					result.add(c);
				}
			}
		}
		else {
			result = cases;
		}
		return result;
	}

	private static Map<Id, Case> getMasterCases(List<Case> cases) {
		Set<Id> masterIds = new Set<Id>();
		for(Case c : cases) {
			masterIds.add(c.Caso_maestro__c);
		}

		return new Map<Id, Case>([
			SELECT Id, Contrato__c, Contrato_clonado__c
			FROM Case
			WHERE Id IN :masterIds
		]);
	}

	private static void assignCasesOfReason(List<Case> cases, Grupos_para_casos__c groupCaseSettings) {
		List<User> users = Database.query(
			'SELECT Id '
			+ 'FROM User '
			+ 'WHERE Id IN ('
				+ 'SELECT UserOrGroupId '
				+ 'FROM GroupMember '
				+ 'WHERE Group.Name = \'' + groupCaseSettings.Nombre_de_grupo__c + '\') '
			+ 'ORDER BY ' + groupCaseSettings.Campo_en_usuario__c + ' ASC NULLS FIRST '
			+ 'LIMIT ' + cases.size()
		);

		integer i = 0;
		Set<Id> userIds = new Set<Id>();
		for(Case c : cases) {
			c.OwnerId = users[i].Id;
			//users[i].put(groupCaseSettings.Campo_en_usuario__c, System.now());
			userIds.add(users[i].Id);
			i++;
			if(i == users.size()) {
				i -= users.size();
			}
		}
		updateUsersInFuture(userIds, groupCaseSettings.Campo_en_usuario__c);
		//update users;
	}

	private static void eraseCaseModificationsRecipients(Set<Id> caseIds) {
		List<Beneficiario__c> recipientsToDelete = new List<Beneficiario__c>();
		List<Beneficiario__c> recipientsToUpdate = new List<Beneficiario__c>();
		for(Beneficiario__c b : [
			SELECT Id, Estado__c
			FROM Beneficiario__c
			WHERE Caso__c IN :caseIds
		]) {
			if(b.Estado__c == 'Baja') {
				b.Caso__c = null;
				recipientsToUpdate.add(b);
			}
			else {
				recipientsToDelete.add(b);
			}
		}
		if(recipientsToUpdate.size() > 0) {
			update recipientsToUpdate;
		}
		if(recipientsToDelete.size() > 0) {
			delete recipientsToDelete;
		}
	}

	private static void eraseCaseModificationsRecipientCoverageRelation(Set<Id> caseIds) {
		List<Cobertura_de_Beneficiario__c> toDelete = new List<Cobertura_de_Beneficiario__c>();
		List<Cobertura_de_Beneficiario__c> toUpdate = new List<Cobertura_de_Beneficiario__c>();
		for(Cobertura_de_Beneficiario__c c : [
			SELECT Id, Caso__c, Beneficiario__r.Estado__c
			FROM Cobertura_de_Beneficiario__c
			WHERE Caso__c IN :caseIds
		]) {
			if(c.Beneficiario__r.Estado__c == 'Baja') {
				c.Caso__c = null;
				toUpdate.add(c);
			}
			else {
				toDelete.add(c);
			}
		}

		if(toDelete.size() > 0) {
			delete toDelete;
		}
		if(toUpdate.size() > 0) {
			update toUpdate;
		}
	}

	private static void eraseCaseModificationsDiscounts(Set<Id> caseIds) {
		delete [
			SELECT Id
			FROM Descuento_Recargo_Aplicado__c
			WHERE Caso__c IN :caseIds
		];

		delete [
			SELECT Id
			FROM Aplicante__c
			WHERE Caso__c IN :caseIds
		];
	}

	private static void activateCaseModificationsRecipients(Set<Id> caseIds) {
		List<Beneficiario__c> recipientsToUpdate = [
			SELECT Id, Caso__c, Estado__c
			FROM Beneficiario__c
			WHERE Caso__c IN :caseIds
		];

        System.debug(caseIds);
        System.debug(recipientsToUpdate);

		for(Beneficiario__c b : recipientsToUpdate) {
			b.Caso__c = null;
			b.Estado__c = 'Activo';
		}

		update recipientsToUpdate;
	}

	private static void activateCaseModificationsRecipientCoverageRelation(Set<Id> caseIds) {
		List<Cobertura_de_Beneficiario__c> toDelete = new List<Cobertura_de_Beneficiario__c>();
		List<Cobertura_de_Beneficiario__c> toUpdate = new List<Cobertura_de_Beneficiario__c>();

		for(Cobertura_de_Beneficiario__c r : [
			SELECT Id, Caso__c
			FROM Cobertura_de_Beneficiario__c
			WHERE Caso__c IN :caseIds
				OR (Beneficiario__r.Caso__c IN :caseIds)
		]) {
			if(r.Caso__c != null) {
				r.Caso__c = null;
				toUpdate.add(r);
			}
			else {
				toDelete.add(r);
			}
		}

		if(toUpdate.size() > 0) {
			update toUpdate;
		}
		if(toDelete.size() > 0) {
			delete toDelete;
		}
	}

	private static void activateCaseModificationsDiscounts(Set<Id> caseIds) {
		List<Descuento_Recargo_Aplicado__c> discounts = [
			SELECT Id, Caso__c
			FROM Descuento_Recargo_Aplicado__c
			WHERE Caso__c IN :caseIds
		];

		for(Descuento_Recargo_Aplicado__c d : discounts) {
			d.Caso__c = null;
		}

		update discounts;

		List<Aplicante__c> applicants = [
			SELECT Id, Caso__c
			FROM Aplicante__c
			WHERE Caso__c IN :caseIds
		];

		for(Aplicante__c a : applicants) {
			a.Caso__c = null;
		}

		update applicants;
	}

	@future
	private static void updateUsersInFuture(Set<Id> usersIds, String fieldName) {
		//HACK avoiding mixed DML exception
		List<User> users = new List<User>();
		for(Id uid : usersIds) {
			User u = new User(id = uid);
			u.put(fieldName, System.now());
			users.add(u);
		}
		update users;
	}


	public static List<Case> checkCardNumbers(List<Case> cases) {
		List<Case> validCases = new List<Case>();

		for(Case caso : cases) {
			if(Validate.cardNumberWithType(String.valueOf(caso.Numero_de_Tarjeta__c),caso.Tipo_de_tarjeta__c)) {
				validCases.add(caso);
			}
			else {
				caso.Numero_de_Tarjeta__c.addError(Label.Tarjeta_invalida);
			}
		}

		return validCases;
	}

	public static void moveCardNumbers(List<Case> cases) {
		for(Case c : cases) { /*
			c.Tarjeta_sin_cifrar__c = c.Numero_de_Tarjeta__c;
			c.Numero_de_Tarjeta__c = '************' + c.Numero_de_Tarjeta__c.right(4);
			*/
			//c.CBU_sin_cifrar__c = c.CBU__c;
			//c.CBU__c = c.CBU__c.left(6) + '**********' + c.CBU__c.right(4);
		}
	}



}
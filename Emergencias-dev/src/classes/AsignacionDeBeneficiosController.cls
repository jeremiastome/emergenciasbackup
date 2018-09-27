public class AsignacionDeBeneficiosController {
	public List<Beneficiario__c> Recipients { get; set; }
	
	public Map<Id, Beneficiario__c> getRecipientsById() {
		return new Map<Id, Beneficiario__c> (Recipients);
	}
	
	public Map<Id, Cobertura_de_Beneficiario__c> RecipientsCoverages { get; set; }
	public Id ContractId { get; set; }
	public List<Cobertura__c> Coverages { get; set; }
	
	public Map<Id, Cobertura__c> getCoveragesById() {
		return new Map<Id, Cobertura__c> (Coverages);
	}
	
	public Map<Id, Map<Id, CoverageRecipientWrapper>> RelationsByCoverageByRecipient { get; set; }
	
	public Map<Id, List<CoverageRecipientWrapper>> getRelationsByCoverage() {
		Map<Id, List<CoverageRecipientWrapper>> out = new Map<Id, List<CoverageRecipientWrapper>> ();
		
		for (Map<Id, CoverageRecipientWrapper> relationsByCoverage : RelationsByCoverageByRecipient.values()) {
			for (Id idCoverage : relationsByCoverage.keySet()) {
				if (!out.containsKey(idCoverage)) {
					out.put(idCoverage, new CoverageRecipientWrapper[] { });
				}
				
				out.get(idCoverage).add(relationsByCoverage.get(idCoverage));
			}
		}
		
		return out;
	}
	
	public String RecipientToRemove { get; set; }
	public boolean EmptyRecipients { get; set; }
	public boolean InvalidDiscounts { get; set; }
	public String ReturnRecord { get; set; }
	
	public Beneficiario__c NewRecipient { get; set; }
	public Account NewAccount { get; set; }
	public String AccFirstName { get; set; } //HACK not rendering in visualforce due to lightning interfering.
	public String AccLastName { get; set; }
	
	public boolean ForAdditionCase { get; set; }
	public Id additionCaseId { get; set; }
	
	private Id personRecipientTypeId;
	private Id personAccountRecordType;
	
	public AsignacionDeBeneficiosController() {
		ContractId = ApexPages.currentPage().getParameters().get('Id');
		ReturnRecord = ApexPages.currentPage().getParameters().get('retId');
		String OpportunityId = ApexPages.currentPage().getParameters().get('opp');
		
		ForAdditionCase = false;
		if (String.isBlank(ReturnRecord)) {
			if (String.isBlank(OpportunityId)) {
				ReturnRecord = ContractId;
			}
			else {
				ReturnRecord = OpportunityId;
			}
		}
		else {
			checkIsForAdditionCase();
		}
		
		Recipients = [
			SELECT Id, Nombre__c, Apellido__c, Titular__r.Cliente__r.Name, Fecha_de_nacimiento__c,
			RecordTypeId, RecordType.DeveloperName, Caso__c, (
				SELECT Id, Cobertura__c, Beneficiario__c
				FROM Coberturas__r
				WHERE Caso__c = :additionCaseId OR Caso__c = null
			)
			FROM Beneficiario__c
			WHERE Contrato__c = :ContractId
			AND(Caso__c = :additionCaseId OR Caso__c = null)
		];
		
		RecipientsCoverages = new Map<Id, Cobertura_de_Beneficiario__c> ([
			SELECT Id, Cobertura__c, Beneficiario__c, Caso__c, Cantidad_domicilio__c,
				Cantidad_domicilio_en_transito__c, (
					SELECT Id, Descuento_Recargo_Aplicado__c,
						Descuento_Recargo_Aplicado__r.Codigo_de_descuento__c,
						Descuento_Recargo_Aplicado__r.Nombre_de_descuento__c, Caso__c
					FROM Aplicantes__r
					WHERE Caso__c = :additionCaseId OR Caso__c = null
				), (
					SELECT Id, Cantidad__c, Cantidad_en_transito__c, Activo__c
					FROM Cantidades_de_productos_de_beneficiaros__r
					WHERE Activo__c = true
						OR Caso__c = :ReturnRecord
						OR Oportunidad__c = :ReturnRecord
				)
			FROM Cobertura_de_Beneficiario__c
			WHERE Beneficiario__c IN :Recipients
				AND (
					Caso__c = :additionCaseId
					OR Caso__c = null
				)
		]);
		
		Coverages = [
			SELECT Id, Nombre_de_producto__c, (
				SELECT Id, Codigo_de_descuento__c, Nombre_de_descuento__c, fecha_inicio__c
				FROM Descuentos_recargos_aplicados__r
				WHERE Caso__c = :additionCaseId OR Caso__c = null
			)
			FROM Cobertura__c
			WHERE Contrato__c = :ContractId
		];
		
		prepareRelations();
		
		RecordType rt = [
			SELECT Id FROM RecordType
			WHERE DeveloperName = 'PersonAccount'
				AND SobjectType = 'Account'
		];
		personAccountRecordType = rt.Id;
		rt = [
			SELECT Id
			FROM RecordType
			WHERE sObjectType = 'Beneficiario__c'
				AND IsActive = true
				AND DeveloperName = 'Persona'
		];
		personRecipientTypeId = rt.Id;
		
		prepareNewRecipient();
		EmptyRecipients = false;
		InvalidDiscounts = false;
	}
	
	public void createRecipient() {
		if (NewRecipient.RecordTypeId == personRecipientTypeId) {
			NewAccount.FirstName = AccFirstName;
			NewAccount.LastName = AccLastName;
			
			upsert NewAccount CUIL_CUIT__c;
			
			NewRecipient.Beneficiario__c = NewAccount.Id;
		}
		//If this isn't for an addition case, the Id will be null and this won't matter
		NewRecipient.Caso__c = additionCaseId;
		
		insert NewRecipient;
		
		NewRecipient = [
			SELECT Id, Nombre__c, Apellido__c, Titular__r.Cliente__r.Name, Fecha_de_nacimiento__c,
			Caso__c, RecordType.DeveloperName, (
				SELECT Id, Cobertura__c, Beneficiario__c, Caso__c
				FROM Coberturas__r
			) //XXX Brought just so that the Coberturas__r field is present
			FROM Beneficiario__c
			WHERE Id = :NewRecipient.Id
		];
		
		Recipients.add(NewRecipient);
		
		prepareRelationsForRecipient(NewRecipient);
		
		prepareNewRecipient();
	}
	
	public PageReference save() {
		Map<Id, Integer> recipientsByCoverage = getAmountOfRecipientsByCoverage();
		Map<Id, Integer> minorsWithDiscountByCoverage = new Map<Id, Integer> ();
		
		List<Cobertura_de_Beneficiario__c> relationsToInsert = new List<Cobertura_de_Beneficiario__c> ();
		List<Cobertura_de_Beneficiario__c> relationsToDelete = new List<Cobertura_de_Beneficiario__c> ();
		
		List<Aplicante__c> applicantsToDelete = new List<Aplicante__c> ();
		if (ContractId != null) {
			Contrato__c currentContract = [SELECT Estado__c FROM contrato__c WHERE id =:ContractId];
			if (currentContract.Estado__c == 'Activo') {
				update currentContract;
			}
		}
		EmptyRecipients = false;
		for (Map<Id, CoverageRecipientWrapper> RelationsByCoverage : RelationsByCoverageByRecipient.values()) {
			boolean hasACoverage = false;
			
			for (CoverageRecipientWrapper wrapper : RelationsByCoverage.values()) {
				if (wrapper.IsActive) {
					if (wrapper.Relation.Id == null) {
						relationsToInsert.add(wrapper.Relation);
					}
					// Proccess discount applicants
					for (CoverageDiscountWrapper discountWrapper : wrapper.Discounts) {
						if (discountWrapper.IsActive) {
							Date birthdate = getRecipientsById().get(wrapper.Relation.Beneficiario__c).Fecha_de_nacimiento__c;
							
							Integer oldAmount = minorsWithDiscountByCoverage.get(wrapper.Relation.Cobertura__c);
							minorsWithDiscountByCoverage.put(
								wrapper.Relation.Cobertura__c,
								(oldAmount == null) ? 1 : oldAmount + 1
							);
						}
						else if (discountWrapper.Relation.Id != null) {
							applicantsToDelete.add(discountWrapper.Relation);
						}
					}
					hasACoverage = true;
				}
				else if (wrapper.Relation.Id != null) {
					relationsToDelete.add(wrapper.Relation);
					// If the recipient doesn't belong to the coverage anymore, then he can't apply for its discounts
					for (CoverageDiscountWrapper discountWrapper : wrapper.Discounts) {
						if (discountWrapper.Relation.Id != null) {
							applicantsToDelete.add(discountWrapper.Relation);
						}
					}
				}
			}
			
			if (!hasACoverage) {
				EmptyRecipients = true;
			}
		}
		
		InvalidDiscounts = false;
		for (Id coverageId : minorsWithDiscountByCoverage.keySet()) {
			Integer minorsToValidate = minorsWithDiscountByCoverage.get(coverageId);
			Integer recipientsInCoverage = recipientsByCoverage.get(coverageId);
			
			if (minorsToValidate > (recipientsInCoverage / 2)) {
				InvalidDiscounts = true;
				break;
			}
		}
		
		if (!EmptyRecipients && !InvalidDiscounts) {
			delete applicantsToDelete;
			delete relationsToDelete;
			
			System.debug(relationsToInsert);
			insert relationsToInsert;
			List<Aplicante__c> applicantsToInsert = new List<Aplicante__c> ();
			List<Cantidad_de_producto_de_beneficiaro__c> amountDetails =
				new List<Cantidad_de_producto_de_beneficiaro__c>();
			for (Map<Id, CoverageRecipientWrapper> RelationsByCoverage : RelationsByCoverageByRecipient.values()) {
				for (CoverageRecipientWrapper wrapper : RelationsByCoverage.values()) {
					if (wrapper.IsActive) {
						if (wrapper.Relation.Id != null) {
							for (CoverageDiscountWrapper discountWrapper : wrapper.Discounts) {
								if (discountWrapper.IsActive) {
									if (discountWrapper.Relation.Id == null) {
										discountWrapper.Relation.Cobertura__c = wrapper.Relation.Id;
										discountWrapper.Relation.Fin_Vigencia__c =
											getRecipientsById().get(wrapper.Relation.Beneficiario__c)
												.Fecha_de_nacimiento__c.addYears(13);
										applicantsToInsert.add(discountWrapper.Relation);
									}
								}
							}
							
							if(wrapper.isAddress) {
								Cantidad_de_producto_de_beneficiaro__c amntDet =
									wrapper.getAddressAmountDetails();
								if(amntDet != null) {
									amountDetails.add(amntDet);
								}
							}
						}
					}
				}
			}
			System.debug(applicantsToInsert);
			insert applicantsToInsert;
			upsert amountDetails;
			return new PageReference('/' + ReturnRecord);
		}
		else {
			return null;
		}
	}
	
	public void removeRecipient() {
		RelationsByCoverageByRecipient.remove(RecipientToRemove);
		
		Integer i;
		for (i = 0; i<Recipients.size(); i++) {
			if (recipients[i].Id == RecipientToRemove) {
				break;
			}
		}
		if (i<Recipients.size()) {
			// Remove applications before deleting the recipient
			delete [
				SELECT Id
				FROM Aplicante__c
				WHERE Cobertura__c IN (
					SELECT Id
					FROM Cobertura_de_beneficiario__c
					WHERE Beneficiario__c = : RecipientToRemove
				)
			];
			delete Recipients[i];
			Recipients.remove(i);
		}
	}
	
	private void prepareRelations() {
		RelationsByCoverageByRecipient = new Map<Id, Map<Id, CoverageRecipientWrapper>> ();
		for (Beneficiario__c recipient : Recipients) {
			prepareRelationsForRecipient(recipient);
		}
	}
	
	private void prepareRelationsForRecipient(Beneficiario__c recipient) {
		Map<Id, Cobertura_de_Beneficiario__c> existingRelationsByCoverage = new Map<Id, Cobertura_de_Beneficiario__c> ();
		for (Cobertura_de_Beneficiario__c rel : recipient.Coberturas__r) {
			existingRelationsByCoverage.put(rel.Cobertura__c, RecipientsCoverages.get(rel.Id));
		}
		
		Map<Id, CoverageRecipientWrapper> relationsByCoverage = new Map<Id, CoverageRecipientWrapper> ();
		for (Cobertura__c coverage : Coverages) {
			if (existingRelationsByCoverage.containsKey(coverage.Id)) {
				relationsByCoverage.put(
					coverage.Id,
					new CoverageRecipientWrapper(
						existingRelationsByCoverage.get(coverage.Id),
						coverage,
						recipient,
						additionCaseId,
						(Id)ReturnRecord
					)
				);
			}
			else {
				relationsByCoverage.put(
					coverage.Id,
					new CoverageRecipientWrapper(
						coverage,
						recipient,
						additionCaseId,
						(Id)ReturnRecord
					)
				);
			}
		}
		
		RelationsByCoverageByRecipient.put(recipient.Id, relationsByCoverage);
	}
	
	public void prepareNewRecipient() {
		NewRecipient = new Beneficiario__c(
			Contrato__c = ContractId
		);

		NewAccount = new Account(RecordTypeId = personAccountRecordType);
		AccFirstName = '';
		AccLastName = '';
	}
	
	private Map<Id, Integer> getAmountOfRecipientsByCoverage() {
		Map<Id, Integer> recipientsByCoverage = new Map<Id, Integer> ();
		
		for (Cobertura__c coverage : Coverages) {
			recipientsByCoverage.put(coverage.Id, getRecipientsWithoutDiscount(coverage.Id));
		}
		
		return recipientsByCoverage;
	}
	
	private Integer getRecipientsWithoutDiscount(Id coverageId) {
		Integer nOfRecipients = 0;
		
		for (CoverageRecipientWrapper wrapper : getRelationsByCoverage().get(coverageId)) {
			// Has to be active
			if (!wrapper.IsActive) continue;
			
			Beneficiario__c recipient = getRecipientsById().get(wrapper.Relation.Beneficiario__c);
			
			// It shouldn't have the same discount activated
			Boolean hasDiscountActivated = false;
			
			for (CoverageDiscountWrapper discountWrapper : wrapper.Discounts) {
				if (discountWrapper.IsActive) {
					hasDiscountActivated = true;
					break;
				}
			}
			
			// Recipient exists and is a person
			if (recipient == null || recipient.RecordTypeId != personRecipientTypeId) continue;
			
			if (!hasDiscountActivated) nOfRecipients++;
		}
		
		return nOfRecipients;
	}
	
	private void checkIsForAdditionCase() {
		Id returnId = Id.valueOf(ReturnRecord);
		if (returnId.getSObjectType() == Schema.Case.SObjectType) {
			Case theCase = [
				SELECT Id, RecordType.DeveloperName
				FROM Case
				WHERE Id = :returnId
			];
			Casos_Beneficiarios_Descuentos__c caseSettings = Casos_Beneficiarios_Descuentos__c.getValues(theCase.RecordType.DeveloperName);
			if (caseSettings != null && caseSettings.Id != null) {
				ForAdditionCase = true;
				additionCaseId = returnId;
			}
		}
	}
	
	public class CoverageRecipientWrapper {
		public Cobertura_de_Beneficiario__c Relation { get; set; }
		public Cantidad_de_producto_de_beneficiaro__c amountDetail {get; set;}
		public CoverageDiscountWrapper[] Discounts { get; set; }
		public Boolean isAnAdult { get; set; }
		public Boolean isAddress {get; set;}
		public Boolean IsActive {
			get {
				if(isAddress) {
					//Directions should be active when either of their amounts
					// are greater than zero
					return (
						amountDetail.Cantidad__c > 0
						|| amountDetail.Cantidad_en_transito__c > 0
					);
				}
				else {
					//All other types of recipients should just toggle the active on or off
					return IsActive;
				}
			}
			set;
		}
		
		private Cantidad_de_producto_de_beneficiaro__c oldDetail;
		
		public CoverageRecipientWrapper(
			Cobertura__c coverage,
			Beneficiario__c recipient,
			Id caseId,
			Id returnId
		) {
			checkIfIsAnAdult(recipient);
			Relation = new Cobertura_de_Beneficiario__c(
				Beneficiario__c = recipient.Id,
				Cobertura__c = coverage.Id,
				Caso__c = caseId //If not for a case, null is passed
			);
			if(returnId.getSobjectType() == Schema.Opportunity.SObjectType) {
				Relation.Creado_en_Oportunidad__c = returnId;
			}
			else if(returnId.getSobjectType() == Schema.Case.SObjectType) {
				Relation.Creado_en_Caso__c = returnId;
			}
			
			Discounts = new CoverageDiscountWrapper[] { };
			System.debug(coverage.Descuentos_recargos_aplicados__r);
			// Create new applicants as options
			if (coverage.Descuentos_recargos_aplicados__r != null) {
				loadDiscounts(coverage.Descuentos_recargos_aplicados__r, recipient, caseId);
			}
			
			isActive = false;
			isAddress = recipient.RecordType.DeveloperName == 'Domicilio';
			if(isAddress) {
				createAmountDetail(returnId);
			}
		}
		
		public CoverageRecipientWrapper(
			Cobertura_de_Beneficiario__c rel,
			Cobertura__c coverage,
			Beneficiario__c recipient,
			Id caseId,
			Id returnId
		) {
			checkIfIsAnAdult(recipient);
			Relation = rel;
			
			Discounts = new CoverageDiscountWrapper[] { };
			
			Set<Id> existingApplications = new Set<Id> ();
			// Prepare applicants
			if (coverage.Descuentos_recargos_aplicados__r != null) {
				loadDiscounts(coverage.Descuentos_recargos_aplicados__r, recipient, rel.Aplicantes__r, caseId);
			}
			isActive = true;
			isAddress = recipient.RecordType.DeveloperName == 'Domicilio';
			if(isAddress) {
				for(Cantidad_de_producto_de_beneficiaro__c detail:
					rel.Cantidades_de_productos_de_beneficiaros__r
				) {
					if(detail.Activo__c) {
						oldDetail = detail;
					}
					else {
						amountDetail = detail;
					}
				}
				if(amountDetail == null) {
					createAmountDetail(returnId);
				}
			}
		}
		
		public Cantidad_de_producto_de_beneficiaro__c getAddressAmountDetails() {
			if(IsActive && amountsChanged()) {
				amountDetail.Cobertura_de_Beneficiario__c = Relation.Id;
				return amountDetail;
			}
			else {
				return null;
			}
		}
		
		private boolean amountsChanged() {
			return oldDetail == null
				|| oldDetail.Cantidad__c != amountDetail.Cantidad__c
				|| oldDetail.Cantidad_en_transito__c != amountDetail.Cantidad_en_transito__c;
		}
		
		private void createAmountDetail(Id returnId) {
			amountDetail = new Cantidad_de_producto_de_beneficiaro__c(
				Activo__c = false,
				Cantidad__c = Relation.Cantidad_domicilio__c,
				Cantidad_en_transito__c = Relation.Cantidad_domicilio_en_transito__c
			);
			if(returnId.getSobjectType() == Schema.Opportunity.SObjectType) {
				amountDetail.Oportunidad__c = returnId;
			}
			else if(returnId.getSobjectType() == Schema.Case.SObjectType) {
				amountDetail.Caso__c = returnId;
			}
		}
		
		private void loadDiscounts(List<Descuento_Recargo_Aplicado__c> appliedDiscounts, Beneficiario__c recipient, Id caseId) {
			loadDiscounts(appliedDiscounts, recipient, new List<Aplicante__c> (), caseId);
		}
		
		private void loadDiscounts(Descuento_Recargo_Aplicado__c[] appliedDiscounts, Beneficiario__c recipient, List<Aplicante__c> applicants, Id caseId) {
			Map<Id, Aplicante__c> applicantsByDiscount = new Map<Id, Aplicante__c> ();
			for (Aplicante__c appl : applicants) {
				applicantsByDiscount.put(appl.Descuento_Recargo_Aplicado__c, appl);
			}
			
			for (Descuento_Recargo_Aplicado__c discount : appliedDiscounts) {
				//Is it the one 'free child with two adults' discount?
				if (discount.Codigo_de_descuento__c == 'ZDV1') {
					Aplicante__c appl = applicantsByDiscount.get(discount.Id);
					if (appl == null) {
						Discounts.add(new CoverageDiscountWrapper(discount, recipient, caseId));
					}
					else {
						Discounts.add(new CoverageDiscountWrapper(appl));
					}
					//Once found the discount, no need to keep looking.
					return;
				}
			}
		}
		
		private void checkIfIsAnAdult(Beneficiario__c recipient) {
			DateTime birthDate = recipient.Fecha_de_nacimiento__c;
			if (birthDate == null) {
				IsAnAdult = true;
			}
			else {
				DateTime birthDateOfAnAdult = Date.today().addYears(- 13);
				//Compare the amount of millis since the Unix epoch of the recipient's birth date
				// and 13 years ago. If the birth date is earlier (the amount of millis is lower),
				// the recipient is an adult.
				IsAnAdult = birthDateOfAnAdult.getTime() >= birthDate.getTime();
			}
		}
	}
	
	public class CoverageDiscountWrapper {
		public boolean IsActive { get; set; }
		public Aplicante__c Relation { get; set; }
		public String DiscountName { get; set; }
		
		public CoverageDiscountWrapper(Descuento_Recargo_Aplicado__c discount, Beneficiario__c recipient, Id caseId) {
			Relation = new Aplicante__c(
				Cobertura__c = null,
				Descuento_Recargo_Aplicado__c = discount.Id,
				Caso__c = caseId,
				Inicio_vigencia__c = discount.Fecha_inicio__c,
				Fin_Vigencia__c = recipient.Fecha_de_nacimiento__c != null ? recipient.Fecha_de_nacimiento__c.addYears(13) : null
			);
			
			IsActive = false;
			
			DiscountName = discount.Nombre_de_descuento__c;
		}
		
		public CoverageDiscountWrapper(Aplicante__c rel) {
			Relation = rel;
			isActive = true;
			
			DiscountName = rel.Descuento_Recargo_Aplicado__r.Nombre_de_descuento__c;
		}
	}
}
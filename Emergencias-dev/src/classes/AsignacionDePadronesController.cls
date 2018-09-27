public class AsignacionDePadronesController {
	public static RecordType MassiveRecipientType = [
		SELECT Id
		FROM RecordType
		WHERE DeveloperName = 'Padron'
			AND IsActive = true
			AND SObjectType = 'Beneficiario__c'
	];

	public List<RecipientWrapper> Recipients {get; set;}
	public Map<Id, Decimal> oldPadronValuesByCoverageId {get; set;}
	public String NextRecipient {get; set;}
	public Id ReturnRecord {get; set;}
	public Id ContractId {get; set;}
	public List<Cobertura__c> Coverages {get; set;}
	public Map<String, String> IVATreatmentLabelByValue {get; set;}
	public List<SelectOption> Holders {get; set;}
	public String SelectedHolder {get; set;}
	public integer RecipientToRemove {get; set;}
	public Date StartDate {get; set;}
	public List<SelectOption> ProvinceOptions {get; set;}

	private Map<String, String> RecipientNames;//To avoid repeats
	private integer lastIndex = 0;
	private List<Beneficiario__c> recipientsToRemove;
	List<Cobertura_de_Beneficiario__c> recipientCoveragesToDelete;
	List<HistorialPadron> hitorialToSave;

	public AsignacionDePadronesController() {
		ContractId = ApexPages.currentPage().getParameters().get('Id');
		String retId = ApexPages.currentPage().getParameters().get('retId');
		if(String.isBlank(retId)) {
			ReturnRecord = ContractId;
		}
		else {
			ReturnRecord = retId;
		}

		prepareCoverages();
		prepareIVATreatmentValues();
		prepareHolders();

		NextRecipient = '';
		RecipientToRemove = -1;
		recipientsToRemove = new List<Beneficiario__c>();
		RecipientNames = new Map<String, String>();
		Recipients = new List<RecipientWrapper>();
		oldPadronValuesByCoverageId = new Map<Id, Decimal>();
		recipientCoveragesToDelete = new List<Cobertura_de_Beneficiario__c>();
		hitorialToSave = new List<HistorialPadron>();
		regenerateRecipients();
		prepareProvinces();
	}

	public void addRecipient() {
		if(String.isBlank(NextRecipient)) {
			//TODO add some kind of message
			return;
		}
		if(!RecipientNames.containsKey(NextRecipient)) {
			Recipients.add(new RecipientWrapper(
				ContractId,
				NextRecipient,
				lastIndex++,
				Coverages,
				IVATreatmentLabelByValue,
				SelectedHolder
			));

			List<SelectOption> provinceTemp = new List<SelectOption>();
			for(SelectOption op : ProvinceOptions) {
				if(op.getValue() != NextRecipient) {
					provinceTemp.add(op);
				}
				else {
					RecipientNames.put(op.getValue(), op.getLabel());
				}
			}
			ProvinceOptions = provinceTemp;
		}
		// else {
		// 	//TODO add some kind of message
		// }
		NextRecipient = '';
	}

	public PageReference save() {
		List<Beneficiario__c> recipientsToSave = new List<Beneficiario__c>();
		for(RecipientWrapper wrp : Recipients) {
			wrp.Recipient.Fecha_de_padron__c = StartDate;
			recipientsToSave.add(wrp.Recipient);
		}
		upsert recipientsToSave;

		List<Cobertura_de_Beneficiario__c> recipientCoverages = new List<Cobertura_de_Beneficiario__c>();
		for(RecipientWrapper wrp : Recipients) {
			for(Cobertura_de_Beneficiario__c rcv : wrp.RelationsByIVAAndCoverage.values()) {
				String productName = getProductName(rcv.Cobertura__c);
				if(rcv.Cantidad_de_Padron__c > 0) {
					if(rcv.Id == null) {
						rcv.Beneficiario__c = wrp.Recipient.Id;
					}
					hitorialToSave.add(new HistorialPadron(
						productName, wrp.Recipient.Provincia1__c , StartDate, rcv, false));
					recipientCoverages.add(rcv);
				}
				else if(rcv.Id != null) {
					hitorialToSave.add(new HistorialPadron(
						productName, wrp.Recipient.Provincia1__c , StartDate, rcv, false));
				}
			}
		}
		HistorialPadronesUtils.registrarActualizacion(hitorialToSave, oldPadronValuesByCoverageId, ContractId);
		hitorialToSave.clear();
		upsert recipientCoverages;
		delete recipientCoveragesToDelete;
		delete recipientsToRemove;

		update new Contrato__c(Id = ContractId);
		return new PageReference('/' + ReturnRecord);
	}

	public string getProductName(Id coverageId) {
		for(Cobertura__c coverage : Coverages) {
			if(coverage.id == coverageId) {
				return coverage.Producto__r.Name;
			}
		}
		return null;
	}
	public void removeRecipient() {
		Integer i;
		for(i = 0; i < Recipients.size(); i++) {
			if(recipients[i].Index == RecipientToRemove) {
				break;
			}
		}
		if(i < Recipients.size()) {
			if(Recipients[i].Recipient.Id != null) {
				recipientsToRemove.add(Recipients[i].Recipient);
				for(Cobertura_de_Beneficiario__c cobertura : Recipients[i].RelationsByIVAAndCoverage.values()) {
					if(cobertura.id != null) {
						recipientCoveragesToDelete.add(cobertura);
						String productName = getProductName(cobertura.Cobertura__c);
						hitorialToSave.add(new HistorialPadron(
							productName, Recipients[i].Recipient.Provincia1__c , StartDate, cobertura, true));
					}
				}
			}
			String provName = Recipients[i].Recipient.Provincia1__c;
			ProvinceOptions.add(new SelectOption(provName, RecipientNames.get(provName)));
			RecipientNames.remove(provName);
			Recipients.remove(i);
		}
		RecipientToRemove = -1;
	}

	private void prepareCoverages() {
		Coverages = [
			SELECT Id, Producto__c, Producto__r.Name
			FROM Cobertura__c
			WHERE Contrato__c = :ContractId
		];
	}

	private void prepareIVATreatmentValues() {
		IVATreatmentLabelByValue = new Map<String, String>();
		for(Schema.PicklistEntry ple : Cobertura_de_Beneficiario__c.Tratamiento_de_IVA__c.getDescribe().getPicklistValues()) {
			IVATreatmentLabelByValue.put(ple.getValue(), ple.getLabel());
		}
	}

	private void prepareHolders() {
		Holders = new List<SelectOption>();

		for(Titular__c t : [
			SELECT Id, Cliente__r.Name
			FROM Titular__c
			WHERE Contrato__c = :ContractId
		]) {
			Holders.add(new SelectOption(t.Id, t.Cliente__r.Name));
		}

		SelectedHolder = Holders[0].getValue();
	}

	private void prepareProvinces() {
		ProvinceOptions = new List<SelectOption>();
		for(Schema.PicklistEntry provinceValue : Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues()) {
			if(!RecipientNames.containsKey(provinceValue.getValue())) {
				ProvinceOptions.add(new SelectOption(provinceValue.getValue(), provinceValue.getLabel()));
			}
			else {
				RecipientNames.put(provinceValue.getValue(), provinceValue.getLabel());
			}
		}
	}

	private void regenerateRecipients() {
		for(Beneficiario__c recipient : [
			SELECT Id, Provincia1__c, Fecha_de_padron__c, Interlocutor__c, Interlocutor__r.Name, (
					SELECT Id, Tratamiento_de_IVA__c, Cobertura__c, Cobertura__r.Name, Cantidad_de_Padron__c
					FROM Coberturas__r
				)
			FROM Beneficiario__c
			WHERE Contrato__c = :ContractId
		]) {
			RecipientWrapper wrapper = new RecipientWrapper(
				recipient,
				lastIndex++,
				Coverages,
				IVATreatmentLabelByValue
			);
			for(Cobertura_de_Beneficiario__c rc : recipient.Coberturas__r) {
				wrapper.RelationsByIVAAndCoverage.put(rc.Tratamiento_de_IVA__c + rc.Cobertura__c, rc);
				oldPadronValuesByCoverageId.put(rc.id, rc.Cantidad_de_Padron__c);
			}
			RecipientNames.put(recipient.Provincia1__c, '');
			Recipients.add(wrapper);

			StartDate = recipient.Fecha_de_padron__c;
		}
	}

	public class RecipientWrapper {
		public integer Index {get; set;}
		public Beneficiario__c Recipient {get; set;}
		public List<Cobertura__c> coverages {get; set;}
		public Map<String, Cobertura_de_Beneficiario__c> RelationsByIVAAndCoverage {get; set;}

		public RecipientWrapper(
			Id contractId,
			String name,
			integer index,
			List<Cobertura__c> Coverages,
			Map<String, String> IVATreatmentLabelByValue,
			String Holder
		) {
			Recipient = new Beneficiario__c(
				Contrato__c = contractId,
				Provincia1__c = name,
				RecordTypeId = AsignacionDePadronesController.MassiveRecipientType.Id,
				Titular__c = Holder
			);
			this.Index = index;
			this.coverages = Coverages;
			prepareRelations(Coverages, IVATreatmentLabelByValue);
		}

		public RecipientWrapper(
			Beneficiario__c recipient,
			integer index,
			List<Cobertura__c> Coverages,
			Map<String, String> IVATreatmentLabelByValue
		) {
			this.Recipient = recipient;
			this.Index = index;
			this.coverages = Coverages;
			prepareRelations(Coverages, IVATreatmentLabelByValue);
		}

		private void prepareRelations(
			List<Cobertura__c> Coverages,
			Map<String, String> IVATreatmentLabelByValue
		) {
			RelationsByIVAAndCoverage = new Map<String, Cobertura_de_Beneficiario__c>();
			for(String ivaTreatment : IVATreatmentLabelByValue.keyset()) {
				for(Cobertura__c coverage : Coverages) {
					RelationsByIVAAndCoverage.put(
						ivaTreatment + coverage.id,
						new Cobertura_de_Beneficiario__c(
							Cobertura__c = coverage.id,
							Tratamiento_de_IVA__c = ivaTreatment,
							Cantidad_de_Padron__c = 0
						)
					);
				}
			}
		}
	}
}
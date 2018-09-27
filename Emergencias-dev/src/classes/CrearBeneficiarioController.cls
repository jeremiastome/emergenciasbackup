public class CrearBeneficiarioController {
	public List<SelectOption> holders {get; set;}
	public List<SelectOption> recipientTypes {get; set;}
	
	public Id contractId {
		get;
		set {
			if(value != contractId) {
				contractId = value;
				
				if(recipientSo != null && recipientSo.Contrato__c == null) {
					recipientSo.Contrato__c = contractId;
				}
				prepareHolders();
			}
		}
	}
	public Beneficiario__c recipientSo {
		get;
		set {
			if(value != null) {
				if(contractId != null && value.Contrato__c == null) {
					value.Contrato__c = contractId;
				}
				if(value.RecordTypeId == null && recipientTypes != null && !recipientTypes.isEmpty()) {
					value.RecordTypeId = recipientTypes[0].getValue();
				}
			}
			recipientSo = value;
		}
	}
	
	private String profileName;
	
	public CrearBeneficiarioController() {
		holders = new List<SelectOption>();
		Profile uProf = [
			SELECT Name
			FROM Profile
			WHERE Id = :UserInfo.getProfileId()
		];
		profileName = uProf.Name;
		
		recipientTypes = new List<SelectOption>();
		for(RecordType rt : [
			SELECT Id, Name
			FROM RecordType
			WHERE sObjectType = 'Beneficiario__c'
				AND IsActive = true
				AND DeveloperName != 'Padron'
		]) {
			recipientTypes.add(new SelectOption(rt.Id, rt.Name));
		}
	}
	
	//XXX Should always be function getter, if not it will break when within an <apex:form>
	public ApexPages.Component getRecipientComponent() {
		Map<String, Schema.SObjectField> recFields = Schema.SObjectType.Beneficiario__c.fields.getMap();
		Component.Apex.PanelGrid result = new Component.Apex.PanelGrid(columns = 1);
		for(SelectOption recType : recipientTypes) {
			Metadata.Layout layoutData = getLayoutData('Beneficiario__c-' + recType.getLabel());
			Component.Apex.PanelGrid layoutComp;
			if(layoutData != null) {
				layoutComp = generateComponent(layoutData, recFields);
			}
			else {
				layoutComp = new Component.Apex.PanelGrid();
				layoutComp.childComponents.add(
					new Component.Apex.OutputLabel(
						value = 'No se encontro layout para ' + recType.getLabel()
					)
				);
			}
			layoutComp.expressions.style = 'display: {!IF('
				+ 'recipientSo.RecordTypeId == \'' + recType.getValue() + '\', \'initial\', \'none\')};';
			layoutComp.styleClass = 'recComp' + recType.getValue();
			result.childComponents.add(layoutComp);
		}
		return result;
	}
	
	private Metadata.Layout getLayoutData(String baseName) {
		List<String> layoutNames = new List<String>();
		layoutNames.add(baseName + '-' + profileName);
		layoutNames.add(baseName);//Auto Domicilio
		List<Metadata.Metadata> components = Metadata.Operations.retrieve(
			Metadata.MetadataType.Layout,
			layoutNames
		);
		
		if(components.size() != 0) {
			return (Metadata.Layout) components[0];
		}
		else {
			return null;
		}
	}
	
	private Component.Apex.PanelGrid generateComponent(
		Metadata.Layout lay,
		Map<String, Schema.SObjectField> recFields
	) {
		Component.Apex.PanelGrid result = new Component.Apex.PanelGrid(columns = 1);
		
		for(Metadata.LayoutSection lSect : lay.layoutSections) {
			Component.Apex.PanelGrid pg = new Component.Apex.PanelGrid(columns = lSect.layoutColumns.size());
			pg.columnClasses = 'sectionColumn';
			for(Metadata.LayoutColumn lCol : lSect.layoutColumns) {
				Component.Apex.PanelGrid col = new Component.Apex.PanelGrid(columns = 2);
				if(lCol.layoutItems != null) {
					for(Metadata.LayoutItem lItem : lCol.layoutItems) {
						if(lItem.behavior != Metadata.UiBehavior.Readonly
							&& lItem.field != 'Contrato__c'
							&& lItem.field != 'Motivo_de_Baja__c'
							&& lItem.field != 'Detalle_Motivo_de_Baja__c'
						) {
							Component.Apex.OutputLabel opLabel = new Component.Apex.OutputLabel();
							opLabel.value = recFields.get(lItem.field).getDescribe().getLabel();
							opLabel.for = lay.fullName + '-' + lItem.field;
							col.childComponents.add(opLabel);
							
							ApexPages.Component inComp;
							if(lItem.field == 'Titular__c') {
								Component.Apex.SelectList inField = generateHolderSelectList();
								
								// if(lItem.behavior != Metadata.UiBehavior.Required) {
								// 	inField.styleClass = 'requiredField';
								// }//TODO Check why it doesn't work in anything but checkboxes
								inComp = inField;
							}
							else {
								Component.Apex.inputField inField = new Component.Apex.inputField();
								inField.expressions.value = '{!recipientSo.' + lItem.field + '}';
								inField.onChange = 'syncFields($jq(this)); return false;';
								// if(lItem.behavior != Metadata.UiBehavior.Required) {
								// 	inField.styleClass = 'requiredField';
								// }//TODO Check why it doesn't work in anything but checkboxes
								inComp = inField;
							}
							
							inComp.id = lay.fullName + '-' + lItem.field;
							col.childComponents.add(inComp);
						}
					}
				}
				pg.childComponents.add(col);
				result.childComponents.add(pg);
			}
		}
		
		return result;
	}
	
	private Component.Apex.SelectList generateHolderSelectList() {
		Component.Apex.SelectList result = new Component.Apex.SelectList(
			size = 1,
			multiselect = false
		);
		result.expressions.value = '{!recipientSo.Titular__c}';
		
		Component.Apex.SelectOptions options = new Component.Apex.SelectOptions();
		options.expressions.value = '{!holders}';
		result.childComponents.add(options);
		result.onChange = 'syncFields($jq(this)); return false;';
		
		return result;
	}
	
	private void prepareHolders() {
		holders = new List<SelectOption>();
		
		for(Titular__c holder : [
			SELECT Id, Cliente__r.Name
			FROM Titular__c
			WHERE Contrato__c = :contractId
		]) {
			holders.add(new SelectOption(holder.Id, holder.Cliente__r.Name));
		}
	}
}
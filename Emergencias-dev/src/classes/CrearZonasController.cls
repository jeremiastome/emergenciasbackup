public class CrearZonasController {
	public Map<Id, Zona__c> Zones {get; set;}
	public List<SelectOption> ZoneSelectOptions {get; set;}
	public EditableZone ZoneToEdit {get; set;}
	public List<SelectOption> ZoneTypes {get; set;}
	public String ZonesJson {get; set;}
	
	public CrearZonasController() {
		Zones = new Map<Id, Zona__c> ([
			SELECT Id, Name, Tipo__c, Posicion__c
			FROM Zona__c
			ORDER BY Name
		]);
		ZonesJson = JSON.serialize(Zones);
		
		ZoneSelectOptions = new List<SelectOption>();
		for(Zona__c zone : Zones.values()){
			ZoneSelectOptions.add(new SelectOption(zone.Id, zone.Name));
		}
		
		ZoneToEdit = new EditableZone();
		
		ZoneTypes = new List<SelectOption> ();
		for(Schema.PicklistEntry zoneType : Zona__c.Tipo__c.getDescribe().getPicklistValues()){
			ZoneTypes.add(new SelectOption(zoneType.getValue(), zoneType.getLabel()));
		}
	}
	
	public void saveEditableZone() {
		Zona__c zone;
		if(String.isNotBlank(ZoneToEdit.ZoneId)) {
			zone = zones.get(ZoneToEdit.ZoneId);
		}
		else {
			zone = new Zona__c();
		}
		
		zone.Name = ZoneToEdit.Name;
		zone.Tipo__c = ZoneToEdit.Type;
		zone.Posicion__c = ZoneToEdit.Position;
		
		upsert zone;
		ZoneToEdit.ZoneId = zone.Id;
		if(!zones.containsKey(zone.Id)) {
			zones.put(zone.Id, zone);
			ZoneSelectOptions.add(new SelectOption(zone.Id, zone.Name));
		}
		
		ZonesJson = JSON.serialize(Zones);
	}
	
	public void deleteZone() {
		if(ZoneToEdit.ZoneId != null) {
			Zona__c zone = Zones.remove(ZoneToEdit.ZoneId);
			
			Integer i;
			for(i = 0; i < ZoneSelectOptions.size(); i++){
				SelectOption so = ZoneSelectOptions[i];
				if(so.getValue() == zone.Id) {
					break;
				}
			}
			ZoneSelectOptions.remove(i);
			delete zone;
			
			ZoneToEdit = new EditableZone();
			ZonesJson = JSON.serialize(Zones);
		}
	}
	
	public class EditableZone {
		public String ZoneId {get; set;}
		public String Name {get; set;}
		public String Type {get; set;}
		public String Position {get; set;}
	}
}
@isTest
public class CrearZonasControllerTest {
	private static testMethod void initiallyAListOfZonesShouldBeObtainable() {
		CrearZonasController controller = new CrearZonasController();
		
		System.assertEquals(zones.size(), controller.ZoneSelectOptions.size());
		System.assertEquals(zones.size(), controller.Zones.size());
		
		System.assertEquals(
			JSON.serialize(controller.Zones),
			controller.ZonesJson
		);
		
		for(SelectOption zoneSelectOption : controller.ZoneSelectOptions){
			System.assertNotEquals(null, zonesByName.get(zoneSelectOption.getLabel()));
			System.assertEquals(
				zonesByName.get(zoneSelectOption.getLabel()).Id,
				zoneSelectOption.getValue()
			);
		}
	}
	
	private static testMethod void initiallyItShouldBePosibleToObtainThePosibleValuesForTheZonesType() {
		Map<String, String> zoneTypes = new Map<String, String>();
		for(Schema.PicklistEntry zoneType : Zona__c.Tipo__c.getDescribe().getPicklistValues()){
			zoneTypes.put(zoneType.getValue(), zoneType.getLabel());
		}
		
		CrearZonasController controller = new CrearZonasController();
		
		for(SelectOption zoneType : controller.ZoneTypes){
			System.assertNotEquals(null, zoneTypes.get(zoneType.getValue()));
			System.assertEquals(zoneTypes.get(zoneType.getValue()), zoneType.getLabel());
		}
	}
	
	private static testMethod void itShouldBePosibleToSaveANewZone() {
		CrearZonasController controller = new CrearZonasController();
		
		controller.ZoneToEdit.Name = 'Zone E';
		controller.ZoneToEdit.Type = 'Cobrador';
		controller.ZoneToEdit.Position = '[{"lat":27.436,"lng":22.206}]';
		
		controller.saveEditableZone();
		System.assertEquals(zones.size() + 1, controller.ZoneSelectOptions.size());
		
		
		Zona__c theNewZone = [
			SELECT Id, Tipo__c, Posicion__c
			FROM Zona__c
			WHERE Name = :controller.ZoneToEdit.Name
		];
		
		System.assertEquals(controller.ZoneToEdit.Type, theNewZone.Tipo__c);
		System.assertEquals(controller.ZoneToEdit.Position, theNewZone.Posicion__c);
		
		System.assertEquals(theNewZone.Id, controller.ZoneToEdit.ZoneId);
	}
	
	private static testMethod void itShouldBePosibleToUpdateAZone() {
		CrearZonasController controller = new CrearZonasController();
		
		controller.ZoneToEdit.ZoneId = zones[0].Id;
		controller.ZoneToEdit.Name = 'Zone E';
		controller.ZoneToEdit.Type = 'Cobrador';
		controller.ZoneToEdit.Position = '[{"lat":27.436,"lng":22.206}]';
		
		controller.saveEditableZone();
		
		Zona__c theNewZone = [
			SELECT Name, Tipo__c, Posicion__c
			FROM Zona__c
			WHERE Id = :zones[0].Id
		];
		
		System.assertEquals(controller.ZoneToEdit.Type, theNewZone.Tipo__c);
		System.assertEquals(controller.ZoneToEdit.Position, theNewZone.Posicion__c);
		System.assertEquals(controller.ZoneToEdit.Name, theNewZone.Name);
	}
	
	private static testMethod void itShouldBePosibleToDeleteAZone() {
		CrearZonasController controller = new CrearZonasController();
		
		controller.ZoneToEdit.ZoneId = zones[0].Id;
		
		controller.deleteZone();
		
		System.assertEquals(null, controller.Zones.get(zones[0].Id));
		
		List<Zona__c> theZoneInDB = [
			SELECT Id
			FROM Zona__c
			WHERE Id = :zones[0].Id
		];
		
		System.assertEquals(0, theZoneInDB.size());
	}
	//==========================================================================
	static List<Zona__c> zones;
	static Map<String, Zona__c> zonesByName;
	
	static {
		zones = new List<Zona__c> {
			Build.aZone().withName('Zone A').withType('Acceso condicionado')
				.withPosition('[{"lat":37.466,"lng":-122.206},{"lat":37.456,"lng":-122.217}]')
				.build(),
			Build.aZone().withName('Zone B').withType('Acceso condicionado')
				.withPosition('[{"lat":37.436,"lng":-122.206}]').build(),
			Build.aZone().withName('Zone C').withType('Cobrador')
				.withPosition('[{"lat":37.456,"lng":-122.206}]').build(),
			Build.aZone().withName('Zone D').withType('Cobrador')
				.withPosition('[{"lat":37.476,"lng":-122.206}]').build()
		};
		insert zones;
		zones = [
			SELECT Id, Name, Tipo__c, Posicion__c
			FROM Zona__c
		];
		
		zonesByName = new Map<String, Zona__c>();
		for(Zona__c zone : zones){
			zonesByName.put(zone.Name, zone);
		}
	}
}
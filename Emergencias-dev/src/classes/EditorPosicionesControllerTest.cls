@isTest
global class EditorPosicionesControllerTest {
	@isTest
	private static void canBeDetectWhenItIsADocDetalle() {
		Case aCase = build.aCase().WithBillNumber('1234').withBillReference('Si').build();
		insert aCase;
		Test.setCurrentPageReference(new PageReference('Page.EditorPosiciones'));
		System.currentPageReference().getParameters().put('ID', aCase.Id);
		
		EditorPosicionesController editorPosiciones = new EditorPosicionesController();
		
		System.assertEquals(true, editorPosiciones.isDocDetalle);
	}
	
	@isTest
	private static void canBePosibleSetUnitsToAll() {
		Case aCase = build.aCase().WithBillNumber('1234').withBillReference('No').build();
		insert aCase;
			
		List<Posicion__c> positions = new List<Posicion__c>();
		
		for (integer i = 0; i < 5; i++) {
			Posicion__c pos = new Posicion__c();
			pos.Caso__c = aCase.id;
			positions.add(pos);
		}
        
		insert positions;
		
		Test.setCurrentPageReference(new PageReference('Page.EditorPosiciones'));
		System.currentPageReference().getParameters().put('ID', aCase.Id);
		
		EditorPosicionesController editorPosiciones = new EditorPosicionesController();
		editorPosiciones.Posicion_Comun.Unidad__c = 'ARS';
		
		editorPosiciones.SetUnidadesToAll();
		PageReference pag = editorPosiciones.Save();
			
		positions = [SELECT Unidad__c
					FROM Posicion__c];
		for (Posicion__c pos : positions) {
			system.assertEquals(editorPosiciones.Posicion_Comun.Unidad__c, pos.Unidad__c);
		}
	}
	
	@isTest 
	private static void canBePosibleSetValuesDistributedInThePositions() {
		Case aCase = build.aCase().WithBillNumber('1234').withBillReference('No').build();
		insert aCase;
        
		List<Posicion__c> positions = new List<Posicion__c>();
		for (integer i = 0; i < 5; i++) {
			Posicion__c pos = new Posicion__c();
			pos.Caso__c = aCase.id;
            pos.Unidad__c='ARS';
			positions.add(pos);
		}
		insert positions;
        
		Test.setCurrentPageReference(new PageReference('Page.EditorPosiciones'));
		System.currentPageReference().getParameters().put('ID', aCase.Id);
		
		EditorPosicionesController editorPosiciones = new EditorPosicionesController();
		editorPosiciones.Posicion_Comun.Valor__c = 123;		
		editorPosiciones.Posicion_Comun.Unidad__c = 'ARS';		
		editorPosiciones.SetAll();
		
		PageReference pag = editorPosiciones.Save();		
		
		positions = [SELECT Valor__c
					FROM Posicion__c];
        
        for (Posicion__c pos : positions) {
			system.assertEquals(editorPosiciones.Posicion_Comun.Valor__c/editorPosiciones.positions.size(),pos.Valor__c);
		}
	}
    
	@isTest 
	private static void cantBePosibleGiveAPorcentValueWithDecimals() {
		Case aCase = build.aCase().WithBillNumber('1234').withBillReference('Si').build();
		insert aCase;
        
		List<Posicion__c> positions = new List<Posicion__c>();
		for (integer i = 0; i < 5; i++) {
			Posicion__c pos = new Posicion__c();
			pos.Caso__c = aCase.id;
            pos.Unidad__c='%';
			positions.add(pos);
		}
		insert positions;
        
		Test.setCurrentPageReference(new PageReference('Page.EditorPosiciones'));
		System.currentPageReference().getParameters().put('ID', aCase.Id);
		
		EditorPosicionesController editorPosiciones = new EditorPosicionesController();
		editorPosiciones.Posicion_Comun.Valor__c = 10.4; //	DECIMAL
		editorPosiciones.Posicion_Comun.Unidad__c = '%'; // This can't be decimal with porcent.
		editorPosiciones.SetAll();
		
		PageReference pag = editorPosiciones.Save();		
		
		positions = [SELECT Valor__c
					FROM Posicion__c];
        
        for (Posicion__c pos : positions) {
			system.assertNotEquals(editorPosiciones.Posicion_Comun.Valor__c/positions.size(),pos.Valor__c); 
		}
	}
    
    
	@isTest 
	private static void cantBePosibleSaveValuesWithoutUnits() {
		Case aCase = build.aCase().WithBillNumber('1234').withBillReference('Si').build();
		insert aCase;
        
		List<Posicion__c> positions = new List<Posicion__c>();
		for (integer i = 0; i < 5; i++) {
			Posicion__c pos = new Posicion__c();
			pos.Caso__c = aCase.id;
            pos.Unidad__c=null;
			positions.add(pos);
		}
		insert positions;
        
		Test.setCurrentPageReference(new PageReference('Page.EditorPosiciones'));
		System.currentPageReference().getParameters().put('ID', aCase.Id);
		
		EditorPosicionesController editorPosiciones = new EditorPosicionesController();
		editorPosiciones.Posicion_Comun.Valor__c = 100; 
        editorPosiciones.Posicion_Comun.Unidad__c=null;
		editorPosiciones.SetAll();
		
		PageReference pag = editorPosiciones.Save();		
		
		positions = [SELECT Valor__c
					FROM Posicion__c];
        
        for (Posicion__c pos : positions) {
			system.assertNotEquals(editorPosiciones.Posicion_Comun.Valor__c/positions.size(),pos.Valor__c); 
		}
	}
	
	
	@isTest
	private static void cantBePosibleUsePocentUnitWhenTheNoteHasNoBillReference() {
		Case aCase = build.aCase().withBillReference('No').build();
		insert aCase;
		
		Posicion__c pos = new Posicion__c();
		pos.Caso__c = aCase.id;
		insert pos;
		
		Test.setCurrentPageReference(new PageReference('Page.EditorPosiciones'));
		System.currentPageReference().getParameters().put('ID', aCase.Id);
		
		EditorPosicionesController editorPosiciones = new EditorPosicionesController();
		editorPosiciones.Posicion_Comun.Valor__c = 100; 
        editorPosiciones.Posicion_Comun.Unidad__c = '%';
		editorPosiciones.SetAll();
		
		PageReference pag = editorPosiciones.Save();
		
		System.assertEquals(null, pag);
		
		Posicion__c position = [SELECT Valor__c
								FROM Posicion__c
								LIMIT 1];
        
		System.assertNotEquals(position.Valor__c, editorPosiciones.Posicion_Comun.valor__c);
        
	}
    
	@isTest
	private static void canBePosibleCancelOperationWithoutSave() {
		Case aCase = build.aCase().WithBillNumber('1234').build();
		insert aCase;
		
		Posicion__c pos = new Posicion__c();
		pos.Caso__c = aCase.id;
		insert pos;
		
		Test.setCurrentPageReference(new PageReference('Page.EditorPosiciones'));
		System.currentPageReference().getParameters().put('ID', aCase.Id);
		
		EditorPosicionesController editorPosiciones = new EditorPosicionesController();
		editorPosiciones.Posicion_Comun.Valor__c = 123;
		
		PageReference pag = editorPosiciones.Cancel();
		
		System.assertEquals('/' + aCase.Id, pag.getUrl());
		
		Posicion__c positionInDB = [
			SELECT Valor__c
			FROM Posicion__c
			
		];
		
		system.assertNotEquals(123, positionInDB.Valor__c);
	}
    
    
	@isTest
	private static void itShouldbePosibleTogetTheValuesForTheProvinceFieldOfAPosition() {
		Case aCase = build.aCase().WithBillNumber('1234').build();
		insert aCase;
		
		Posicion__c pos = new Posicion__c();
		pos.Caso__c = aCase.id;
		insert pos;
		
		Test.setCurrentPageReference(new PageReference('Page.EditorPosiciones'));
		System.currentPageReference().getParameters().put('ID', aCase.Id);
		
		EditorPosicionesController editorPosiciones = new EditorPosicionesController();
		
		for(Schema.PicklistEntry prov : Posicion__c.Provincia__c.getDescribe().getPicklistValues()) {
			System.assertEquals(true, editorPosiciones.ProvinceValues.containsKey(prov.getValue()));
			System.assertEquals(
				prov.getLabel(),
				editorPosiciones.ProvinceValues.get(prov.getValue())
			);
		}
		System.assertEquals(true, editorPosiciones.ProvinceValues.containsKey(null));
		System.assertEquals('', editorPosiciones.ProvinceValues.get(null));
	}
}
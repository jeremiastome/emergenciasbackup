@isTest
public class WSMaterialTest {
    private static testMethod void newServicesAreAdded(){
        WSMaterial.Material m = new WSMaterial.Material();
        m.TipoOperacion = 'Alta';
        m.Detalle = new WSMaterial.MaterialDetalle();
        m.Detalle.Numero = '1234';
        m.Detalle.Descripcion = 'Desc';
        m.Detalle.esBom = false;

        List<WSMaterial.Material> mats = new List<WSMaterial.Material>();
        mats.add(m);

        Test.startTest();
        WSMaterial.createMaterial(mats);
        Test.stopTest();

        List<Servicio__c> servs = [SELECT Id, Numero__c, Name, Activo__c FROM Servicio__c];
        system.assertEquals(1, servs.size());
        system.assertEquals(m.Detalle.Numero, servs[0].Numero__c);
        system.assertEquals(m.Detalle.Descripcion, servs[0].Name);
        system.assertEquals(true, servs[0].Activo__c);
    }

    private static testMethod void oldServicesAreDeactivated(){
        WSMaterial.Material m = new WSMaterial.Material();
        m.TipoOperacion = 'Alta';
        m.Detalle = new WSMaterial.MaterialDetalle();
        m.Detalle.Numero = '1234';
        m.Detalle.Descripcion = 'Desc';
        m.Detalle.esBom = false;

        List<WSMaterial.Material> mats = new List<WSMaterial.Material>();
        mats.add(m);

        WSMaterial.createMaterial(mats);

		mats[0].TipoOperacion = 'Baja';

        Test.startTest();
        WSMaterial.createMaterial(mats);
        Test.stopTest();

        List<Servicio__c> servs = [SELECT Id, Numero__c, Name, Activo__c FROM Servicio__c];
        system.assertEquals(1, servs.size());
        system.assertEquals(m.Detalle.Numero, servs[0].Numero__c);
        system.assertEquals(m.Detalle.Descripcion, servs[0].Name);
        system.assertEquals(false, servs[0].Activo__c);
    }

    private static testMethod void newProductsAreAdded(){
        WSMaterial.Material m = new WSMaterial.Material();
        m.TipoOperacion = 'Alta';
        m.Detalle = new WSMaterial.MaterialDetalle();
        m.Detalle.Numero = '1234';
        m.Detalle.Descripcion = 'Desc';
        m.Detalle.esBom = true;

        List<WSMaterial.Material> mats = new List<WSMaterial.Material>();
        mats.add(m);

        Test.startTest();
        WSMaterial.createMaterial(mats);
        Test.stopTest();

        List<Product2> prods = [SELECT Id, Numero__c, Name, IsActive FROM Product2];
        system.assertEquals(1, prods.size());
        system.assertEquals(m.Detalle.Numero, prods[0].Numero__c);
        system.assertEquals(m.Detalle.Descripcion, prods[0].Name);
        system.assertEquals(true, prods[0].IsActive);
    }

    private static testMethod void oldProductsAreDeactivated(){
        WSMaterial.Material m = new WSMaterial.Material();
        m.TipoOperacion = 'Alta';
        m.Detalle = new WSMaterial.MaterialDetalle();
        m.Detalle.Numero = '1234';
        m.Detalle.Descripcion = 'Desc';
        m.Detalle.esBom = true;

        List<WSMaterial.Material> mats = new List<WSMaterial.Material>();
        mats.add(m);

        WSMaterial.createMaterial(mats);

		mats[0].TipoOperacion = 'Baja';

        Test.startTest();
        WSMaterial.createMaterial(mats);
        Test.stopTest();

        List<Product2> prods = [SELECT Id, Numero__c, Name, IsActive FROM Product2];
        system.assertEquals(1, prods.size());
        system.assertEquals(m.Detalle.Numero, prods[0].Numero__c);
        system.assertEquals(m.Detalle.Descripcion, prods[0].Name);
        system.assertEquals(false, prods[0].IsActive);
    }

    private static testMethod void newRelationsAreAdded(){
        WSMaterial.Material s = new WSMaterial.Material();
        s.TipoOperacion = 'Alta';
        s.Detalle = new WSMaterial.MaterialDetalle();
        s.Detalle.Numero = '1234';
        s.Detalle.Descripcion = 'Desc';
        s.Detalle.esBom = false;

        WSMaterial.Material m = new WSMaterial.Material();
        m.TipoOperacion = 'Alta';
        m.Detalle = new WSMaterial.MaterialDetalle();
        m.Detalle.Numero = '5678';
        m.Detalle.Descripcion = 'Desc2';
        m.Detalle.esBom = true;

        WSMaterial.Componente comp = new WSMaterial.Componente();
        comp.Material = '1234';
        comp.IdActualizacion = 'I';
        comp.Posicion = '000';
        comp.Cantidad = '555';

        m.Componentes = new List<WSMaterial.Componente>();
        m.Componentes.add(comp);

        List<WSMaterial.Material> mats = new List<WSMaterial.Material>();
        mats.add(s);
        mats.add(m);

        Test.startTest();
        WSMaterial.createMaterial(mats);
        Test.stopTest();

        List<Product2> prods = [SELECT Id, Numero__c, Name, IsActive FROM Product2];
        List<Servicio__c> servs = [SELECT Id, Numero__c, Name, Activo__c FROM Servicio__c];

        String idExterno = m.Detalle.Numero + '|' + s.Detalle.Numero;
        List<Servicio_de_Producto__c> relations = [SELECT Id_Externo__c, Producto__c, Servicio__c, Posicion__c, Cantidad__c, Activo__c
                                                   FROM Servicio_de_Producto__c WHERE Id_Externo__c = :idExterno];

        system.assertEquals(1, relations.size());
        system.assertEquals(comp.Posicion, relations[0].Posicion__c);
        system.assertEquals(comp.Cantidad, relations[0].Cantidad__c);
        system.assertEquals(true, relations[0].Activo__c);

        system.assertEquals(prods[0].Id, relations[0].Producto__c);
        system.assertEquals(servs[0].Id, relations[0].Servicio__c);
    }

    private static testMethod void oldRelationsAreDeactivated(){
        WSMaterial.Material s = new WSMaterial.Material();
        s.TipoOperacion = 'Alta';
        s.Detalle = new WSMaterial.MaterialDetalle();
        s.Detalle.Numero = '1234';
        s.Detalle.Descripcion = 'Desc';
        s.Detalle.esBom = false;

        WSMaterial.Material m = new WSMaterial.Material();
        m.TipoOperacion = 'Alta';
        m.Detalle = new WSMaterial.MaterialDetalle();
        m.Detalle.Numero = '5678';
        m.Detalle.Descripcion = 'Desc2';
        m.Detalle.esBom = true;

        WSMaterial.Componente comp = new WSMaterial.Componente();
        comp.Material = '1234';
        comp.IdActualizacion = 'I';
        comp.Posicion = '000';
        comp.Cantidad = '555';

        m.Componentes = new List<WSMaterial.Componente>();
        m.Componentes.add(comp);

        List<WSMaterial.Material> mats = new List<WSMaterial.Material>();
        mats.add(s);
        mats.add(m);

        WSMaterial.createMaterial(mats);
        mats[1].componentes[0].IdActualizacion = 'D';

        Test.startTest();
        WSMaterial.createMaterial(mats);
        Test.stopTest();

        List<Product2> prods = [SELECT Id, Numero__c, Name, IsActive FROM Product2];
        List<Servicio__c> servs = [SELECT Id, Numero__c, Name, Activo__c FROM Servicio__c];

        String idExterno = m.Detalle.Numero + '|' + s.Detalle.Numero;
        List<Servicio_de_Producto__c> relations = [SELECT Id_Externo__c, Producto__c, Servicio__c, Posicion__c, Cantidad__c, Activo__c
                                                   FROM Servicio_de_Producto__c WHERE Id_Externo__c = :idExterno];

        system.assertEquals(1, relations.size());
        system.assertEquals(comp.Posicion, relations[0].Posicion__c);
        system.assertEquals(comp.Cantidad, relations[0].Cantidad__c);
        system.assertEquals(false, relations[0].Activo__c);

        system.assertEquals(prods[0].Id, relations[0].Producto__c);
        system.assertEquals(servs[0].Id, relations[0].Servicio__c);
    }
}
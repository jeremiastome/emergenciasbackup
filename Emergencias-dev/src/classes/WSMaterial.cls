global class WSMaterial {

    webService static Response createMaterial(List<Material> materiales) {
        System.debug('*** Materiales WS: ' + materiales);
        Response res = new Response();

        try {
            /* WSDL was reporting error: 'WSMaterial not found'.
             * Solution founded for this.
             */
            List<Product2> prods = new List<Product2>();
            List<Servicio__c> servs = new List<Servicio__c>();
            List<Servicio_de_Producto__c> relations = new List<Servicio_de_Producto__c>();
            for(Material mat : materiales){
				System.debug('Material :'+mat);
                if(mat.Detalle.EsBOM){
                    Product2 prod = new Product2();
                    prod.Numero__c = mat.Detalle.Numero;
                    prod.Name = mat.Detalle.Descripcion;
                    prod.Organizacion_de_Venta__c = mat.Detalle.OrgVentas;
                    prod.Centro__c = mat.Detalle.Centro;
                    prod.Unidad_Medida_Base__c = mat.Detalle.UnidadMedidaBase;
                    prod.Marca_de_Borrado__c = mat.Detalle.MarcaBorrado;
                    prod.Canal_de_Distribucion__c = mat.Detalle.CanalDistribucion;
                    prod.Tipo_de_Material__c = mat.Detalle.TipoMaterial;

                    if(mat.TipoOperacion == 'Baja'){
                        prod.IsActive = false;
                    }
                    else{
                        prod.IsActive = true;
                    }

                    prods.add(prod);
                    if(mat.Componentes != null){
                        for(Componente comp : mat.Componentes){
                            Servicio_de_Producto__c relation = new Servicio_de_Producto__c();
                            relation.Posicion__c = comp.posicion;
                            relation.Cantidad__c = comp.cantidad;
                            relation.Id_Externo__c = mat.Detalle.Numero + '|' + comp.Material;

                            if(comp.IdActualizacion == 'D'){
                                relation.Activo__c = false;
                            }
                            else{
                                relation.Activo__c = true;
                            }

                            relations.add(relation);
                        }
                    }
                }
                else{
                    Servicio__c serv = new Servicio__c();
                    serv.Numero__c = mat.Detalle.Numero;
                    serv.Name = mat.Detalle.Descripcion;
                    serv.Organizacion_de_Venta__c = mat.Detalle.OrgVentas;
                    serv.Centro__c = mat.Detalle.Centro;
                    serv.Unidad_Medida_Base__c = mat.Detalle.UnidadMedidaBase;
                    serv.Marca_de_Borrado__c = mat.Detalle.MarcaBorrado;
                    serv.Canal_de_Distribucion__c = mat.Detalle.CanalDistribucion;
                    serv.Tipo_de_Material__c = mat.Detalle.TipoMaterial;

                    if(mat.TipoOperacion == 'Baja'){
                        serv.Activo__c = false;
                    }
                    else{
                        serv.Activo__c = true;
                    }

                    servs.add(serv);
                }
            }
            upsert prods Numero__c;
            upsert servs Numero__c;
            upsert relations Id_Externo__c;
            /*
            List<Servicio__c> servs = new List<Servicio__c>();
            for(Integer i = 0; i < materiales.size(); i++){
                Material mat = materiales[i];
                Product2 prod = prods[i];

                for(Componente comp : mat.Componentes){
                    Servicio__c serv = new Servicio__c();
                    serv.Posicion__c = comp.Posicion;
                    serv.Name = comp.Material;
                    serv.Cantidad__c = comp.Cantidad;

                    if(comp.IdActualizacion == 'D'){
                        //serv.Activo__c = false;
                    }
                    else{
                        //serv.Activo__c = true;
                    }

                    servs.add(serv);
                }
            }
			*/
            /*
            Material__c newMaterial = new Material__c();
            newMaterial.Numero__c = matInfo.Numero;
            newMaterial.Descripcion__c = matInfo.Descripcion;
            newMaterial.Organizacion_de_Venta__c = matInfo.Organizacion_de_Venta;
            newMaterial.Centro__c = matInfo.Centro;
            newMaterial.UnidadMedidaBase__c = matInfo.UnidadMedidaBase;
            newMaterial.MarcaBorrado__c = matInfo.MarcaBorrado;
            newMaterial.Material_Componente__c = matInfo.Material_Componente;
            newMaterial.Cantidad__c = matInfo.Cantidad;
            insert newMaterial;
            */
            res.statusMsg = 'Ok';
        }
        catch (Exception e) {
            res.errorCode = e.getLineNumber();
            res.statusMsg = e.getMessage();
        }
        return res;
    }

    global class Response {
        webService Integer errorCode {get;set;}
        webService String statusMsg {get;set;}
    }

    global class Material {
        webService String TipoOperacion {get;set;}
        webService MaterialDetalle Detalle {get; Set;}
        webService List<Componente> Componentes {get; Set;}
    }

    global class MaterialDetalle {
        webService String Numero {get;set;}
        webService String Descripcion {get;set;}
        webService String OrgVentas  {get;set;}
        webService String Centro {get;set;}
        webService String UnidadMedidaBase {get;set;}
        webService String MarcaBorrado {get;set;}
        webService String CanalDistribucion {get;set;}
        webService String TipoMaterial {get;set;}
        webService Boolean EsBOM {get;set;}
    }

    global class Componente {
        webService String Posicion {get;set;}
        webService String Material {get;set;}
        webService String Cantidad {get;set;}
        webService String IdActualizacion {get;set;}
    }
}
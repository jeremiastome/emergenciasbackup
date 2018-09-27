trigger ServicioDeProducto on Servicio_de_Producto__c (before insert, before update) {
    List<String> productCodes = new List<String>();
    List<String> serviceCodes = new List<String>();
    for(Servicio_de_Producto__c relation : Trigger.New){
        List<String> codes = relation.Id_Externo__c.split('[|]');
        productCodes.add(codes[0]);
        serviceCodes.add(codes[1]);
    }
   	List<Product2> prods = [SELECT Id, Numero__c FROM Product2 WHERE Numero__c IN :productCodes];
   	List<Servicio__c> servs = [SELECT Id, Numero__c FROM Servicio__c WHERE Numero__c IN :serviceCodes];
    
    for(Servicio_de_Producto__c relation : Trigger.New){
        List<String> codes = relation.Id_Externo__c.split('[|]');
        for(Product2 prod : prods){
            if(prod.Numero__c == codes[0]){
                relation.Producto__c = prod.Id;
                break;
            }
        }	       
        for(Servicio__c serv : servs){
            if(serv.Numero__c == codes[1]){
                relation.Servicio__c = serv.Id;
                break;
            }
        }	       
    }	       
}
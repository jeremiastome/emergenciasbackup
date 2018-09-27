trigger TaskTrigger on Task (before insert, before update) {
    if(Trigger.isInsert && Trigger.isBefore){
        for(Task t : Trigger.new){
            if(t.Fecha_de_Vencimiento__c!=null) {
                t.ActivityDate = date.newinstance(
                    t.Fecha_de_Vencimiento__c.year(),
                    t.Fecha_de_Vencimiento__c.month(),
                    t.fecha_de_vencimiento__c.day()
                );
            }
        }
    }

    if(Trigger.isUpdate && Trigger.IsBefore){
    	for(Task t : Trigger.new){
        	if(Trigger.oldMap.get(t.Id).fecha_de_vencimiento__C != t.Fecha_de_Vencimiento__c){
                
            	if(t.Fecha_de_Vencimiento__c!=null) {
                    t.ActivityDate = date.newinstance(
                        t.Fecha_de_Vencimiento__c.year(),
                        t.Fecha_de_Vencimiento__c.month(),
                        t.fecha_de_vencimiento__c.day()
                    );
                }
        	}
    	}
    }

}
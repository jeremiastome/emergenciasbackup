trigger Beneficiario on Beneficiario__c(before insert, after update) {
    
    List<Id> beneficiarioActualizado = new List<Id>();
    
    if (Trigger.isBefore && Trigger.isInsert){
        List<Beneficiario__c> benfToGenerateUniqueNumber = new List<Beneficiario__c> ();
        for (Beneficiario__c ben : Trigger.New) {
            if (ben.N_mero_nico_de_Beneficiario__c == null) {
                benfToGenerateUniqueNumber.add(ben);
            }
        }
        BeneficiarioTriggerHelper.createUniqueNumbers(benfToGenerateUniqueNumber);
    }  
    else if (Trigger.isAfter && Trigger.isUpdate) {
		Map<Id, Beneficiario__c> beneficiariosActivados = new Map<Id, Beneficiario__c> ();
		Set<id> idOfContratosToUpdate = new Set<id> ();
		for (Beneficiario__c beneficiario : Trigger.new) {
            

			Beneficiario__c oldBeneficiario = Trigger.oldMap.get(beneficiario.Id);

			Boolean ahoraEstaActivo = beneficiario.Estado__c != oldBeneficiario.Estado__c && beneficiario.Estado__c == 'Activo';


			if (ahoraEstaActivo) {
				beneficiariosActivados.put(beneficiario.Id, beneficiario);
			}
            
            
			Usuario_no_envia_a_SAP__c usr = Usuario_no_envia_a_SAP__c.getValues(UserInfo.getUserName());

			if (beneficiario.Estado__c == 'Activo' &&
			(beneficiario.Cantidad_de_personas_en_transito__c != oldBeneficiario.Cantidad_de_personas_en_transito__c
			 || beneficiario.Cantidad_de_Personas_Fijas__c != oldBeneficiario.Cantidad_de_Personas_Fijas__c
			 || beneficiario.Provincia1__c != oldBeneficiario.Provincia1__c
			 || beneficiario.Tratamiento_IVA__c != oldBeneficiario.Tratamiento_IVA__c
             ||	beneficiario.Rubro_del_domicilio__c != oldBeneficiario.Rubro_del_domicilio__c) 
             && (usr == null || !usr.No_envia__c)
			)
			{
				idOfContratosToUpdate.add(beneficiario.Contrato__c);
			}
		}

		if (!idOfContratosToUpdate.isEmpty()) {
			List<Contrato__c> contratosToUpdate = [SELECT id 
                                                   FROM contrato__c 
                                                   WHERE id in :idOfContratosToUpdate 
                                                   AND Estado__c = 'Activo'];
			if (!contratosToUpdate.isEmpty()) {
				update contratosToUpdate;
			}
		}


		if (!beneficiariosActivados.isEmpty()) {

			//BeneficiarioTriggerHelper.crearPedidosDeEmbozos(beneficiariosActivados);


		}
	}
}
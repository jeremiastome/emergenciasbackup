public class Beneficiario_RequestEmbozadoController {
    
    @AuraEnabled
    public static List<wrapperBeneficiario> getWrapperList(String idCase) {
        
		Case actualCase = [
			SELECT Id, Contrato__c
			FROM Case
			WHERE id = :idCase
			LIMIT 1
		];
							//listBeneficiarios
        List<Beneficiario__c> recipients = [
			SELECT Id, Nombre__c, Apellido__c,
				(SELECT Id 
				 FROM Coberturas__r
				 WHERE Requiere_Credencial__c = TRUE),
				(SELECT Id
				 FROM Pedidos_de_Embozado__r
				 WHERE Caso__c = :idCase)
			FROM Beneficiario__c
			WHERE Contrato__c = :actualCase.Contrato__c
			AND Estado__c='Activo'
		];

        List<Beneficiario__c> recipientToCreateWrapper = new List<Beneficiario__c>();
        for (Beneficiario__c recipient : recipients) {
			if(recipient.Coberturas__r.size() != 0) { //To avoid NullPointerException
				recipientToCreateWrapper.add(recipient);
			}
        }
        
        List<wrapperBeneficiario> recipientWrapper = new List<wrapperBeneficiario> ();
        for (Beneficiario__c ben : recipientToCreateWrapper) {
            recipientWrapper.add( new wrapperBeneficiario(false, ben) );
        }
        
        return recipientWrapper;
    }
    
    @AuraEnabled
    public static String updateSelectedBeneficiarios(List<Beneficiario__c> recipients, Id caseId) {
		List<Id> recipientsIds = new List<id>();
        
		for(Beneficiario__c recipient : recipients) { 
			recipientsIds.add(recipient.id);
		}
        
		List<Pedido_de_Embozado__c> eachRequest = new List<Pedido_de_Embozado__c>();
        Configuracion_embozados__c config = Configuracion_embozados__c.getOrgDefaults();
        
		if(config==null) {
			return 'no existe una configuracion para el numero de '+
					'credencial. Comuniquese con el administrador.';
		}
            
		Integer proxNumero = (config.Ultimo_numero_credencial__c != null)  ? config.Ultimo_numero_credencial__c.intValue()+1 : 1;
        
		List<Cobertura_de_Beneficiario__c> recipientCoverages = [
			SELECT Id, Beneficiario__r.Nombre__c, Beneficiario__r.Apellido__c, 
				Beneficiario__r.TRACK_1__c, Beneficiario__r.TRACK_2__c,
				Beneficiario__r.Numero_Club_de_Emergencias__c, 
				Beneficiario__r.Version__c, Cobertura__r.Requiere_credencial__c, 
				Cobertura__r.Nombre_de_producto__c 
			FROM Cobertura_de_Beneficiario__c 
			WHERE Beneficiario__c IN :recipientsIds 
			AND Requiere_credencial__c = true

		];
        
		if(recipients.size()>0) {
                
			EmbozadoBuilder embozadoBuild = new EmbozadoBuilder(proxNumero);
			List<Beneficiario__c> recipientUpdated = new List<Beneficiario__c>();
                
			for (Cobertura_de_Beneficiario__c coverage : recipientCoverages){
                    
				Pedido_de_Embozado__c embozado = embozadoBuild.obtenerPedido(coverage.Beneficiario__r, 
                    								coverage.Cobertura__r.Nombre_de_producto__c, caseId, 'Manual');
                
				recipientUpdated.add(embozadoBuild.beneficiario);
				eachRequest.add(embozado);
			}

            try {
				update recipientUpdated;
			} catch (ListException ex) {
				return 'No se ha podido completa la operacion porque existe '+
					'algun beneficiario que tiene asignado mas de un producto '+
					'que necesita credencial.';
			}
			
			insert eachRequest;
			config.Ultimo_numero_credencial__c = embozadoBuild.numero;
			upsert config;
            
		} else {
			return 'no se han seleccionado beneficiarios.';
		}
        return 'Success';
    }
    
    public class wrapperBeneficiario {
        @AuraEnabled
        public Beneficiario__c beneficiario { get; set; }
        @AuraEnabled
        public Boolean selected { get; set; }
        @AuraEnabled
        public Boolean created { get; set; }
        
        public wrapperBeneficiario(boolean selected, Beneficiario__c beneficiario) {
            this.beneficiario = beneficiario;
			this.created = beneficiario.Pedidos_de_Embozado__r.size() != 0;
			
			if (!created) {
				this.selected = selected;
			} else {
				this.selected = true;
			}
        }
    }
}
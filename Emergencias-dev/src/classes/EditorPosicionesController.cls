public class EditorPosicionesController {
	public List<Posicion__c> positions {get; set;}
	public Posicion__c Posicion_Comun {get; set;}
	public boolean isDocDetalle {get; set;}
	public Map<String, String> ProvinceValues {get; set;}
	public string idOfCase;
	
	public EditorPosicionesController() {
		this.idOfCase = ApexPages.currentPage().getParameters().get('ID');
		ResetDate();
	}
	
	void ResetDate() {
		Posicion_Comun = new Posicion__c();
		Posicion_Comun.Unidad__c = '%';	
        
		Case aCase = [SELECT Nro_de_Factura__c, 
                      	Con_referencia_a_factura__c, 
                      	RecordType.DeveloperName
						FROM case
						WHERE id=:idOfCase];
        System.debug(aCase.RecordType.DeveloperName);
        
		isDocDetalle = aCase.Con_referencia_a_factura__c=='Si';
        
		positions = [SELECT Producto__c, Unidad__c, Valor__c, Iva__c, Provincia__c
					FROM Posicion__c
					WHERE caso__c = :idOfCase];
		
		ProvinceValues = new Map<String, String>();
		for(Schema.PicklistEntry prov : Posicion__c.Provincia__c.getDescribe().getPicklistValues()) {
			ProvinceValues.put(prov.getValue(), prov.getLabel());
		}
		ProvinceValues.put(null, '');
	}
	
	public void setAll() {
		SetUnidadesToAll();
		SetValoresToAll();
	}
	
	public void SetValoresToAll() {
		for (Posicion__c pos : positions) {
            if(pos.Unidad__c!='%') {
				pos.valor__c = Posicion_Comun.valor__c/positions.size();
            } else {
                pos.valor__c = Posicion_Comun.valor__c;
            }
		}
	}
	
	public void SetUnidadesToAll() {
		for (Posicion__c pos : positions) {
			pos.unidad__c = Posicion_Comun.unidad__c;
		}
	}
	
	public PageReference Save() {

		for (Posicion__c pos : positions) {
			if(pos.Unidad__c == '%' && pos.Valor__c.round() != pos.Valor__c) {
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No se puede usar la unidad "%" con decimales.' ));
				return null;
			} else if ( (pos.Unidad__c == null || String.isBlank(pos.Unidad__c) ) && pos.Valor__c!=0) {
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Por favor, indicar unidad.' ));
				return null;
			}
            if (!isDocDetalle && (pos.Unidad__c == '%' && pos.Valor__c != 0 )) {
				ApexPages.AddMessage( new ApexPages.Message( ApexPages.Severity.ERROR, 'No se puede usar una unidad de porcentaje (%) '+
                                                            							'para una nota de credito no referenciada.' ));
				return null;
            } 
            
            if (isDocDetalle && (pos.Unidad__c != '%' && pos.Valor__c != 0 )) {
				ApexPages.AddMessage( new ApexPages.Message( ApexPages.Severity.ERROR, 'No se puede usar una unidad de pesos ($) '+
                                                            							'para una nota de credito referenciada.' ));
				return null;
            } 
            
		}
		
		update positions;
		PageReference pg = new PageReference('/' + idOfCase);
		pg.setRedirect(true);
		return pg;

	}
	
	public PageReference Cancel() {
		PageReference pg = new PageReference('/' + idOfCase);
		pg.setRedirect(true);
		return pg;
	}
}
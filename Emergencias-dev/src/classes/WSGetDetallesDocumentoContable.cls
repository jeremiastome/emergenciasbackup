public class WSGetDetallesDocumentoContable {
    public boolean hadError = false;
	public List<WSSAPDetallesDocumentoContable.XVBRP_element> result;
    
	private String prepareAuthorization() {
		Configuracion_SAP__c sapSettings = Configuracion_SAP__c.getInstance();
		if(String.isBlank(sapSettings.Url__c)) {
			return null;
		}
		return 'Basic ' + EncodingUtil.base64Encode(
			blob.valueOf(
				sapSettings.Usuario__c + ':' + sapSettings.Contrasena__c
			)
		);
	}    
	public void getForFactura(String factura) {
		WSSAPDetallesDocumentoContable.HTTPS_Port ws = new WSSAPDetallesDocumentoContable.HTTPS_Port();
		ws.inputHttpHeaders_x = new Map<String, String>();
		String auth = prepareAuthorization();
		if(auth == null) {
			hadError = true;
			return;
		}
        
		ws.inputHttpHeaders_x.put('authorization', auth);
		ws.inputHttpHeaders_x.put('Content-Type', 'text/xml;charset=UTF-8');
        
		WSSAPDetallesDocumentoContable.DT_Documentos_de_Facturacion_Response_In response = new WSSAPDetallesDocumentoContable.DT_Documentos_de_Facturacion_Response_In();
        WSSAPDetallesDocumentoContable.Consulta_element Consulta = new WSSAPDetallesDocumentoContable.Consulta_element();
    	consulta.VBELN = factura;
    
		try {            
			response = ws.SI_Documentos_de_Facturacion_Request(consulta);
		}
		catch (Exception e) {
			System.debug('Error loading');
			System.debug(e);
			hadError = true;
			return;
		}
        system.debug(response);
		if(response != null) {            
			result = new  List<WSSAPDetallesDocumentoContable.XVBRP_element> ();
            if(response.XVBRP!=null) {
                for (WSSAPDetallesDocumentoContable.XVBRP_element XVBRP : response.XVBRP) {
                    if (XVBRP.AUPOS.isnumeric()
                    &&Math.mod(integer.valueOf(XVBRP.AUPOS),100)==0
                        &&integer.valueOf(XVBRP.AUPOS)!=0) {
                        System.debug(XVBRP);
                        System.debug(XVBRP.AUPOS.isnumeric());
                        System.debug(Math.mod(integer.valueOf(XVBRP.AUPOS),100)==0);
                        System.debug(integer.valueOf(XVBRP.AUPOS)!=0);
                        result.add(XVBRP);
					}
                }
            }
            this.result = response.XVBRP;			
        } 
	}
}
public class Cuenta_ReenviarFacturaController {
		@AuraEnabled
		public static void resendFact(String facNum, String mail) {
            
			WSSAPReenvioFacturas.Parametros_element req = new WSSAPReenvioFacturas.Parametros_element();
			req.Nro_Factura_Sap = facNum;
			req.Mail_Alternativo = mail;
				
			WSSAPReenvioFacturas.HTTPS_Port ws = new WSSAPReenvioFacturas.HTTPS_Port();
			Configuracion_SAP__c sapSettings = Configuracion_SAP__c.getOrgDefaults();
			if(String.isBlank(sapSettings.Url__c)) {
					return;
			}
			String auth = EncodingUtil.base64Encode(
					blob.valueOf(
							sapSettings.Usuario__c + ':' + sapSettings.Contrasena__c
					)
			);
			ws.inputHttpHeaders_x = new Map<String,String>();
			ws.inputHttpHeaders_x.put('authorization', 'Basic ' + auth);
			WSSAPReenvioFacturas.Msg_element resp = ws.SI_OS_Reenvio_Facturas(req);   

                    
		}
}
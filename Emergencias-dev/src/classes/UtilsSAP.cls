public class UtilsSAP  {

	public static String convertirAFechaSAP(Date fecha) {
		
		return (fecha != null) ? convertirAFechaSAP(Datetime.newInstance(fecha, Time.newInstance(0, 0, 0, 0))) : null;
	}

	public static String convertirAFechaSAP(Datetime fecha) {
		
		return (fecha != null) ? fecha.format('yyyyMMdd') : null;
	}

	public static List<DocumentoContable> convertirADocumentosContablesSF(WSSAPDocumentosContables.LINEITEMS_element[] lineItems) {
		
		List<DocumentoContable> documentos = new List<DocumentoContable>();

		if (lineItems == null) return documentos;

		for (WSSAPDocumentosContables.LINEITEMS_element lineItem : lineItems) {
			
			documentos.add(new DocumentoContable(lineItem));
		}

		return documentos;
	}

	public static List<DetalleDocumentoContable> convertirADetallesDocumentoContableSF(WSSAPDetallesDocumentoContable.XVBRP_element[] details) {
		
		List<DetalleDocumentoContable> detalles = new List<DetalleDocumentoContable>();

		if (details == null) return detalles;

		for (WSSAPDetallesDocumentoContable.XVBRP_element detail : details) {
			
			detalles.add(new DetalleDocumentoContable(detail));
		}

		return detalles;
	}

	public static String obtenerHeaderAuth() {
		
		Configuracion_SAP__c sapSettings = Configuracion_SAP__c.getInstance();

		if (sapSettings == null) return null;

		return 'Basic ' + EncodingUtil.base64Encode(
			blob.valueOf(
				sapSettings.Usuario__c + ':' + sapSettings.Contrasena__c
			)
		);
	}
}
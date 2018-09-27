public class DocumentoContable  {

    private WSSAPDocumentosContables.LINEITEMS_element lineItem {get; set;}
    @AuraEnabled public DetalleDocumentoContable[] detalles {get; set;}
    @AuraEnabled public String mensaje {get; set;}
    
    // Datos
    @AuraEnabled public String tipo {get; set;}
    @AuraEnabled public String numeroDocumento {get; set;}
    @AuraEnabled public String importe {get; set;}
    @AuraEnabled public Date fechaDocumento {get; set;}
    @AuraEnabled public String medioDePago {get; set;}
    @AuraEnabled public String facturaAsoc {get; set;}
    @AuraEnabled public String PagoAFactura {get; set;}
    @AuraEnabled public String numDocumentoContable {get; set;}
    @AuraEnabled public decimal importeDecimal {get; set;}
    @AuraEnabled public String recordTypeId {get; set;}
    @AuraEnabled public String numeroDeContrato {get;set;}
    @AuraEnabled public String Contrato {get;set;}
    @AuraEnabled public boolean pagado{get;set;}
	@AuraEnabled public string LineItemToString {get;Set;}
    @AuraEnabled public string tipoDeContabilidad {get;set;}

    public DocumentoContable(WSSAPDocumentosContables.LINEITEMS_element lineItem) {
		
		this.LineItemToString = JSON.serialize(lineItem);
	

		this.lineItem = lineItem;

		detalles = new DetalleDocumentoContable[] {};

		tipo = '';
      
		if (lineItem.DOC_TYPE == 'DR' || lineItem.DOC_TYPE=='CI') {
      
			tipo = 'Factura';

		} else if (lineItem.DOC_TYPE == 'DG') {
      
			tipo = 'Nota de Credito';
      
		} else if (lineItem.DOC_TYPE == 'DW' || 
                   lineItem.DOC_TYPE == 'DZ' || 
                   lineItem.DOC_TYPE == 'DV' || 
                   lineItem.DOC_TYPE == 'DX') {
        
			tipo = 'Pago';
		}
      
		PagoAFactura= lineItem.CLR_DOC_NO;
		numDocumentoContable = lineItem.DOC_NO;
		importe = lineItem.AMOUNT;
        tipoDeContabilidad = lineItem.POST_KEY;
        

		if(tipo=='Factura') {
			numeroDocumento = lineItem.BILL_DOC;
		} else {
			numeroDocumento = lineItem.DOC_NO;
		}
		
		medioDePago = lineItem.PMNTTRMS;
		facturaAsoc = lineItem.REF_DOC_NO;
		numeroDeContrato = lineItem.NRO_CONTRATO;
        
		if (!String.isBlank(lineItem.DOC_DATE) && lineItem.DOC_DATE.length() == 8) {

			String dia = lineItem.DOC_DATE.substring(6);
			String mes = lineItem.DOC_DATE.substring(4, 6);
			String ano = lineItem.DOC_DATE.substring(0, 4);

			fechaDocumento = Date.valueOf(ano+'-'+mes+'-'+dia);
		  }

		String importeString = lineItem.AMOUNT;
		if (importeString!=null) {
			importeDecimal= (decimal.valueOf(importeString.trim())).setScale(2);
			} else {
				importeDecimal=0;
			}
    }
}
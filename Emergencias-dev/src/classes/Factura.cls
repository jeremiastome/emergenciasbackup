global class Factura {
    @AuraEnabled public DocumentoContable documento;
    @AuraEnabled public List<DocumentoContable> notasDeCredito;
    @AuraEnabled public List<DocumentoContable> pagos;
    
    public Factura (DocumentoContable documento,
    				List<DocumentoContable> notasDeCredito,
   					 List<DocumentoContable> pagos) {
        this.documento = documento;
        this.notasDeCredito = notasDeCredito;
        this.pagos = pagos;
    }
}
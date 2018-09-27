public class DetalleDocumentoContable  {
    
    private WSSAPDetallesDocumentoContable.XVBRP_element detail {get; set;}

    @AuraEnabled public String posicionFactura {get; set;}
    @AuraEnabled public String importe {get; set;}
    @AuraEnabled public Date fechaDetalle {get; set;}
    @AuraEnabled public String centroBenef {get; set;}
    @AuraEnabled public String materialIntroducido {get; set;}
    @AuraEnabled public String posicionVenta {get; set;}
    @AuraEnabled public String cantidad  {get; set;}
    @AuraEnabled public String importeTotal  {get; set;}
    @AuraEnabled public String bonificacion  {get; set;}
    @AuraEnabled public String periodoFacturacion {get; set;}
    @AuraEnabled public String DetalleSAP {get; set;}
    
    public DetalleDocumentoContable(WSSAPDetallesDocumentoContable.XVBRP_element detail) {
      
      this.detail = detail;
      cantidad = detail.FKIMG;
	  importeTotal = detail.SKFBP;
	  bonificacion = detail.BONBA;
	  DetalleSAP = detail.ARKTX;
      posicionVenta= detail.AUPOS;
      posicionFactura = detail.POSNR;
      importe = detail.NETWR;
      materialIntroducido = detail.MATWA;
      centroBenef = detail.PRCTR;

      if (!String.isBlank(detail.FBUDA) && detail.FBUDA.length() == 8) {

        String dia = detail.FBUDA.substring(6);
        String mes = detail.FBUDA.substring(4, 6);
        String ano = detail.FBUDA.substring(0, 4);

        fechaDetalle = Date.valueOf(ano+'-'+mes+'-'+dia);

		periodoFacturacion = mes+'/'+ano;
      }
    }
}
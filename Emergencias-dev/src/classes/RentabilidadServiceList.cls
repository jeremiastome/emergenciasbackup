public class RentabilidadServiceList extends WSEmergenciasResponse {
  @AuraEnabled public String Codigo {get; set;}
  @AuraEnabled public String Indicador {get; set;}
  @AuraEnabled public String Detalle {get; set;}

  public RentabilidadServiceList() {}
}
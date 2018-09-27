public class TicketCliente {

  public String InstanteCreacionSolicitud {get; set {
    
    if (String.isBlank(value)) return;
    InstanteSF = Datetime.newInstance(Long.valueOf(value.removeStart('/Date(').removeEnd('-0300)/')));
  }}

  @AuraEnabled public Datetime InstanteSF {get; set;}
  @AuraEnabled public String NumeroSolicitud {get; set;}
  @AuraEnabled public String NumeroTicket {get; set;}
  @AuraEnabled public String MotivoTicket {get; set;}
  @AuraEnabled public String ResolucionSolicitud {get; set;}
  @AuraEnabled public String VerDetalles {get {
    return 'http://ersitiosweb/gestiontickets/IniciarGestionTickets.aspx?solicitud=' + NumeroSolicitud + '&ticket=' + NumeroTicket;
  }}

  public TicketCliente() { }
}
public class WSEmergencias {

  public static Object realizarPedido(HttpRequest request, WSEmergenciasResponse respuesta, System.Type tipoRespuesta) {
    try {
      HttpResponse response = new Http().send(request);
      if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
        respuesta.mensaje = response.getStatus();
        return respuesta;
      }
      System.debug('*** respuesta: ' + response.getBody());
      return JSON.deserialize(response.getBody(), tipoRespuesta);

    } catch(Exception ex) {
      respuesta.mensaje = ex.getMessage();
      return respuesta;
    }
  }

  public static RentabilidadServiceList getRentabilidadServiceList(String[] keys) {

    RentabilidadServiceList indice = new RentabilidadServiceList();

    if (keys == null || keys.isEmpty()) {
      indice.mensaje = Label.WSEmergencias_FaltanClavesDeSistema;
      return indice;
    }

    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:Emergencias_Endpoint/GetRentabilidadServiceList');
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    request.setTimeout(120000);
    request.setBody(JSON.serialize(new WSEmergenciasRequest(keys)));

    return (RentabilidadServiceList) realizarPedido(request, indice, RentabilidadServiceList.class);
  }

  public static LegacySystemServiceList getLegacySystemServiceList(String[] keys) {
      return getLegacySystemServiceList(keys, null, null);
  }

  public static LegacySystemServiceList getLegacySystemServiceList(String[] keys, DateTime dateFrom, DateTime dateTo) {

    LegacySystemServiceList serviceList = new LegacySystemServiceList();

    // Validaciones
    if (keys == null || keys.isEmpty()) {
      serviceList.mensaje = Label.WSEmergencias_FaltanClavesDeSistema;
      return serviceList;
    }

    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:Emergencias_Endpoint/GetLegacySystemServiceList');
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    request.setTimeout(120000);
    String dateFromStr = '';
    String dateToStr = '';
    if(dateFrom != null) {
        dateFromStr = '/Date('+String.valueOf(dateFrom.getTime())+'-0300)/';
    }
    if(dateTo != null) {
        dateToStr = '/Date('+String.valueOf(dateTo.getTime())+'-0300)/';
    }
    String requestBody = WSEmergenciasRequestString.wsEmergenciasRequestToJSON(keys, dateFromStr, dateToStr);
    System.debug('*** requestBody: ' + requestBody);
    request.setBody(requestBody);
    return (LegacySystemServiceList) realizarPedido(request, serviceList, LegacySystemServiceList.class);
  }

  public static TicketsHistoricosCliente getTicketsServiceListResponse(String[] keys) {

    TicketsHistoricosCliente tickets = new TicketsHistoricosCliente();

    // Validaciones
    if (keys == null || keys.isEmpty()) {
      tickets.mensaje = Label.WSEmergencias_FaltanClavesDeSistema;
      return tickets;
    }

    // Armo el pedido
    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:Emergencias_Endpoint/GetTickestServiceList');
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    request.setTimeout(120000);
    request.setBody(JSON.serialize(new WSEmergenciasRequest(keys)));

    return (TicketsHistoricosCliente) realizarPedido(request, tickets, TicketsHistoricosCliente.class);
  }

  public class WSEmergenciasRequest {
    public String[] ListaClaveSistema {get; set;}

    public WSEmergenciasRequest(String[] keys) {
      ListaClaveSistema = keys;
    }
  }
}
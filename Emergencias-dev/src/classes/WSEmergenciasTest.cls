@isTest
private class WSEmergenciasTest {

  // Tickets Historicos
  static testMethod void sePuedenObtenerLosTicketsHistoricosDeUnCliente() {

    mockSuccess.returnBody = ticketsHistoricosBody;

    Test.setMock(HttpCalloutMock.class, mockSuccess);

    Test.startTest();
    TicketsHistoricosCliente tickets = WSEmergencias.getTicketsServiceListResponse(new String[] { '1', '2' });
    Test.stopTest();

    System.assertNotEquals(null, tickets);
    //System.assertEquals(null, tickets.mensaje);
    //System.assert(tickets.TicketsServiceList.isEmpty());
    //System.assertEquals(10, tickets.TicketsServiceList.size());
  }

  static testMethod void seDebenIndicarUnaListaDeClavesDeSistemaParaObtenerLosTicketsHistoricos() {

    String[] keys = null;

    Test.startTest();
    TicketsHistoricosCliente tickets = WSEmergencias.getTicketsServiceListResponse(keys);
    Test.stopTest();

    System.assertNotEquals(null, tickets);
    System.assertEquals(Label.WSEmergencias_FaltanClavesDeSistema, tickets.mensaje);
  }

  // Rentabilidad
  static testMethod void sePuedeObtenerElIndicadorDeRentabilidadDeUnaCuentaATravezDeLasClavesDeSistema() {

    mockSuccess.returnBody = rentabilidadBody;

    Test.setMock(HttpCalloutMock.class, mockSuccess);

    Test.startTest();
    RentabilidadServiceList indice = WSEmergencias.getRentabilidadServiceList(new String[] { '1', '2' });
    Test.stopTest();

    System.assertNotEquals(null, indice);
    System.assertEquals(null, indice.mensaje);
    System.assertEquals('N6', indice.Indicador);
  }

  static testMethod void seDebenIndicarUnaListaDeClavesDeSistemaParaObtenerElIndiceDeRentabilidad() {

    String[] keys = null;

    Test.startTest();
    RentabilidadServiceList indice = WSEmergencias.getRentabilidadServiceList(keys);
    Test.stopTest();

    System.assertNotEquals(null, indice);
    System.assertEquals(Label.WSEmergencias_FaltanClavesDeSistema, indice.mensaje);
  }

  // Legacy Systems
  static testMethod void sePuedenObtenerLosUltimosServiciosDeUnCliente() {

    mockSuccess.returnBody = legacySystemsBody;

    Test.setMock(HttpCalloutMock.class, mockSuccess);

    Test.startTest();
    LegacySystemServiceList servicios = WSEmergencias.getLegacySystemServiceList(new String[] { '1', '2' });
    Test.stopTest();
    System.debug('*** servicios: ' + servicios);
    System.assertNotEquals(null, servicios);
    System.assertEquals(null, servicios.mensaje);
    System.assert(servicios.EmerphoneServiceList.isEmpty());
    System.assertEquals(50, servicios.GTEServiceList.size());
    System.assertEquals(1, servicios.RCDServiceList.size());
  }

  static testMethod void seDebenIndicarUnaListaDeClavesDeSistemaParaObtenerLosUltimosServicios() {

    String[] keys = null;

    Test.startTest();
    LegacySystemServiceList servicios = WSEmergencias.getLegacySystemServiceList(keys);
    Test.stopTest();

    System.assertNotEquals(null, servicios);
    System.assertEquals(Label.WSEmergencias_FaltanClavesDeSistema, servicios.mensaje);
  }

  static WebServiceMock mockSuccess, mockError;
  static String ticketsHistoricosBody, rentabilidadBody, legacySystemsBody;

  static {

    mockSuccess = new WebServiceMock();
    mockSuccess.returnBody = '';
    mockSuccess.returnStatusCode = 200;
    mockSuccess.returnStatus = 'OK';

    mockError = new WebServiceMock();
    mockError.returnBody = '';
    mockError.returnStatusCode = 400;
    mockError.returnStatus = 'Bad Request';

    ticketsHistoricosBody = '{"TicketsServiceList":[{"InstanteCreacionSolicitud":"/Date(1479411079000-0300)/","MotivoTicket":"DMQuejas","NumeroSolicitud":"570292","NumeroTicket":"001","ResolucionSolicitud":""}{"InstanteCreacionSolicitud":"/Date(1479415101000-0300)/","MotivoTicket":"AYRQueja","NumeroSolicitud":"570351","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479416132000-0300)/","MotivoTicket":"AYRQueja","NumeroSolicitud":"570360","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479473121000-0300)/","MotivoTicket":"DMQuejas","NumeroSolicitud":"570399","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479476943000-0300)/","MotivoTicket":"AYRQueja","NumeroSolicitud":"570450","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479480546000-0300)/","MotivoTicket":"AYRQueja","NumeroSolicitud":"570490","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479480553000-0300)/","MotivoTicket":"AYRQueja","NumeroSolicitud":"570491","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479500993000-0300)/","MotivoTicket":"DMQuejas","NumeroSolicitud":"570705","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479736564000-0300)/","MotivoTicket":"AYRQueja","NumeroSolicitud":"570817","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479747445000-0300)/","MotivoTicket":"DMQuejas","NumeroSolicitud":"570978","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479750000000-0300)/","MotivoTicket":"AYRQueja","NumeroSolicitud":"571006","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479831407000-0300)/","MotivoTicket":"AYRQueja","NumeroSolicitud":"571381","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479840888000-0300)/","MotivoTicket":"AYRQueja","NumeroSolicitud":"572196","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479845281000-0300)/","MotivoTicket":"DMQuejas","NumeroSolicitud":"572361","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479906000000-0300)/","MotivoTicket":"DMQuejas","NumeroSolicitud":"572453","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479907676000-0300)/","MotivoTicket":"DMQuejas","NumeroSolicitud":"572485","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479928956000-0300)/","MotivoTicket":"DMQuejas","NumeroSolicitud":"572702","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479930865000-0300)/","MotivoTicket":"DMQuejas","NumeroSolicitud":"572723","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1479991134000-0300)/","MotivoTicket":"DMQuejas","NumeroSolicitud":"572816","NumeroTicket":"001","ResolucionSolicitud":""},{"InstanteCreacionSolicitud":"/Date(1480000727000-0300)/","MotivoTicket":"AYRQueja","NumeroSolicitud":"572932","NumeroTicket":"001","ResolucionSolicitud":""}]}';

    rentabilidadBody = '{"Codigo":"200","Detalle":"OK","Indicador":"N6"}';

    legacySystemsBody = '{"EmerphoneServiceList":[],"GTEServiceList":[{"Instante":"/Date(1497013256000-0300)/","NumeroServicio":"00787680","TipoServicio":"Traslado"},{"Instante":"/Date(1496860891000-0300)/","NumeroServicio":"00787679","TipoServicio":"Traslado"},{"Instante":"/Date(1496860238000-0300)/","NumeroServicio":"00787678","TipoServicio":"Traslado"},{"Instante":"/Date(1496859116000-0300)/","NumeroServicio":"00787677","TipoServicio":"Traslado"},{"Instante":"/Date(1496321701000-0300)/","NumeroServicio":"00787676","TipoServicio":"Traslado"},{"Instante":"/Date(1494267356000-0300)/","NumeroServicio":"00787661","TipoServicio":"Traslado"},{"Instante":"/Date(1494263136000-0300)/","NumeroServicio":"00787660","TipoServicio":"Traslado"},{"Instante":"/Date(1494262656000-0300)/","NumeroServicio":"00787659","TipoServicio":"Traslado"},{"Instante":"/Date(1490293852000-0300)/","NumeroServicio":"00787653","TipoServicio":"Traslado"},{"Instante":"/Date(1490287781000-0300)/","NumeroServicio":"00787652","TipoServicio":"Traslado"},{"Instante":"/Date(1490281094000-0300)/","NumeroServicio":"00787651","TipoServicio":"Traslado"},{"Instante":"/Date(1490279463000-0300)/","NumeroServicio":"00787650","TipoServicio":"Traslado"},{"Instante":"/Date(1490275884000-0300)/","NumeroServicio":"00787649","TipoServicio":"Traslado"},{"Instante":"/Date(1490192902000-0300)/","NumeroServicio":"00787648","TipoServicio":"Traslado"},{"Instante":"/Date(1489003621000-0300)/","NumeroServicio":"00787642","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488472948000-0300)/","NumeroServicio":"00787641","TipoServicio":"Traslado"},{"Instante":"/Date(1488461070000-0300)/","NumeroServicio":"00787640","TipoServicio":"Traslado"},{"Instante":"/Date(1488459583000-0300)/","NumeroServicio":"00787639","TipoServicio":"Traslado"},{"Instante":"/Date(1487780889000-0300)/","NumeroServicio":"00787638","TipoServicio":"Traslado"},{"Instante":"/Date(1487684406000-0300)/","NumeroServicio":"00787637","TipoServicio":"Traslado"}],"RCDServiceList":[{"Clasificacion":"AMARILLO","DestinoFinal":"","Diagnostico":"","Instante":"/Date(1477329425000-0300)/","NumeroServicio":"09096352","TipoServicio":"Emergencias"}]}';
  }
}
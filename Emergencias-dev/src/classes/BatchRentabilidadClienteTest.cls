@isTest 
private class BatchRentabilidadClienteTest {

  static testMethod void noSeTieneEnCuentaLosClientesSinContratos() {
    
    Test.setMock(HttpCalloutMock.class, mockSuccess);

    Test.startTest();
    Database.executeBatch(new BatchRentabilidadCliente(), 10);
    Test.stopTest();

    System.assertEquals(
      null,
      [SELECT Valor_de_rentabilidad__c FROM Account WHERE Id = :clienteSinContrato.Id].Valor_de_rentabilidad__c
    );
  }

  static testMethod void noSeTieneEnCuentaLosContratosQueNoEstenActivosOEnBaja() {
    
    Test.setMock(HttpCalloutMock.class, mockSuccess);

    Test.startTest();
    Database.executeBatch(new BatchRentabilidadCliente(), 10);
    Test.stopTest();

    System.assertEquals(
      null,
      [SELECT Valor_de_rentabilidad__c FROM Account WHERE Id = :clienteConContratoPendiente.Id].Valor_de_rentabilidad__c
    );
  }

  static testMethod void seActualizaElIndicadorDeRentabilidadSegunLaRespuestaDelServicio() {
  
    Test.setMock(HttpCalloutMock.class, mockSuccess);

    Test.startTest();
    Database.executeBatch(new BatchRentabilidadCliente(), 10);
    Test.stopTest();

    System.assertEquals(
      'N6',
      [SELECT Valor_de_rentabilidad__c FROM Account WHERE Id = :clienteConContrato.Id].Valor_de_rentabilidad__c
    );
  }

  static testMethod void siSeProduceUnErrorAlLlamarAlServicioNoSeActualizaLaCuenta() {
    
    Test.setMock(HttpCalloutMock.class, mockError);
    
    Test.startTest();
    Database.executeBatch(new BatchRentabilidadCliente(), 10);
    Test.stopTest();

    System.assertEquals(
      null,
      [SELECT Valor_de_rentabilidad__c FROM Account WHERE Id = :clienteConContrato.Id].Valor_de_rentabilidad__c
    );
  }

  static Account clienteConContrato, clienteSinContrato, clienteConContratoPendiente;
  static WebServiceMock mockSuccess, mockError;

  static {
    clienteConContrato = Build.anAccount().build();
    clienteSinContrato = Build.anAccount().build();
    clienteConContratoPendiente = Build.anAccount().build();
    insert new Account[] { clienteConContrato, clienteSinContrato, clienteConContratoPendiente };

    Contrato__c contratoActivo = Build.aContract()
      .withActiveStatus()
      .forAccount(clienteConContrato)
      .withUniqueNumber('V000001')
      .build();
    Contrato__c contratoPendiente = Build.aContract()
      .withPendingStatus()
      .forAccount(clienteConContratoPendiente)
      .withUniqueNumber('V000002')
      .build();
    insert new Contrato__c[] { contratoActivo, contratoPendiente };

    mockSuccess = new WebServiceMock();
    mockSuccess.returnBody = '{"Codigo":"200","Detalle":"OK","Indicador":"N6"}';
    mockSuccess.returnStatusCode = 200;
    mockSuccess.returnStatus = 'OK';

    mockError = new WebServiceMock();
    mockError.returnBody = '';
    mockError.returnStatusCode = 400;
    mockError.returnStatus = 'Bad Request';
  }
}
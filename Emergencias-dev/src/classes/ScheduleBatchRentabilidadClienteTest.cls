@isTest
private class ScheduleBatchRentabilidadClienteTest {

  static testMethod void SePuedeProgramarLaActualizacionDeObjetivos() {

    String CRON_EXP = '0 0 0 * * ? *';

    Datetime ahora = Datetime.newInstance(Date.today(), Time.newInstance(0,0,0,0));
    Datetime proximaEjecucion = ahora.addDays(1);

    Test.startTest();
    String jobId = System.schedule('testScheduledApex',
      CRON_EXP,
      new ScheduleBatchRentabilidadCliente());

    CronTrigger ct = [
      SELECT Id, CronExpression, TimesTriggered, NextFireTime
      FROM CronTrigger
      WHERE id = :jobId
    ];

    System.assertEquals(CRON_EXP,
      ct.CronExpression);
    System.assertEquals(0, ct.TimesTriggered);

    // Verificar proxima ejecucion
    System.assertEquals(
      proximaEjecucion.format('yyyy-MM-dd HH:mm:ss'),
      String.valueOf(ct.NextFireTime)
    );
    Test.stopTest();
  }
}
global class ScheduleBatchRentabilidadCliente implements Schedulable {

  global void execute(SchedulableContext sc) {
    BatchRentabilidadCliente actualizador = new BatchRentabilidadCliente();

    Batch_Rentabilidad__c config = Batch_Rentabilidad__c.getOrgDefaults();
    Integer batchSize = (config != null && config.Batch_size__c != null) ? config.Batch_size__c.intValue() : 10;

    // Lotes de a X cuentas
    Database.executeBatch(actualizador, batchSize);
  }
}
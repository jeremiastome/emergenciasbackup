global class BajaContratosScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        BajaContratosBatch batch = new BajaContratosBatch();
        Database.executeBatch(batch, 1);
    }
}
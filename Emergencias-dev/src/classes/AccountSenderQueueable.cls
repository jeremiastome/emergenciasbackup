public class AccountSenderQueueable implements Queueable, Database.AllowsCallouts {
    Id accountId;
    String operationType;
    
    public AccountSenderQueueable(Id aId, String ot){
        accountId = aId;
        operationType = ot;
    }
    
    public void execute(QueueableContext context) {
        WSAccountToSAP.sendAccountToSAP(accountId, operationType);
    }
}
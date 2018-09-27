public class ContactSenderQueueable implements Queueable, Database.AllowsCallouts {
	Id contactId;
    String operationType;
    
    public ContactSenderQueueable(Id cId, String ot){
        contactId = cId;
        operationType = ot;
    }
    
    public void execute(QueueableContext context) {
        WSAccountToSAP.sendContactToSAP(contactId, operationType);
    }
}
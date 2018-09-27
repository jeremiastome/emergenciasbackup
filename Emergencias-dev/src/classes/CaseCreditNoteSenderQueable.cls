public class CaseCreditNoteSenderQueable implements Queueable, Database.AllowsCallouts {
    Id caseId;
    
    public CaseCreditNoteSenderQueable(Id cId){
        caseId = cId;
    }
    
    public void execute(QueueableContext context) {
        WSCreditNoteToSAP.sendCreditNote(caseId);
    }
}
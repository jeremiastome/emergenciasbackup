public class ContractSenderQueable implements Queueable, Database.AllowsCallouts {
    Id contractId;
    String operationType;
    
    public ContractSenderQueable(Id cId, String ot){
        contractId = cId;
        operationType = ot;
    }
    
    public void execute(QueueableContext context) {
		ContratosPedidos_EnviarSAP.sendContract(contractId, operationType);
    }
}
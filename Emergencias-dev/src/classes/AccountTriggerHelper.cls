public class AccountTriggerHelper {
	public static void sendAccountsToSAP(Set<Id> accountIds, String operationType) {
		for(Id accId : accountIds) {
            sendAccountToSAP(accId, operationType);
		}
	}
	
	public static void sendAccountToSAP(Id accountId, String operationType) {
        //AccountTriggerHelper.sendAccountsToSAPFuture(accId, operationType);
        AccountSenderQueueable asq = new AccountSenderQueueable(accountId, operationType);
        System.enqueueJob(asq);
	}
			
	//algorithm by https://virushardrive.wordpress.com/2010/04/04/algoritmo-de-cuil-cuit/, code by Grigoriy Zatravkin	
	//Se empieza a utilzar XappiaUtils
    /*
     public static string GenerateCUITFromDNI(string dni, boolean isMale){
        if (!dni.isNumeric()||dni.length()!=8)
			return '';
					
		string XY;
		if (isMale)
			XY='20';
		else
			XY='27';

		string XYWithDNI = XY+dni;
		Integer[] serie = new Integer[]{5, 4, 3, 2, 7, 6, 5, 4, 3, 2};		
        Integer aux = 0;                            
        for (integer i=0; i<10; i++){
			string simbol = XYWithDNI.substring(i,i+1);                                			
			aux += integer.valueOf(simbol) * serie[i];			
		}		
		aux = (Math.mod(aux , 11));		
		//ultimo digito (validador)
		string Z = '';
		if (aux==0)
		{
			Z='0';
		}
		else if (aux==1)
		{			
			XY='23';
			if (isMale)
			{
				Z='9';				
			} else 
			{
				Z='4';
			}			
		}
		else
		{
			Z = String.valueOf(11-aux);
		}		
		return XY+dni+Z;
    }*/

	@future(callout=true)
    public static void sendAccountsToSAPFuture(Id accountId, String operationType) {
        WSAccountToSAP.sendAccountToSAP(accountId, operationType);
    }
    
    /*
	@future(callout=true)
	public static void sendAccountsToSAP(Set<Id> accountIds, String operationType) {
		for(Id accId : accountIds) {
			WSAccountToSAP.sendAccountToSAP(accId, operationType);
		}
	}
	*/
}
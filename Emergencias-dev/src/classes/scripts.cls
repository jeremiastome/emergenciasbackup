@isTest
public class scripts {
/*
List<Contrato__c> cons = [SELECT Id FROM Contrato__c WHERE Cliente__c IN (SELECT Id FROM Account WHERE Es_Cliente__c = true ORDER BY Id LIMIT 20)];
for(Contrato__c con : cons){
    ContratoTriggerHelper.sendContractToSAP(con.Id, 'M');
	//ContratosPedidos_EnviarSAP.sendContract(con.Id, 'M');
}

WSAccountToSAP.sendAccountToSAP('0010v0000072N9SAAU', 'M');
CUIL_CUIT__c IN ('30522763922','30683032227','30696170580')
List<Account> accs = [SELECT Id FROM Account WHERE Es_Cliente__c = true ORDER BY Id LIMIT 20];
Set<Id> accIds = new Set<Id>();
for(Account acc : accs){
    accIds.add(acc.Id);
}
AccountTriggerHelper.sendAccountsToSAP(accIds, 'M');

Contrato__c con = [SELECT Tarjeta_sin_cifrar__c FROM Contrato__c WHERE Id = 'a010v000001GjIQ'];
system.debug(con.Tarjeta_sin_cifrar__c);

List<Account> accs = [SELECT Id, Dado_de_alta__c, Sexo__c, Salutation FROM Account WHERE Es_Cliente__c = true 
                      AND Dado_de_alta__c = false AND IsPersonAccount = true ORDER BY CreatedDate LIMIT 20];
for(Account acc : accs){
}
update accs;

List<Account> accs = [SELECT Id, Dado_de_alta__c, Sexo__c, Salutation FROM Account WHERE Es_Cliente__c = true 
                      AND Dado_de_alta__c = false AND IsPersonAccount = false ORDER BY CreatedDate LIMIT 20];
for(Account acc : accs){
    acc.Dado_de_alta__c = true;
}
update accs;

List<Account> accs = [SELECT Id, Dado_de_alta__c FROM Account WHERE Es_Cliente__c = true AND Dado_de_alta__c = true ORDER BY CreatedDate];
for(Account acc : accs){
    acc.Dado_de_alta__c = false;
}
update accs;


WSAccountToSAP.sendAccountToSAP('0010v0000072Jjw', 'A');
ContratosPedidos_EnviarSAP.sendContract('a010v000001GbHr', 'A');

List<Account> accs = [SELECT Id, Dado_de_alta__c, Sexo__c, Salutation FROM Account WHERE Es_Cliente__c = true 
                      AND Dado_de_alta__c = false AND IsPersonAccount = true ORDER BY CreatedDate LIMIT 20];
for(Account acc : accs){
    if(acc.Sexo__c == 'Masculino'){
        acc.Salutation = '0002';
    }
    else if(acc.Sexo__c == 'Femenino'){
        acc.Salutation = '0001';
    }
    else{
        acc.Salutation = '0003';
    }
    acc.Dado_de_alta__c = true;
}
update accs;

List<Account> accs = [SELECT Id, Dado_de_alta__c FROM Account WHERE Es_Cliente__c = true 
                      AND Dado_de_alta__c = false AND IsPersonAccount = false ORDER BY CreatedDate LIMIT 5];
for(Account acc : accs){
    acc.Dado_de_alta__c = true;
}
update accs;

List<Account> accs = [SELECT Id, Dado_de_alta__c FROM Account WHERE Es_Cliente__c = true AND Dado_de_alta__c = true ORDER BY CreatedDate OFFSET 28];
for(Account acc : accs){
    acc.Dado_de_alta__c = false;
}
update accs;

List<Account> accs = [SELECT Id, CUIL_CUIT__c, N_mero_nico_de_Cliente__c FROM Account WHERE Es_Cliente__c = true AND CUIL_CUIT__c != null];
for(Account acc : accs){
    String aux = acc.CUIL_CUIT__c.replace('-','');
    acc.N_mero_nico_de_Cliente__c = aux.Left(aux.Length()-1);
}
update accs;


system.debug(System.Limits.getLimitAsyncCalls());
*/
}
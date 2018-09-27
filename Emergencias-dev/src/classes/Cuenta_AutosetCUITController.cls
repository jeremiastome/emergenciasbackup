public class Cuenta_AutosetCUITController {    
	@AuraEnabled
	public static string AutosetCUITToAcc(Id accountId) {        		        
        Account acc = [select id, cuil_cuit__c, genero__c, numero_de_documento__c from account where id = :accountId];
        if (acc.Genero__c!='Masculino'&& acc.Genero__c!='Femenino'&&string.isBlank(acc.Numero_de_Documento__c))
            return 'Por favor, ingrese sexo y documento de la persona';
        if (acc.Genero__c!='Masculino'&& acc.Genero__c!='Femenino'){
			return 'Por favor, ingrese el sexo de la persona';
        }
        if (string.isBlank(acc.numero_de_documento__c))
            return 'Por favor, ingrese el documento de la persona';
        if (!acc.Numero_de_Documento__c.isNumeric()||acc.Numero_de_Documento__c.length()<7||acc.Numero_de_Documento__c.length()>8)
            return 'El Documento esta ingresado en formato invalido';
        string cuit = XappiaHelper.GenerateCUITFromDNI(acc.Numero_de_Documento__c,acc.genero__c=='Masculino');
		if (cuit=='')
			return 'Hubo un error con la generacion del CUIT';
        integer countSameCuit = [select count() from account where cuil_cuit__c=:cuit];
        if (countSameCuit==0)
        {
        	acc.cuil_cuit__c = cuit;
        	update acc;
            return '';
        }
        else
        {
            return 'No se puede guardar la cuenta con cuit '+cuit+': ya existe una cuenta con mismo numero';
        }
	}
}
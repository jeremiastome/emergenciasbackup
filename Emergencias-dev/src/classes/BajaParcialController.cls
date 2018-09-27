public class BajaParcialController {
    public String titularBuscar {get;set;}
    public String beneficiarioBuscar {get;set;}
    
    public List<Titular__c> titulares {get;set;}
    public List<Titular__c> titularesBaja {get;set;}
    
    public List<Beneficiario__c> beneficiarios {get;set;}
    public List<Beneficiario__c> beneficiariosBaja {get;set;}
    
    public void searchTitular (){
        String strFind = String.escapeSingleQuotes(titularBuscar);
        system.debug(ContractId);
        system.debug(strFind);
        String query = 'SELECT Id, Name, Cliente__r.Name FROM Titular__c ' +
                       'WHERE Contrato__c = \'' + ContractId + '\' AND Cliente__r.Name LIKE \'%' + strFind + '%\'';
        system.debug(query);
        titulares = Database.query(query);
        for(Integer i=0; i<titulares.size(); i++){
            for(Titular__c bajaTit : titularesBaja){
                if(titulares[i].Id == bajaTit.Id){
                    titulares.remove(i);
                    break;
                }
            }
        }
    }
    
    public void searchBeneficiario (){
        String strFind = String.escapeSingleQuotes(beneficiarioBuscar);
        system.debug(ContractId);
        system.debug(strFind);
        String query = 'SELECT Id, Nombre__c, Apellido__c, Calle__c, Altura__c FROM Beneficiario__c WHERE Contrato__c = \'' + ContractId + '\' AND ' + 
            		   '(Nombre__c LIKE \'%' + strFind + '%\' OR Apellido__c LIKE \'%' + strFind + '%\' OR Calle__c LIKE \'%' + strFind + '%\' OR Patente_del_auto__c LIKE \'%' + strFind + '%\')';
        system.debug(query);
        beneficiarios = Database.query(query);
        for(Integer i=0; i<beneficiarios.size(); i++){
            for(Beneficiario__c bajaBen : beneficiariosBaja){
                if(beneficiarios[i].Id == bajaBen.Id){
                    beneficiarios.remove(i);
                    break;
                }
            }
        }
    }
    
    public void bajaTitular (){
        String titularId = Apexpages.currentPage().getParameters().get('idTitular');
        if(titularId != null){
            for(Integer i=0; i<titulares.size(); i++){
                if(titulares[i].Id == titularId){
                    titularesBaja.add(titulares[i]);
                    titulares.remove(i);
                    break;
                }
            }
        }
    }
    
    public void bajaBeneficiario (){
        String beneficiarioId = Apexpages.currentPage().getParameters().get('idBeneficiario');
        if(beneficiarioId != null){
            for(Integer i=0; i<beneficiarios.size(); i++){
                if(beneficiarios[i].Id == beneficiarioId){
                    beneficiariosBaja.add(beneficiarios[i]);
                    beneficiarios.remove(i);
                    break;
                }
            }
        }
    }
    
    public void bajaAllTitulares (){
        titularesBaja.addAll(titulares);
        titulares.clear();
    }
    
    public void bajaAllBeneficiarios (){
        beneficiariosBaja.addAll(beneficiarios);
        beneficiarios.clear();
    }
    
    public void cancelBajaTitular (){
        String titularId = Apexpages.currentPage().getParameters().get('idTitular');
        if(titularId != null){
            for(Integer i=0; i<titularesBaja.size(); i++){
                if(titularesBaja[i].Id == titularId){
                    titularesBaja.remove(i);
                    break;
                }
            }
        }
    }
    
    public void cancelBajaBeneficiario (){
        String beneficiarioId = Apexpages.currentPage().getParameters().get('idBeneficiario');
        if(beneficiarioId != null){
            for(Integer i=0; i<beneficiariosBaja.size(); i++){
                if(beneficiariosBaja[i].Id == beneficiarioId){
                    beneficiariosBaja.remove(i);
                    break;
                }
            }
        }
    }
    
    public void cancelBajaAllTitulares (){
        titularesBaja.clear();
    }
    
    public void cancelBajaAllBeneficiarios (){
        beneficiariosBaja.clear();
    }
    
	public List<Beneficiario__c> Recipients {get; set;}
    public Id CaseId {get; set;}
	public Id ContractId {get; set;}
	public String ReturnRecord {get; set;}
	
	public BajaParcialController() {
        CaseId = ApexPages.currentPage().getParameters().get('caseId');
        ContractId = ApexPages.currentPage().getParameters().get('contractId');		

        titulares = new List<Titular__c>();
        titularesBaja = new List<Titular__c>();

        beneficiarios = new List<Beneficiario__c>();
        beneficiariosBaja = new List<Beneficiario__c>();
        
        Set<Id> titIds = new Set<Id>();
        Set<Id> benIds = new Set<Id>();
        List<Baja_Parcial__c> bajas = [SELECT Id, Titular__c, Beneficiario__c FROM Baja_Parcial__c WHERE Caso__c = :CaseId];
        for(Baja_Parcial__c baja : bajas){
            if(baja.Titular__c != null){
                titIds.add(baja.Titular__c);
            }
            if(baja.Beneficiario__c != null){
                benIds.add(baja.Beneficiario__c);
            }
        }
        titularesBaja = [SELECT Id, Name, Cliente__r.Name FROM Titular__c WHERE Id IN :titIds];
        beneficiariosBaja = [SELECT Id, Nombre__c, Apellido__c, Calle__c, Altura__c FROM Beneficiario__c WHERE Id IN :benIds];
	}
    
    public PageReference save(){
        List<Baja_Parcial__c> bajas = new List<Baja_Parcial__c>();
        for(Titular__c t : titularesBaja){
            Baja_Parcial__c b = new Baja_Parcial__c();
            b.Caso__c = CaseId;
            b.Titular__c = t.Id;
            bajas.add(b);
        }
        for(Beneficiario__c ben : beneficiariosBaja){
            Baja_Parcial__c b = new Baja_Parcial__c();
            b.Caso__c = CaseId;
            b.Beneficiario__c = ben.Id;
            bajas.add(b);
        }
        delete [SELECT Id FROM Baja_Parcial__c WHERE Caso__c = :CaseId];
        insert bajas;
        
        return new PageReference('/' + CaseId);
    }
}
public class TestRedirect {
    public PageReference redirect(){
        //https://c.na73.visual.force.com/apex/TestRedirect?ANI=
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String tel = ApexPages.currentPage().getParameters().get('ANI');
        if (tel != null){
        	List<Account> accs = [SELECT Id FROM Account WHERE Phone = :tel];
            if(accs.size() > 0){
        		return new PageReference(baseUrl + '/one/one.app#/sObject/' + accs[0].Id + '/view');                
            }
        }		
        return new PageReference(baseUrl + '/one/one.app#/sObject/Account/list?filterName=Recent');
    }
}
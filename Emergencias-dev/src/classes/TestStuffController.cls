public class TestStuffController {
	public Beneficiario__c recipient {get; set;}
	
	public TestStuffController() {
		recipient = new Beneficiario__c();
	}
}
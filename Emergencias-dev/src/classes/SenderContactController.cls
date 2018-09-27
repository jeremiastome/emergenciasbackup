public class SenderContactController  {
	private Contact contacto; 

	public SenderContactController() {
		contacto = [SELECT Id
					FROM Contact 
					WHERE Id=:ApexPages.currentPage().getParameters().get('id')];

	}

	public PageReference send() {
		ContactTriggerHelper.sendContactToSAP(contacto, 'A');

		return null;
	}	
	public PageReference sendM() { ContactTriggerHelper.sendContactToSAP(contacto, 'M');  return null; }
}
public class ContactTriggerHelper {
	public static void sendContactToSAP(Contact c, String operationType) {
		ContactSenderQueueable csq = new ContactSenderQueueable(c.Id, operationType);
		System.enqueueJob(csq);
	}
}
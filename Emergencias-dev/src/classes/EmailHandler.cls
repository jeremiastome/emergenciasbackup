global class EmailHandler implements Messaging.InboundEmailHandler{
	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
		Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

		List<Account> accountsWithFromEmail = [
			SELECT Id, Correo_Electronico__c, PersonContactId
			FROM Account
			WHERE Correo_Electronico__c = :email.fromAddress
		];

		List<EmailMessage> emailsToInsert = new List<EmailMessage>();
		List<Attachment> attachmentsToInsert = new List<Attachment>();

		if (!accountsWithFromEmail.isEmpty()) {
			for(Account acc : accountsWithFromEmail) {
				emailsToInsert.add(buildEmailMessage(email, acc.id));
			}
			insert emailsToInsert;

			for(EmailMessage emailMessage : emailsToInsert) {
				attachmentsToInsert.addAll(buildEmailAttachments(email, emailMessage.Id));
			}
			if(!attachmentsToInsert.isEmpty()) {
				insert attachmentsToInsert;
			}
		}
        return result;
	}

	public static EmailMessage buildEmailMessage(Messaging.InboundEmail email, Id accountId) {
		EmailMessage anEmail = new EmailMessage();
		anEmail.FromAddress = email.fromAddress;
		anEmail.ToAddress = email.toAddresses[0];
		anEmail.Subject = email.subject;
		anEmail.HtmlBody = email.htmlBody;
		anEmail.TextBody = email.plainTextBody;
		anEmail.FromName = email.fromName;
		anEmail.Headers = String.valueOf(email.headers);
		anEmail.MessageDate = Datetime.now();
		anEmail.Incoming = true;
		anEmail.RelatedToId = accountId;
		return anEmail;
	}

	public static List<Attachment> buildEmailAttachments(Messaging.InboundEmail email, Id emailMessageId) {
		List<Attachment> attachmentsToInsert = new List<Attachment>();
		if(email.textAttachments != null) {
			for (Messaging.Inboundemail.TextAttachment att : email.textAttachments) {
				Attachment anAttachment = new Attachment();
				anAttachment.Name = att.fileName;
				anAttachment.Body = Blob.valueOf(att.body);
				anAttachment.ParentId = emailMessageId;
				attachmentsToInsert.add(anAttachment);
			}
		}
		if(email.binaryAttachments != null) {
			for (Messaging.Inboundemail.BinaryAttachment bAtt : email.binaryAttachments) {
				Attachment anAttachment = new Attachment();
				anAttachment.Name = bAtt.fileName;
				anAttachment.Body = bAtt.body;
				anAttachment.ParentId = emailMessageId;
				attachmentsToInsert.add(anAttachment);
			}
		}
		return attachmentsToInsert;
	}
}
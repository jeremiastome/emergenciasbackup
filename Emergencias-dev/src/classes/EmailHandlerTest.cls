@isTest
public class EmailHandlerTest {
	public static testmethod void anInboundEmailShouldCreateAnEmailMessageIfAnAccountWithTheSameEmailExists() {
		EmailHandler aHandler = new EmailHandler();
		Messaging.InboundEmailResult  result = aHandler.handleInboundEmail(anEmail,new Messaging.InboundEnvelope());

		List<EmailMessage> insertedEmails = [
			SELECT Id, FromAddress,FromName, ToAddress, Subject, TextBody
			FROM EmailMessage
			WHERE Subject = : anEmail.subject
		];

		System.assert(result.success);
		System.assertEquals(1, insertedEmails.size());
		System.assertEquals(anEmail.fromAddress,insertedEmails[0].FromAddress);
		System.assertEquals(anEmail.toAddresses[0],insertedEmails[0].ToAddress);
		System.assertEquals(anEmail.plainTextBody,insertedEmails[0].TextBody);

	}

	public static testmethod void anInboundEmailWillNotCreateAnEmailMessageIfThereIsNoAccountWithTheSameEmail() {
		anEmail.fromAddress = 'anotheremail@test.com';
		EmailHandler aHandler = new EmailHandler();

		Messaging.InboundEmailResult  result = aHandler.handleInboundEmail(anEmail,new Messaging.InboundEnvelope());
		List<EmailMessage> insertedEmails = [
			SELECT Id, FromAddress,FromName, ToAddress, Subject, TextBody
			FROM EmailMessage
			WHERE Subject = : anEmail.subject
		];

		System.assert(result.success);
		System.assertEquals(0, insertedEmails.size());

	}

	public static testmethod void whenAnEmailMessageIsCreatedByTheEmailHandlerItShouldBeRelatedToAnAccountWithThatEmail() {
		EmailHandler aHandler = new EmailHandler();
		Messaging.InboundEmailResult  result = aHandler.handleInboundEmail(anEmail,new Messaging.InboundEnvelope());

		List<EmailMessage> insertedEmails = [
			SELECT Id, FromAddress, RelatedToId, ToAddress, Subject, TextBody
			FROM EmailMessage
			WHERE RelatedToId = : anAccount.Id
		];

		System.assert(result.success);
		System.assertEquals(1,insertedEmails.size());
	}

	public static testmethod void whenAnInboundEmailHasAttachmentsTheyShouldBeCreatedToo(){
		List<Messaging.InboundEmail.BinaryAttachment> bAtts = new List<Messaging.InboundEmail.BinaryAttachment>();
		List<Messaging.InboundEmail.TextAttachment> tAtts = new List<Messaging.InboundEmail.TextAttachment>();

		Messaging.InboundEmail.BinaryAttachment aBinaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
		aBinaryAttachment.fileName = 'myfile.png';
		aBinaryAttachment.body = Blob.valueOf('this is the body');
		bAtts.add(aBinaryAttachment);

		Messaging.InboundEmail.TextAttachment aTextAttachment = new Messaging.InboundEmail.TextAttachment();
		aTextAttachment.fileName = 'myTextFile.txt';
		aTextAttachment.body = 'This is the body';
		tAtts.add(aTextAttachment);

		anEmail.binaryAttachments = bAtts;
		anEmail.textAttachments = tAtts;

		EmailHandler aHandler = new EmailHandler();
		Messaging.InboundEmailResult  result = aHandler.handleInboundEmail(anEmail,new Messaging.InboundEnvelope());

		List<EmailMessage> insertedEmails = [
			SELECT Id, FromAddress, RelatedToId, ToAddress, Subject, TextBody
			FROM EmailMessage
			WHERE RelatedToId = : anAccount.Id
		];

		List<Attachment> insertedAttachment = [
			SELECT Id
			FROM Attachment
			WHERE ParentId = :insertedEmails[0].id
		];

		System.assert(result.success);
		System.assertEquals(1,insertedEmails.size());
		System.assertEquals(2, insertedAttachment.size());
	}

	public static testmethod void whenManyAccountsHaveTheSameEmailAddressTheEmailShouldBeRelatedBoth(){
		Account anotherAccount = Build.anAccount()
								.withEmail('emailtest@test.com')
								.build();
		insert anotherAccount;

		EmailHandler aHandler = new EmailHandler();
		aHandler.handleInboundEmail(anEmail,new Messaging.InboundEnvelope());

		List<EmailMessage> insertedEmails = [
			SELECT Id, FromAddress,FromName, RelatedToId, ToAddress, Subject, TextBody
			FROM EmailMessage
			WHERE Subject = : anEmail.subject
		];

		System.assert(!insertedEmails.isEmpty());
		Set<Id> relatedAccounts = new Set<Id>();
		for(EmailMessage em : insertedEmails){
			relatedAccounts.add(em.RelatedToId);
		}

		System.assertEquals(2, insertedEmails.size());
		System.assert(relatedAccounts.contains(anAccount.Id));
		System.assert(relatedAccounts.contains(anotherAccount.Id));
	}

	public static testmethod void whenManyAccountsHaveTheSameEmailAddressAndTheEmailHasAttachmentsTheyShouldBeReplicatedForEveryAccount() {
		Account anotherAccount = Build.anAccount()
								.withEmail('emailtest@test.com')
								.build();
		insert anotherAccount;

		List<Messaging.InboundEmail.BinaryAttachment> binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>();
		List<Messaging.InboundEmail.TextAttachment> textAttachments = new List<Messaging.InboundEmail.TextAttachment>();

		Messaging.InboundEmail.TextAttachment aTextAttachment = new Messaging.InboundEmail.TextAttachment();
		aTextAttachment.fileName = 'myTextFile.txt';
		aTextAttachment.body = 'This is the body';
		textAttachments.add(aTextAttachment);

		Messaging.InboundEmail.BinaryAttachment aBinaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
		aBinaryAttachment.fileName = 'myfile.png';
		aBinaryAttachment.body = Blob.valueOf('this is the body');
		binaryAttachments.add(aBinaryAttachment);

		anEmail.binaryAttachments = binaryAttachments;
		anEmail.textAttachments = textAttachments;

		EmailHandler aHandler = new EmailHandler();
		aHandler.handleInboundEmail(anEmail, new Messaging.InboundEnvelope());

		List<EmailMessage> insertedEmails = [
			SELECT Id, FromAddress, RelatedToId, ToAddress, Subject, TextBody
			FROM EmailMessage
			WHERE Subject = : anEmail.subject
		];

		List<Attachment> insertedAttachmentsAnAccount = [
			SELECT Id
			FROM Attachment
			WHERE ParentId = :insertedEmails[0].Id
		];
		List<Attachment> insertedAttachmentsOtherAccount = [
			SELECT Id
			FROM Attachment
			WHERE ParentId = :insertedEmails[1].Id
		];

		Set<Id> relatedAccounts = new Set<Id>();
		for(EmailMessage em : insertedEmails){
			relatedAccounts.add(em.RelatedToId);
		}

		System.assertEquals(2, insertedEmails.size());
		System.assert(relatedAccounts.contains(anAccount.Id));
		System.assert(relatedAccounts.contains(anotherAccount.Id));
		System.assertEquals(2,insertedAttachmentsAnAccount.size());
		System.assertEquals(2,insertedAttachmentsOtherAccount.size());
	}

	static Account anAccount;
	static Messaging.InboundEmail anEmail;

	static {
		anAccount = Build.anAccount()
					.withEmail('emailtest@test.com')
					.build();
		insert anAccount;
		anEmail = new Messaging.InboundEmail();
		anEmail.fromAddress = 'emailtest@test.com';
		anEmail.toAddresses = new List<String>();
		anEmail.toAddresses.add('recipient@test.com');
		anEmail.plainTextBody = 'This is a test';
		anEmail.subject = 'Test';
	}
}
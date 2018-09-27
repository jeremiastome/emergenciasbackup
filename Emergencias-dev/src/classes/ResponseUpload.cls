public class ResponseUpload {
	@AuraEnabled Boolean isSuccess {get;set;}
	@AuraEnabled String message {get;set;}
	@AuraEnabled String documentId {get;set;}
	public ResponseUpload(Boolean isSuccess, String message, String documentId) {
		this.isSuccess = isSuccess;
		this.message = message;
		this.documentId = documentId;
	}
}
@isTest
public class WebServiceMock implements HttpCalloutMock {
	public integer returnStatusCode = 200;
	public String returnStatus = 'OK';
	public integer callsMade = 0;
	
	public HTTPRequest receivedRequest;
	public List<HTTPRequest> receivedRequests = new List<HTTPRequest>();
	public List<String> returnBodies = new List<String>();
	
	public String returnBody {
		get {
			if(returnBodies.size() > 0) {
				return returnBodies[0];
			}
			else {
				return null;
			}
		}
		set {
			if(returnBodies.size() > 0) {
				returnBodies.add(0, value);
			}
			else {
				returnBodies.add(value);
			}
		}
	}
	
	public HTTPResponse respond(HTTPRequest req) {
        req.setTimeout(120000);
		receivedRequest = req;
		receivedRequests.add(req);
		System.debug(req);
		
		HTTPResponse res = new HTTPResponse();
		
		res.setBody(returnBodies[Math.mod(callsMade, returnBodies.size())]);
		res.setStatusCode(returnStatusCode);
		res.setStatus(returnStatus);
		
		callsMade++;
		return res;
	}
}
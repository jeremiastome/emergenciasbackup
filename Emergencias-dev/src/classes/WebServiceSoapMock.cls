@isTest
public class WebServiceSoapMock implements System.WebServiceMock {
	public Object requestObj;
	public String endpoint;
	public String soapAction;
	public String requestName;
	public boolean simulateNetworkError = false;
	public integer receivedRequests = 0;
	
	public List<Object> stubs = new List<Object>();
	public List<Object> soapRequests = new List<Object>();
	public List<Object> responseObjs = new List<Object>();
	
	public Object stub {
		get {
			if(stubs.size() > 0) {
				return stubs[0];
			}
			else {
				return null;
			}
		}
	}
	public Object soapRequest {
		get {
			if(soapRequests.size() > 0) {
				return soapRequests[0];
			}
			else {
				return null;
			}
		}
	}
	public Object responseObj {
		get {
			if(responseObjs.size() != 0) {
				return responseObjs[0];
			}
			else {
				return null;
			}
		}
		set {
			if(responseObjs.size() != 0) {
				responseObjs.set(0, value);
			}
			else {
				responseObjs.add(value);
			}
		}
	}
	
	public void doInvoke(
		Object stub,
		Object soapRequest,
		Map<String,Object> responseMap,
		String endpoint,
		String soapAction,
		String requestName,
		String responseNamespace,
		String responseName,
		String responseType
	) {
		this.endpoint = endpoint;
		this.soapAction = soapAction;
		this.requestName = requestName;
		this.receivedRequests++;
		
		this.stubs.add(stub);
		Object resp = null;
		if(responseObjs.size() > 0) {
			resp = responseObjs[Math.mod(soapRequests.size(), responseObjs.size())];
		}
		soapRequests.add(soapRequest);
		
		requestObj = soapRequest;
		responseMap.put('response_x', resp);
		
		if(simulateNetworkError) {
			throw new CalloutException();
		}
	}
}
public class SapWSTestCon {
    public static void testCon(){
        String username = 'SALESFORCE';
        String password = 'sappid';
        HTTP h = new HTTP();
        HTTPRequest r = new HTTPRequest();
        r.setEndpoint('http://199.187.122.163:50500/XISOAPAdapter/MessageServlet?senderParty=&senderService=BC_SF&receiverParty=&receiverService=&interface=SI_dummy_request&interfaceNamespace=urn:dummy_test_bapi');
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        system.debug(authorizationHeader);
        r.setHeader('Accept-Encoding', 'gzip,deflate');
        r.setHeader('Authorization', authorizationHeader);
        r.setHeader('Connection', 'Keep-Alive');
        r.setHeader('Content-Length', '324');
        r.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        r.setHeader('Cookie', 'com.sap.engine.security.authentication.original_application_url=POST#SExjviv5Gi25POKrSlgNtaMRpP3ZMX1QypkdNmG0Vvgz0xEQtP1YwTxDgnCcK5nvsbHS52s4fB50EZfcFslyWuhyhzQegl%2FaiTNVQtp7nnR7wPG90ngP79hROr4waii1nauH%2BYINgxbpQAXSonMZaNCmV44AqvpOjOOu3enbC%2FM3vlj8I7IckjE%2Fwz17pH9kKEY1b6etxl2XYWS8bJmFjfU9BWtYX4scGb3lpMfonaVOStwzBhVUdhKwRgsBjPUi3Tsy4nWb719rI9hMIf6lSC9P1XE%2BYX08fU72sQZ6m3A%3D; saplb_*=(ERPID_PID_00)2112150');
        r.setHeader('Cookie2', '$Version=1');
        r.setHeader('Host', '199.187.122.163');
        r.setHeader('Soapaction', '"http://sap.com/xi/WebService/soap1.1"');
        r.setMethod('POST');
        r.setBody('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:dummy_test_bapi"><soapenv:Header/><soapenv:Body><urn:MT_dummy_request><!--Optional:--><COMPANYCODEID>1001</COMPANYCODEID></urn:MT_dummy_request></soapenv:Body></soapenv:Envelope>');
        HTTPResponse resp = h.send(r);
		system.debug(resp.getBody());        
    }
}
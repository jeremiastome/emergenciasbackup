@isTest
public class UtilsSAPTest  {

	static testMethod void sePuedeObtenerUnaFechaConFormatoSAP() {
		
		Date fechaNull = null;

		Test.startTest();
		System.assertEquals('20011227', UtilsSAP.convertirAFechaSAP(Date.newInstance(2001, 12, 27)));
		System.assertEquals('20141214', UtilsSAP.convertirAFechaSAP(Datetime.newInstance(
			Date.newInstance(2014, 12, 14),
			Time.newInstance(21, 0, 0, 0)
		)));
		System.assertEquals(null, UtilsSAP.convertirAFechaSAP(fechaNull));
		Test.stopTest();
	}
	
	static testMethod void sePuedeObtenerElHeaderDeAutentificacionDeSAP() {
		
		String usuario = 'test';
		String contrasena = 'pass';

		Configuracion_SAP__c conf = Build.SAPSettings().withUsername(usuario).withPassword(contrasena).build();
		insert conf;

		Test.startTest();
		System.assertEquals(
			'Basic ' + EncodingUtil.base64Encode(
				blob.valueOf(
					usuario + ':' + contrasena
				)
			),
			UtilsSAP.obtenerHeaderAuth()
		);
		Test.stopTest();
	}
}
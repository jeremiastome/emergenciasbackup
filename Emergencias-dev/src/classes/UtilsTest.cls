@isTest
public class UtilsTest {
	public static testMethod void placeHolderTest(){
		Utils.enviarCorreoLog('test', new String[]{'test'}, new String[]{'test@test.com'});
	}

	static testMethod void sePuedeConvertirUnTextoConCaracteresEspecialesAASCII() {

		String textoCaracteresEsp = 'ñÑÄäáÁéÉëËíÍïÏóÓöÖúÚüÜ';
		
		System.assertEquals('nNAaaAeEeEiIiIoOoOuUuU', Utils.toAsciiSiete(textoCaracteresEsp));
	}
}
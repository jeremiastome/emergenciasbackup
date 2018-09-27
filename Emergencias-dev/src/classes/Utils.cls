public class Utils {

	public static void enviarCorreoLog(String asunto, String[] lineas, String[] destinatarios) {

		if (destinatarios == null 
			|| destinatarios.size() == 0
			|| lineas == null 
			|| lineas.size() == 0
		) {
			return;
		}

		// Mail con debug...
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setToAddresses(destinatarios);
		email.setSubject(asunto);
		String msgBody = '';

		for (String linea : lineas) {
			msgBody += linea + ' \n';
		}

		email.setPlainTextBody(msgBody);

		List<Messaging.SendEmailResult> resultados = Messaging.sendEmail(new Messaging.Email[] { email });
	}

	// Traduccion a Ascii7
	public static String toAsciiSiete(String source) {
				
			Map<String, Traduccion_ascii__c> confTraducciones = cargarConfiguracionAscii();

			source = replaceCharacters(confTraducciones, source);

			return source;
	}

	public static String replace(String source, String target, String replacement) {
				
		if (source.contains(target)) {

			Pattern nonWordChar = Pattern.compile(target);
			source = nonWordChar.matcher(source).replaceAll(replacement);
		}

		return source;	
	}

	private static String replaceCharacters(Map<String, Traduccion_ascii__c> charMap, String source) {
			
		for (String find : charMap.keySet()) {
			source = replace(source, find, (String.isBlank(charMap.get(find).valor__c)) ? '' : charMap.get(find).valor__c);
		}

		return source;
	}

	private static Map<String, String> traduccionAsciiDefault = new Map<String, String> {
		'ñ' => 'n', 'Ñ' => 'N', 'Ä' => 'A', 'ä' => 'a', 'á' => 'a', 'Á' => 'A', 'â' => 'a', 'Â' => 'A', 'ã' => 'a', 'Ã' => 'A', 'é' => 'e',
		'É' => 'E', 'ë' => 'e', 'Ë' => 'E', 'ê' => 'e', 'Ê' => 'E', 'ì' => 'i', 'í' => 'i', 'Ì' => 'I', 'Í' => 'I', 'ï' => 'i', 'Ï' => 'I',
		'î' => 'i', 'Î' => 'I', 'ó' => 'o', 'Ó' => 'O', 'ö' => 'o', 'Ö' => 'O', 'ô' => 'o', 'Ô' => 'O', 'õ' => 'o', 'Õ' => 'O', 'ú' => 'u',
		'Ú' => 'U', 'ü' => 'u', 'Ü' => 'U', 'û' => 'u', 'Û' => 'U', 'ç' => 'c', 'Ç' => 'C', '´' => '\'', '¨' => '', '`' => '', '~' => '-',
		'º' => '.', '–' => '-'
	};

	private static Map<String, Traduccion_ascii__c> cargarConfiguracionAscii() {
		
		Map<String, Traduccion_ascii__c> configs = Traduccion_ascii__c.getAll();

		if (configs != null && !configs.isEmpty()) {
			return configs;
		}
		
		// Creo traducciones por defecto
		List<Traduccion_ascii__c> toInsert = new List<Traduccion_ascii__c>();

		for (String find : traduccionAsciiDefault.keySet()) {
			toInsert.add(new Traduccion_ascii__c(
				Name = find,
				Valor__c = traduccionAsciiDefault.get(find)
			));	
		}

		insert toInsert;
		
		return Traduccion_ascii__c.getAll();
	}
}
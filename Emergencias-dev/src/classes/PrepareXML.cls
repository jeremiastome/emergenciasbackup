public class PrepareXML {
	public static String accountToSap(WSAccountToSAP.SAPClient acc, String operationType) {
		XmlStreamWriter writer = new XmlStreamWriter();
		
		writer.writeStartDocument(null, '1.0');
		
		String soapEnv = 'http://schemas.xmlsoap.org/soap/envelope/';
		writer.writeStartElement('soapenv', 'Envelope', soapEnv);
		writer.writeNamespace('soapenv', soapEnv);
		writer.writeNamespace('urn', 'urn:ABM_Clientes');
		//Envelope
		writer.writeEmptyElement('soapenv', 'Header', soapEnv);
		writer.writeStartElement('soapenv', 'Body', soapEnv);
		//Body
		writer.writeStartElement('urn', 'MT_ABM_Clientes_Request_Out', 'urn:ABM_Clientes');
		//MT_ABM_Clientes_Request_Out
		writeTextElement(writer, 'TipoOperacion', operationType);
		
		writer.writeStartElement(null, 'GeneralesCliente', null);
		//GeneralesCliente
		writeTextElement(writer, 'Cliente', acc.uniqueNumber);
		
		writeTextElement(writer, 'Tratamiento', acc.salutation);
		writeTextElement(writer, 'Nombre', acc.firstName);
		writeTextElement(writer, 'Apellido', acc.lastName);
		
		writeTextElement(writer, 'Busqueda', acc.alias);
		
		writeTextElement(writer, 'Calle', acc.streetName);
		writeTextElement(writer, 'Altura', acc.streetNumber);
		writeTextElement(writer, 'Piso', acc.floor);		
		writeTextElement(writer, 'Depto', acc.dpto);


		
		writeTextElement(writer, 'Poblacion', acc.city);
		writeTextElement(writer, 'CodigoPostal', acc.postalCode);
		writeTextElement(writer, 'Pais', getCountryCode(acc.country));
		writeTextElement(writer, 'Region', getStateCode(acc.state));
		writeTextElement(writer, 'Telefono', acc.phone);
		writeTextElement(writer, 'Fax', acc.fax);
		writeTextElement(writer, 'Email', acc.email);
		writeTextElement(writer, 'Nif1', acc.nif1);
		writeTextElement(writer, 'TipoNif1', acc.nif1Type);
		
		writeTextElement(writer, 'ClaseDeImpuesto', acc.taxClass);
		writeTextElement(writer, 'PersonaFisica', acc.isFisicalPerson);
		writeTextElement(writer, 'ImpVolNegocio', null);
		writeTextElement(writer, 'Empleado', null);
		writeTextElement(writer, 'Destinatario', acc.destinatary);
		writeTextElement(writer, 'Bloqueado', operationType == 'B'?'True':'False');
		//End GeneralesCliente
		writer.writeEndElement();
		//========================================
		writer.writeStartElement(null, 'SociedadCliente', null);
		//SociedadCliente
		writeTextElement(writer, 'Sociedad', acc.clientSoc);
		writeTextElement(writer, 'NroCuentaAnterior', null);
		writeTextElement(writer, 'CodigoActividad', null);
		writeTextElement(writer, 'CondicionDePago', 'C020');
		writeTextElement(writer, 'ViaDePago', 'M');


		/// New
		writeTextElement(writer, 'Piso', acc.floor);
		writeTextElement(writer, 'Dto', acc.dpto);


		//End SociedadCliente
		writer.writeEndElement();
		//========================================
		createClientSalesTag(writer, acc, null);
        System.debug(acc.sapContacts);
        System.debug(acc.sapContacts.size());
		for(WSAccountToSAP.SAPContactRelation sapContact : acc.sapContacts) {
			createClientSalesTag(writer, acc, sapContact);
		}
		
		//End MT_ABM_Clientes_Request_Out
		writer.writeEndElement();
		
		//End Body
		writer.writeEndElement();
		
		//End Envelope
		writer.writeEndElement();
		String xmlOut = writer.getXmlString();
		writer.close();
		return xmlOut;
	}
	
	private static void createClientSalesTag(XmlStreamWriter writer, WSAccountToSAP.SAPClient acc, WSAccountToSAP.SAPContactRelation sapContact) {

        writer.writeStartElement(null, 'VentaClientes', null);
		//VentaClientes
		writeTextElement(writer, 'OrganizacionVentas', acc.salesOrg);
		writeTextElement(writer, 'CanalDistribucion', acc.distChannel);
        
		if(sapContact != null) {
			writeTextElement(writer, 'CondicionPagoFactura', sapContact.paymentCondition);
			writeTextElement(writer, 'Solicitante', null);
			writeTextElement(writer, 'ResponsableDePago', sapContact.sapId);
			writeTextElement(writer, 'ResponsableDeFactura', sapContact.sapId);
			writeTextElement(writer, 'Destinatario', sapContact.sapId);
		}
		else {
			if(acc.sapContacts.size() == 0) {
				writeTextElement(writer, 'CondicionPagoFactura', 'C010');
			}
			else {
				writeTextElement(writer, 'CondicionPagoFactura', null);
			}
			writeTextElement(writer, 'Solicitante', null);
			writeTextElement(writer, 'ResponsableDePago', null);
			writeTextElement(writer, 'ResponsableDeFactura', null);
			writeTextElement(writer, 'Destinatario', null);
		}
		//End VentaClientes
		writer.writeEndElement();
	}
	
	private static void writeTextElement(XmlStreamWriter writer, String tag, String text) {
		if(String.isBlank(text)) {
			text = '';
		}
		writer.writeStartElement(null, tag, null);
		writer.writeCharacters(text);
		writer.writeEndElement();
	}
	
	private static String getCountryCode(String country) {
		if(country != null) {
			if(country.toLowerCase() == 'argentina') {
				return 'AR';
			}
		}
		return '';
	}
	
	private static Map<String, String> provinceToCode = new Map<String, String> {
		'capital federal' => '00',
		'caba' => '00',
		'buenos aires' => '01',
		'catamarca' => '02',
		'cordoba' => '03',
		'corrientes' => '04',
		'entre rios' => '05',
		'jujuy' => '06',
		'mendoza' => '07',
		'la rioja' => '08',
		'salta' => '09',
		'san juan' => '10',
		'san luis' => '11',
		'santa fe' => '12',
		'santiago del estero' => '13',
		'tucuman' => '14',
		'chaco' => '16',
		'chubut' => '17',
		'formosa' => '18',
		'misiones' => '19',
		'neuquen' => '20',
		'la pampa' => '21',
		'rio negro' => '22',
		'santa cruz' => '23',
		'tierra del fuego' => '24'
	};
	public static String getStateCode(String state) {
		if(state != null) {
			string safeval = state.replace('á', 'a').replace('é', 'e')
				.replace('í', 'i').replace('ó', 'o').replace('ú', 'u').toLowerCase();
			if(provinceToCode.containsKey(safeVal)) {
				return provinceToCode.get(safeVal);
			}
		}
		return '99';
	}
}
public abstract class ContractToSAPConverterBase {
	protected String operation;
	protected Contrato__c contract;
	protected Account client;
	protected Cobrador__c collector;
	protected Contact deliveryContact;
	protected Contact billingContact;
	protected Contact collectionContact;
	
	public ContractToSAPConverterBase(Id contractId, String operation) {
		this.operation = operation;
		contract = [
			SELECT Id, Numero_Unico_de_Contrato_Con_Sufijo__c, Organizacion_de_Ventas__c, Contrato_de_Padrones__c,
				Canal_de_Distribucion__c, Condicion_de_pago__c,Forma_de_pago__c, Fecha_Baja__c, Grupo_de_Vendedores__c,
				Fecha_Alta__c, Oficina_de_Venta__c, Tipo_de_Tarjeta__c, Tarjeta_sin_cifrar__c, Estado__c,
				Factura_por_Adelantado__c, Es_evento__c, Bloqueo_Factura__c, Importe__c,
				CBU__c, Fecha_Inicio_de_Vigencia__c, Tipo_de_documento_sap__c,
				Cobrador__r.Codigo_Sap__c, Cliente__r.N_mero_nico_de_Cliente__c,
				Contacto_Cobranza__r.Codigo_SAP_contacto__c,
				Contacto_Cobranza__r.Zona_de_cobranza_manual__r.Name, Zona__r.Name,
				Contacto_de_delivery__r.Codigo_SAP_contacto__c,
				Contacto_Facturacion__r.Codigo_SAP_contacto__c,
				RecordType.DeveloperName
			FROM Contrato__c
			WHERE Id = :contractId
		];
		
		if (contract.Fecha_Alta__c == null){
			contract.Fecha_Alta__c = Date.today();
		}
		deliveryContact = contract.Contacto_de_delivery__r;
		billingContact = contract.Contacto_Facturacion__r;
		collectionContact = contract.Contacto_Cobranza__r;
		client = contract.Cliente__r;
		collector = contract.Cobrador__r;
	}
	
	public virtual WSSAPContratosPedidos.Pedido_element generateRequest() {
		WSSAPContratosPedidos.Pedido_element result = new WSSAPContratosPedidos.Pedido_element();
		operation = operation.toUpperCase();
		
		result.Cabecera = generateContractHeader();
		
		return result;
	}
	
	protected WSSAPContratosPedidos.Cabecera_element generateContractHeader() {
		WSSAPContratosPedidos.Cabecera_element result = new WSSAPContratosPedidos.Cabecera_element();
		
		if(operation != null) {
			result.TipoOperacion = operation;
		}
		result.TipoDocumento = getContractDocumentType();
		
		if(contract.Numero_Unico_de_Contrato_Con_Sufijo__c != null) {
			result.NumeroDePedido = contract.Numero_Unico_de_Contrato_Con_Sufijo__c;
		}
		if(contract.Organizacion_de_Ventas__c != null) {
			result.OrganizacionVentas = contract.Organizacion_de_Ventas__c;
		}
		if(contract.Canal_de_Distribucion__c != null) {
			result.CanalDistribucion = contract.Canal_de_Distribucion__c;
		}
		result.Sector = '00';
		result.NumeroPedidoCliente = '';
		if(contract.Forma_de_Pago__c != null || contract.Condicion_de_pago__c != null) {
			result.CondicionDePago = contract.Forma_de_Pago__c + contract.Condicion_de_pago__c;
		}

		if(contract.Oficina_de_Venta__c != null || contract.Grupo_de_Vendedores__c != null) {
			if (contract.Oficina_de_Venta__c==null) {
				contract.Oficina_de_Venta__c= '	';
			}
			if(contract.Grupo_de_Vendedores__c==null) {
				contract.Grupo_de_Vendedores__c= ' ';
			}

			result.OficinaDeVentas = contract.Oficina_de_Venta__c + '-' + contract.Grupo_de_Vendedores__c;
			
			System.debug(result.OficinaDeVentas);
		}
		else {
			result.OficinaDeVentas=' ';
		}

		if(contract.Forma_de_Pago__c == 'S') {
			if(contract.CBU__c != null) {
				result.Tarjeta = contract.CBU__c;
			}
		}
		else {
			if(contract.Tipo_de_Tarjeta__c != null) {
				result.TipoTarjeta = contract.Tipo_de_Tarjeta__c;
			}
			if(contract.Tarjeta_sin_cifrar__c != null) {
				result.Tarjeta = contract.Tarjeta_sin_cifrar__c;
			}
		}
		
		if(contract.Fecha_Inicio_de_Vigencia__c != null) {
			result.IniVigenciaContrato = formatDate(contract.Fecha_Inicio_de_Vigencia__c);
		}
		else if(contract.Fecha_Alta__c != null) {
			result.IniVigenciaContrato = formatDate(contract.Fecha_Alta__c);
		}
		if(contract.Fecha_Baja__c != null) {
			result.FinVigenciaContrato = formatDate(contract.Fecha_Baja__c);
		}
		else {
			result.FinVigenciaContrato = '99991231';
		}
		
		if(collector != null) {
			result.Cobrador = collector.Codigo_Sap__c;
		}
		
		if(result.TipoDocumento == 'C0') {
			result.FactAdelantado = contract.Factura_por_Adelantado__c? 'True':' ';
			result.ReglaFact = '50';
		}
		else {
			result.FactAdelantado = '';
			result.ReglaFact = '';
		}
		
		if(operation == 'B') {
			result.BloqueoFact = 'BA';
		}
		else if(contract.Bloqueo_Factura__c != null) {
			result.BloqueoFact = contract.Bloqueo_Factura__c;
		}
		else {
			result.BloqueoFact = '';
		}
		
		if(operation == 'S') {
			result.Solicitante = Cuenta_de_cotizador__c.getInstance().Numero_unico_CF__c;
		}
		else {
			if(client.N_mero_nico_de_Cliente__c != null){
				result.Solicitante = client.N_mero_nico_de_Cliente__c;
			}
		}
		
		if(operation != 'S' && deliveryContact != null) {
			result.DestinatarioMercancias = deliveryContact.Codigo_SAP_contacto__c;
		}
		else {
			result.DestinatarioMercancias = '';
		}
		if(operation != 'S' && billingContact != null) {
			result.DestinatarioFactura = billingContact.Codigo_SAP_contacto__c;
		}
		else {
			result.DestinatarioFactura = '';
		}
		
		result.Radio = '';
		if(operation != 'S' && collectionContact != null) {
			result.ResponsableDePago = collectionContact.Codigo_SAP_contacto__c;
			if(collectionContact.Zona_de_cobranza_manual__r != null) {
				result.Radio = collectionContact.Zona_de_cobranza_manual__r.Name;
			}
		}
		else {
			result.ResponsableDePago = '';
		}
		if(operation != 'S' && result.Radio == '') {
			if(contract.Zona__r != null) {
				result.Radio = contract.Zona__r.Name;
			}
		}
		
		result.MotivoDePedido = '';
		result.DocumentoRef = '';
		return result;
	}
	
	private String getContractDocumentType() {
		if(contract.RecordType.DeveloperName == 'Ventas_Varias') {
			return 'VV';
		}
		else if(contract.Canal_de_Distribucion__c == '31' || contract.Canal_de_Distribucion__c == '32') {
			return 'C3';
		}
		else if(contract.Contrato_de_Padrones__c) {
			return 'C1';
		}
		else {
			return contract.Tipo_de_documento_sap__c;
		}
	}
	
	//==========================================================================
	//Helper methods
	public static String formatNumber(decimal val, integer decs) {
		String result = String.valueOf(val);
		
		if(result.contains('.')) {
			List<String> parts = result.split('\\.');
			return parts[0] + '.' + parts[1].rightPad(decs, '0');
		}
		else {
			return result + '.' + ''.rightPad(decs, '0');
		}
	}
	
	public static String formatDate(Date val) {
		if(val == null) {
			return '';
		}
		else {
			String month = '0' + val.month();
			String day = '0' + val.day();
			return val.year() + month.right(2) + day.right(2);
		}
	}
}
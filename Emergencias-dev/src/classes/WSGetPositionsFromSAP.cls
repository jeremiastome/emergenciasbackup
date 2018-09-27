public class WSGetPositionsFromSAP {
	private static String ADDRESS = 'addr';
	private static String OTHER = 'othr';
	private static String MINOR_DISCOUNT = 'mdisc';
	private static String SEPARATOR = '<__>';
	public boolean hadError;
	Map<String, integer> posNumByDat;
	integer maxPosNum;
	
	public List<WSSAPContratosPosiciones.POSICIONES_element> result;
	public WSGetPositionsFromSAP() {
		posNumByDat = new Map<String, integer>();
		maxPosNum = 0;
		hadError = false;
	}
	
	@AuraEnabled
	public static String createPositionByCreditNote(string CaseId) {
		Case aCase = [
			SELECT Id, Contrato__r.Numero_unico_de_contrato_con_sufijo__c,
			Nro_de_Factura__c, Con_referencia_a_factura__c, Status
			FROM Case
			WHERE Id = :CaseId
		];
		if(aCase.Status=='Cerrado') {
			return 'El caso ya se encuentra cerrado por lo que no se pueden editar posiciones.';
		}
		List<Posicion__c> posiciones = new List<Posicion__c>();
		if (aCase.Contrato__c!=null
			&& string.isNotEmpty(aCase.Contrato__r.numero_unico_de_contrato_con_sufijo__c)
			&& (string.isEmpty(aCase.Nro_de_Factura__c) || aCase.Con_referencia_a_factura__c=='No')
		) {
			Schema.DescribeFieldResult fieldResult = posicion__c.provincia__c.getDescribe();
			List<Schema.PicklistEntry> provinciaValues = fieldResult.getPickListValues();
			Lead.fields.Country.getDescribe().getpicklistvalues();
			WSGetPositionsFromSAP wsGetPositions = new WSGetPositionsFromSAP();
			
			try {
				wsGetPositions.getForContract(aCase.Contrato__r.numero_unico_de_contrato_con_sufijo__c);
			}
			catch (Exception ex) {
				return 'Error: ' + ex.getMessage();
			}
			
			if (!wsGetPositions.hadError && wsGetPositions.result!=null && !wsGetPositions.result.isEmpty()) {
				List<WSSAPContratosPosiciones.POSICIONES_element> response = wsGetPositions.result;
				for (WSSAPContratosPosiciones.POSICIONES_element pos : response) {
					if(String.isBlank(pos.MOTIVO_RECHAZO)) {
						Posicion__c newPos = new Posicion__c();
						newPos.caso__c = acase.Id;
						newPos.Posicion__c = pos.Posicion;
						newPos.Producto__c = pos.BOM;
						newPos.Provincia__c = getCheckedPickListValue(pos.Destinatario,provinciaValues);
						newPos.Iva__c = pos.Cond_Iva;
						posiciones.add(newPos);
					}
					System.debug(pos);
				}
				updateOrCreatedPosition(CaseId, posiciones);
			}
			else if (wsGetPositions.result==null || wsGetPositions.result.isEmpty()) {
				return 'Error: No se han encontrado posiciones. Comuniquese con su administrador.';
			}
			else {
				return 'Error: Ha ocurrido un error en la conexion. Comuniquese con su administrador.';
			}
		}
		else if (string.isNotEmpty(aCase.Nro_de_Factura__c)
			&& aCase.Con_referencia_a_factura__c=='Si'
		) {
			WSGetDetallesDocumentoContable ws = new WSGetDetallesDocumentoContable();
			try {
				ws.getForFactura(aCase.Nro_de_Factura__c);
			}
			catch (Exception ex) {
				return 'Error: '+ex.getMessage();
			}
			System.debug(ws.hadError);
			System.debug(ws.result);
			if (!ws.hadError && ws.result != null && !ws.result.isEmpty() ) {
				for (WSSAPDetallesDocumentoContable.XVBRP_element detalle : ws.result) {
					if (detalle.AUPOS.isnumeric()
						&& Math.mod(integer.valueOf(detalle.AUPOS),100) == 0
					) {
						Posicion__c newPos = new Posicion__c();
						newPos.caso__c = acase.Id;
						newPos.Posicion__c = detalle.POSNR;
						newPos.Producto__c = detalle.MATWA;
						newPos.Fecha__c = detalle.PRSDT;
						posiciones.add(newPos);
						System.debug(detalle);
					}
				}
				updateOrCreatedPosition(CaseId, posiciones);
			}
			else if(ws.result==null) {
				return 'Error: No se han encontrado posiciones, '
					+ 'verifique el numero de factura o comuniquese con su administrador.';
			}
			else {
				return 'Error: Ha ocurrido un error en la conexion. '
					+ 'Comuniquese con su administrador.';
			}
		}
		return 'Ok';
	}
	
	@AuraEnabled
	public static void updateOrCreatedPosition(string CaseId, List<Posicion__c> positionsResponse) {
		Map<String, Posicion__c> responseByNum = new Map<String, Posicion__c>();
		Map<String, Posicion__c> oldPositionsByNum = new Map<String, Posicion__c>();
		
		List<Posicion__c> oldPositions = [
			SELECT Id, Posicion__c
			FROM Posicion__c
			WHERE Caso__c = :CaseId
		];
		if(oldPositions.size()!=0) {
			List<Posicion__c> addPosition = new List<Posicion__c>();
			List<Posicion__c> deletePosition = new List<Posicion__c>();
			
			for(Posicion__c pos : positionsResponse) {
				responseByNum.put(pos.Posicion__c, pos);
			}
			for(Posicion__c pos : oldPositions) {
				if(!responseByNum.containsKey(pos.Posicion__c)) {
					deletePosition.add(pos);
				}
			}
			if(deletePosition.size()!=0) {
				delete deletePosition;
			}
			
			for(Posicion__c pos : oldPositions) {
				oldPositionsByNum.put(pos.Posicion__c, pos);
			}
			for(Posicion__c pos : positionsResponse) {
				if(!oldPositionsByNum.containsKey(pos.Posicion__c)) {
					addPosition.add(pos);
				}
			}
			if(addPosition.size()!=0) {
				insert addPosition;
			}
		}
		else {
			insert positionsResponse;
		}
	}
	
	public static string getCheckedPickListValue(
		string pickListValue,
		List<Schema.PicklistEntry> pickList
	) {
		for (Schema.PicklistEntry entry: pickList) {
			if (pickListValue==entry.getValue()) {
				return pickListValue;
			}
		}
		return '';
	}
	
	public void getForContract(String contractNumber) {
		WSSAPContratosPosiciones.HTTPS_Port ws = new WSSAPContratosPosiciones.HTTPS_Port();
		ws.inputHttpHeaders_x = new Map<String, String>();
		String auth = prepareAuthorization();
		if(auth == null) {
			hadError = true;
			return;
		}
		
		ws.inputHttpHeaders_x.put('authorization', auth);
		ws.inputHttpHeaders_x.put('Content-Type', 'text/xml;charset=UTF-8');
		
		result = new List<WSSAPContratosPosiciones.POSICIONES_element>();
		
		try {
			result = ws.SI_OS_CONTRATOS_OUT(contractNumber);
		}
		catch (Exception e) {
			System.debug('Error loading old positions');
			System.debug(e);
			hadError = true;
			return;
		}
		system.debug(result);
		if(result != null) {
			for(WSSAPContratosPosiciones.POSICIONES_element pos : result) {
				integer posNum = integer.valueOf(pos.POSICION);
				
				if(posNum > maxPosNum) {
					maxPosNum = posNum;
				}
				
				if(String.isBlank(pos.MOTIVO_RECHAZO)) {
					String dat;
					if(String.isBlank(pos.SUFIJO)) {
						dat = getDat(pos.BOM, pos.COND_IVA, pos.DESTINATARIO, !String.isBlank(pos.MENOR_S_CARGO));
					}
					else {
						dat = getDat(pos.BOM, pos.SUFIJO);
					}
					posNumByDat.put(dat, posNum);
				}
			}
		}
	}
	
	public integer getPosNumber(String product, String sufix) {
		String dat = getDat(product, sufix);
		return getPosNumber(dat);
	}
	
	public integer getPosNumber(String product, String iva, String prov, boolean minorDiscount) {
		String dat = getDat(product, iva, prov, minorDiscount);
		return getPosNumber(dat);
	}
	
	public integer getNextNumber() {
		maxPosNum += 100;
		return maxPosNum;
	}
	
	public List<WSSAPContratosPedidos.Posicion_element> generateDeletePositions() {
		List<WSSAPContratosPedidos.Posicion_element> result = new List<WSSAPContratosPedidos.Posicion_element>();
		
		for(String key : posNumByDat.keySet()) {
			WSSAPContratosPedidos.Posicion_element pos = new WSSAPContratosPedidos.Posicion_element();
			List<String> parts = key.split(SEPARATOR);
			pos.TipoOperacion = 'B';
			pos.NumeroPosicion = String.valueOf(posNumByDat.get(key));
			pos.CodigoMaterial = parts[0];
			pos.Cantidad = '';
			pos.Sector = '';
			if(parts[1] == ADDRESS) {
				pos.CondIVABenef = '';
				pos.DestinatarioMercancias = '';
				pos.ZonaDeVentas = parts[2].leftPad(3, '0');
			}
			else {//parts[1] == OTHER
				pos.CondIVABenef = parts[2];
				pos.DestinatarioMercancias = parts[3];
				pos.ZonaDeVentas = '';
			}
			
			pos.GrupoDeClientes = '';
			pos.MotivoDeRechazo = 'BA';
			pos.Cobrador = '';
			pos.Radio = '';
			
			result.add(pos);
		}
		
		return result;
	}
	
	private String getDat(String product, String sufix) {
		return product + SEPARATOR + ADDRESS + SEPARATOR + String.valueOf(integer.valueOf(sufix));
	}
	
	private String getDat(String product, String iva, String prov, boolean minorDiscount) {
		return product + SEPARATOR + OTHER + SEPARATOR + iva + SEPARATOR + prov + (minorDiscount?SEPARATOR + MINOR_DISCOUNT:'');
	}
	
	private integer getPosNumber(String dat) {
		if(posNumByDat.containsKey(dat)) {
			return posNumByDat.remove(dat);
		}
		else {
			return -1;
		}
	}
	
	private String prepareAuthorization() {
		Configuracion_SAP__c sapSettings = Configuracion_SAP__c.getInstance();
		if(String.isBlank(sapSettings.Url__c)) {
			return null;
		}
		return 'Basic ' + EncodingUtil.base64Encode(
			blob.valueOf(
				sapSettings.Usuario__c + ':' + sapSettings.Contrasena__c
			)
		);
	}
}
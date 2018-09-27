public class WSCreditNoteToSAP {
	public static void sendCreditNote(Id caseId) {
		Configuracion_SAP__c sapSettings = Configuracion_SAP__c.getInstance();
		if(String.isBlank(sapSettings.Url__c)) {
			return;
		}
		String auth = EncodingUtil.base64Encode(
			blob.valueOf(
				sapSettings.Usuario__c + ':' + sapSettings.Contrasena__c
			)
		);
		
		List<WSSAPContratosPedidos.Pedido_element> request = new List<WSSAPContratosPedidos.Pedido_element>();
		
		request.add(
			generateRequest(
				caseId
			)
		);
		
		WSSAPContratosPedidos.HTTPS_Port ws = new WSSAPContratosPedidos.HTTPS_Port();
		ws.inputHttpHeaders_x = new Map<String, String>();
		ws.inputHttpHeaders_x.put('authorization', 'Basic ' + auth);
		ws.inputHttpHeaders_x.put('Content-Type', 'text/xml;charset=UTF-8');
		
        system.debug(request);
		WSSAPContratosPedidos.DT_Contratos_Pedidos_Response_In result;
        Case caseToUpdate = new Case();
        caseToUpdate.Id = caseId;
        caseToUpdate.Enviado_a_SAP__c = true;
        caseToUpdate.Request_SF__c = String.valueOf(request);
				

        try{
			result = ws.SI_Contratos_Pedidos_Request(request);
	        system.debug(result);
        	caseToUpdate.Status_Envio__c = '200';
            caseToUpdate.Response_SAP__c = String.valueOf(result)+'\n'+String.valueOf(Datetime.now());
			caseToUpdate.Numero_de_pedido__c = request[0].Cabecera.NumeroDePedido;
			if(result != null) {  /// Para evitar NullPointerException puse If dentro de If.
				if(result.Msg.size() != 0) {
					if( notNullString(result.Msg[0].Descripcion).length() < 250) {
						caseToUpdate.Descripcion_de_respuesta_de_SAP__c=result.Msg[0].Descripcion;
					}
				}
			}

        }
        catch(Exception ex){
            system.debug(ex);
        	caseToUpdate.Status_Envio__c = '-1';
            caseToUpdate.Response_SAP__c = 'Exception: ' + ex.getMessage();
			caseToUpdate.Descripcion_de_respuesta_de_SAP__c='Exception: ' + ex.getMessage();

        } finally {
			Notas_de_credito_numeracion__c numeracion = [
				SELECT id, numero__c 
				FROM Notas_de_credito_numeracion__c 
				WHERE name = 'Numero' 
			][0];
			numeracion.numero__c = numeracion.numero__c +1;
			update numeracion;

			update caseToUpdate;
		}


	}
	
	private static WSSAPContratosPedidos.Pedido_element generateRequest(Id caseId) {
        WSSAPContratosPedidos.Pedido_element result = new WSSAPContratosPedidos.Pedido_element();
		
		Case theCase = [
			SELECT Id, Nro_de_Factura__c, Motivo_de_nota_de_credito__c,Condicion_de_pago__c,
				Contrato__r.Organizacion_de_Ventas__c, Contrato__r.Canal_de_Distribucion__c,            	
				Account.N_mero_nico_de_Cliente__c, Contrato__r.Numero_Unico_de_Contrato_Con_Sufijo__c,
            	Contrato__r.Oficina_de_Venta__c, Contrato__r.grupo_de_vendedores__c,
            	tipo_de_tarjeta__c, numero_de_tarjeta__c, numero_de_pedido__c,
            		(select posicion__c,producto__c,
                     valor__c, unidad__c, cantidad__c, Fecha__c
                     from Posiciones__r)
			FROM Case
			WHERE Id = :caseId
		];
		
		result.Cabecera = new WSSAPContratosPedidos.Cabecera_element();
       
		result.Cabecera.TipoOperacion = 'A';

        String numDePedido;
        
		if(theCase.Numero_de_pedido__C==null) {

			List<Notas_de_credito_numeracion__C> listNum = [
				SELECT id, numero__c FROM 
				Notas_de_credito_numeracion__c 
				WHERE name = 'Numero'
			];

			Notas_de_credito_numeracion__c numeracion;
        
			if (!listNum.isEmpty()){
        		numeracion = listNum[0];    
			} else{
				numeracion = new Notas_de_credito_numeracion__c ();
				numeracion.Numero__c =65001006;
			}
			numDePedido = '00'+numeracion.numero__c;

		} else {	

			numDePedido =theCase.Numero_de_pedido__C;
		}
  		result.Cabecera.CanalDistribucion = notNullString(theCase.Contrato__r.Canal_de_Distribucion__c);
		result.Cabecera.OrganizacionVentas = notNullString(theCase.Contrato__r.Organizacion_de_Ventas__c);
		result.Cabecera.Solicitante = notNullString(theCase.Account.N_mero_nico_de_Cliente__c);
		result.Cabecera.Sector = '00';
		result.Cabecera.MotivoDePedido = notNullString(theCase.Motivo_de_nota_de_credito__c);
		result.Cabecera.NumeroDePedido = numDePedido; //notNullString(theCase.Contrato__r.Numero_Unico_de_Contrato_Con_Sufijo__c);
		result.Cabecera.DocumentoRef = notNullString(theCase.Nro_de_Factura__c);
		result.Cabecera.CondicionDePago = notNullString(theCase.condicion_de_pago__c);
        result.Cabecera.OficinaDeVentas = notNullString(theCase.contrato__r.oficina_de_venta__c)+'-'+notNullString(theCase.contrato__r.grupo_de_vendedores__c);
        result.Cabecera.TipoTarjeta = notNullString(theCase.tipo_de_tarjeta__c);
        result.Cabecera.Tarjeta = notNullString( string.valueof(theCase.numero_de_tarjeta__c));
		result.Cabecera.IniVigenciaContrato= UtilsSAP.convertirAFechaSAP(Date.today());
		result.Cabecera.FinVigenciaContrato ='29991231';
        result.Cabecera.TipoDocumento='NC';
		
		

        List<WSSAPContratosPedidos.Posicion_element>  posiciones = new List<WSSAPContratosPedidos.POsicion_element>();
        for (Posicion__c pos : theCase.posiciones__r)
        {
            WSSAPContratosPedidos.Posicion_element posElement = new WSSAPContratosPedidos.Posicion_element();
            posElement.NumeroPosicion = notNullString(pos.Posicion__c);
            posElement.CodigoMaterial = notNullString(pos.Producto__c);
            posElement.cantidad = notNullString(String.valueOf(pos.Cantidad__c));
			posElement.Sector= '00';
            posElement.TipoOperacion = 'A';

            WSSAPContratosPedidos.Condiciones_element condicion = new WSSAPContratosPedidos.Condiciones_element();
            condicion.TipoOperacion = 'A';
            condicion.ClaseCondicion = string.isNotEmpty(theCase.Nro_de_Factura__c)? '' : 'ZPVS';
            condicion.Importe = string.valueOf (pos.Valor__c);
            condicion.Unidad = notNullString(pos.Unidad__c);
            if (pos.Fecha__c != null){
            	condicion.FechaInicioValidez = pos.Fecha__c; // UtilsSAP.convertirAFechaSAP(Date.today());    
            }
            condicion.FechaFinValidez = '29991231';
            
		    posElement.Condiciones = new List<WSSAPContratosPedidos.Condiciones_element>();

			if(condicion.Importe != '0' & condicion.Importe != null) {
				posElement.Condiciones.add(condicion);            
            }

            posiciones.add(posElement);
        }
        result.ListaPosiciones = new WSSAPContratosPedidos.ListaPosiciones_element();
        result.ListaPosiciones.Posicion = posiciones;
		return result;
	}
    
    public static string notNullString(string str)
    {
        return string.isEmpty(str)?'':str;
    }
}
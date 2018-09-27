public class EstadoDeCuentaCliente  {

		public static EstadoDeCuenta obtener(Account cliente, Date desde, Date hasta) {
				
				EstadoDeCuenta estado = new EstadoDeCuenta(cliente);

				// Validaciones
				if (cliente == null || String.isBlank(cliente.N_mero_nico_de_Cliente__c)) {
						estado.mensaje = Label.WSDocumentosContables_FaltaCliente;
						return estado;
				}

				if (String.isBlank(cliente.Sociedad__c)) {
						estado.mensaje = Label.WSDocumentosContables_FaltaSociedad;
						return estado;
				}

				if (desde == null || hasta == null) {
						estado.mensaje = Label.WSDocumentosContables_FaltaPeriodo;
						return estado;
				}
				
				// Ellos no tienen en cuenta el ultimo digito del codigo del cliente
				String codCliente = cliente.N_mero_nico_de_Cliente__c;
				
				if (cliente.N_mero_nico_de_Cliente__c.length() > 10) {
						codCliente = cliente.N_mero_nico_de_Cliente__c.substring(0, 10);
				}

				// Armo consulta
				WSSAPDocumentosContables.Consulta_element consulta = new WSSAPDocumentosContables.Consulta_element();
				consulta.COMPANYCODE = cliente.Sociedad__c;
				consulta.CUSTOMER = codCliente;
				consulta.DATE_FROM = UtilsSAP.convertirAFechaSAP(desde);				consulta.DATE_TO = UtilsSAP.convertirAFechaSAP(hasta);

				// Hago llamada a webservice
				System.debug('Consulta '+consulta);
				WSSAPDocumentosContables.DT_Estado_de_Cuenta_Response_In response = calloutDocumentosContables().SI_Estado_de_Cuenta_Request(consulta);
           		System.debug('Respuesta '+response);
				System.debug(LoggingLevel.DEBUG, response);

				if (response.RETURN_x != null && !response.RETURN_x.isEmpty()) {
						
						estado.mensaje = response.RETURN_x[0].MESSAGE;
						return estado;
				} 

				// Parseo respuesta
				estado.documentos = UtilsSAP.convertirADocumentosContablesSF(response.LINEITEMS);

				return estado;
		}

		public static DocumentoContable obtenerDetalles(String nroDocumento) {
				
				WSSAPDocumentosContables.LINEITEMS_element lineItem = new WSSAPDocumentosContables.LINEITEMS_element();
				lineItem.BILL_DOC = nroDocumento;

				DocumentoContable documento = new DocumentoContable(lineItem);

				// Validaciones
				if (String.isBlank(nroDocumento)) {
						documento.mensaje = Label.WSDetallesDocumentosContables_FaltaNroDocumento;
						return documento;
				}

				// Armo consulta
				WSSAPDetallesDocumentoContable.Consulta_element consulta = new WSSAPDetallesDocumentoContable.Consulta_element();
				consulta.VBELN = lineItem.BILL_DOC;

				// Hago llamada a webservice
				WSSAPDetallesDocumentoContable.DT_Documentos_de_Facturacion_Response_In response = calloutDetallesDocumentoContable().SI_Documentos_de_Facturacion_Request(consulta);

				if (response.RETURN_x != null && !response.RETURN_x.isEmpty()) {
						documento.mensaje = response.RETURN_x[0].MESSAGE;
						return documento;
				} 
            
               if(response != null) {       
                    System.debug('Respuesta no es nula');
                    List <WSSAPDetallesDocumentoContable.XVBRP_element> result = new  List<WSSAPDetallesDocumentoContable.XVBRP_element> ();
                    for (WSSAPDetallesDocumentoContable.XVBRP_element XVBRP : response.XVBRP)
                    {
                        if ( XVBRP.AUPOS!=null 
                           && XVBRP.AUPOS.isnumeric()
                        &&Math.mod(integer.valueOf(XVBRP.AUPOS),100)==0
                            &&integer.valueOf(XVBRP.AUPOS)!=0) {
                            System.debug(XVBRP);
                            System.debug(XVBRP.AUPOS.isnumeric());
                            System.debug(Math.mod(integer.valueOf(XVBRP.AUPOS),100)==0);
                            System.debug(XVBRP);
                            result.add(XVBRP);
                            }
                    }
                	response.XVBRP = result;
               }
				// Parseo respuesta
				System.debug(response);
				documento.detalles = UtilsSAP.convertirADetallesDocumentoContableSF(response.XVBRP);
				
				return documento;
		}

		private static WSSAPDetallesDocumentoContable.HTTPS_Port calloutDetallesDocumentoContable() {
				
				WSSAPDetallesDocumentoContable.HTTPS_Port callout = new WSSAPDetallesDocumentoContable.HTTPS_Port();
				callout.inputHttpHeaders_x = new Map<String, String> {
						'authorization' => UtilsSAP.obtenerHeaderAuth()
				};

				return callout;
		}

		private static WSSAPDocumentosContables.HTTPS_Port calloutDocumentosContables() {

				WSSAPDocumentosContables.HTTPS_Port callout = new WSSAPDocumentosContables.HTTPS_Port();
				callout.inputHttpHeaders_x = new Map<String, String> {
						'authorization' => UtilsSAP.obtenerHeaderAuth()
				};

				return callout;
		}
}
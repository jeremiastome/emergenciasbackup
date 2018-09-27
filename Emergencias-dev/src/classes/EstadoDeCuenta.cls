public class EstadoDeCuenta  {

    public Account cliente {get; set;}
    public Map<String, String> codigosContables;
    
	public EstadoDeCuenta(Account cliente) {
        this.codigosContables = new Map<String, String>();
        
      	this.recordTypeId= [SELECT Id FROM RecordType WHERE DeveloperName='Nota_de_credito'][0].id;
        
        List<Codigo_contable__mdt> codigos = [SELECT Id, DeveloperName, 
                                              Tipo_de_operacion__c, codigo__c
                                              FROM Codigo_contable__mdt ];
        
        for (Codigo_contable__mdt codigo : codigos) {
            codigosContables.put(codigo.codigo__c, codigo.Tipo_de_operacion__c);
        }
        
      	this.cliente = cliente;
      	documentos = new DocumentoContable[] {};
        
    }
    
    @AuraEnabled public DocumentoContable[] documentos {get; set;}
    
    @AuraEnabled public string saldo {get{
        Decimal saldo=0; 
        for (DocumentoContable doc : this.documentos) {
            if( doc.tipoDeContabilidad!=null && doc.tipoDeContabilidad!='' && 
               codigosContables.containsKey(doc.tipoDeContabilidad)) {
                   
                if(codigosContables.get(doc.tipoDeContabilidad).toLowerCase()=='suma') {
                    saldo+=doc.importeDecimal;
                } else if (codigosContables.get(doc.tipoDeContabilidad).toLowerCase()=='resta') {
                    saldo-=doc.importeDecimal;
                } else {
                return 'ERROR: La configuracion del codigo '+doc.tipoDeContabilidad+' tiene errores'+
                        '. Contacte con el administrador del sistema.';
                }
                   
            } else if(doc.tipoDeContabilidad==null || doc.tipoDeContabilidad=='') {
                return 'ERROR: Falta el campo "Tipo de contabilidad" en algun documento'+
                        '. Contacte con el administrador del sistema.';
            } else {
                return 'ERROR: No se tiene registrado el codigo de contabilidad '+doc.tipoDeContabilidad+
                        '. Contacte con el administrador del sistema.';
            }
        }
        
        return 'Su saldo es: $'+String.valueOf( saldo.setScale(2) );
    }}
    
    @AuraEnabled public String recordTypeId;

    @AuraEnabled public DocumentoContable[] facturas {get{
		return buscarContratos( documentosPorTipo('Factura') );
    }}

    @AuraEnabled public DocumentoContable[] pagos {get{
      	return documentosPorTipo('Pago');
    }}

    @AuraEnabled public DocumentoContable[] notasDeCredito {get{
      	return documentosPorTipo('Nota de Credito');
    }}
    
    
    @AuraEnabled public Factura[] facturasConAdjuntos {get{
        List<Factura> facturasCompletas = new List<Factura>();
        
        for (DocumentoContable documento : facturas) {
            List<DocumentoContable> pagos = buscarPagos(documento, this.pagos);
            List<DocumentoContable> notas = buscarPagos(documento, this.notasDeCredito);       
            
            facturasCompletas.add( contarFactura 
                                  (new Factura( documento,   notas,    pagos )));
        }
        
        return facturasCompletas;
        
    }}
	
    @AuraEnabled public DocumentoContable[] notasDeCreditoSueltas {get{
        return buscarSueltos(facturas, notasDeCredito);
    }}
    
    @AuraEnabled public DocumentoContable[] pagosSueltos {get{
        return buscarSueltos(facturas, pagos);
    }}
    
    @AuraEnabled public String mensaje {get; set;}


    private DocumentoContable[] documentosPorTipo(String tipo) {
      
		DocumentoContable[] out = new DocumentoContable[]{};
		if (documentos == null) return out;

		for (DocumentoContable documento : documentos) {
            if (documento.tipo == tipo) {
                  out.add(documento);
                  documento.recordTypeId =recordTypeId;
                }
      	}
      	return ordernarDocumentos( out );
    }
    
    @AuraEnabled public static DocumentoContable[] buscarPagos(DocumentoContable factura, DocumentoContable[] pagos) {
        List<DocumentoContable> pagosDeFactura = new List<DocumentoContable>();
        for (integer i=0; i<pagos.size(); i++) {
            if (factura.PagoAFactura==pagos[i].PagoAFactura && pagos[i].PagoAFactura!=null && factura.PagoAFactura!=null) {
                pagosDeFactura.add(pagos[i]);
                pagos.remove(i);
              	i--;
            } 
        }
        return pagosDeFactura;
    }
	@AuraEnabled public static DocumentoContable[] buscarSueltos(DocumentoContable[] facturas, DocumentoContable[] pagos) {
        for (DocumentoContable factura : facturas) {
            for (integer i=0; i<pagos.size(); i++) {
                if (factura.PagoAFactura==pagos[i].PagoAFactura && pagos[i].PagoAFactura!=null && factura.PagoAFactura!=null) {
                        pagos.remove(i);
                        i--;
                } 
            }
        }
        return pagos;
    }
	

    @AuraEnabled public static DocumentoContable[] buscarContratos(DocumentoContable[] facturas) {	          
        Map<String, DocumentoContable> documentosConNumeroDeContrato = new Map<String, DocumentoContable>();
        for(DocumentoContable factura : facturas) {
            documentosConNumeroDeContrato.put(factura.numeroDeContrato, factura);
        }
        List<Contrato__c> contratos = [
			SELECT Id, Numero_Unico_de_Contrato_Con_Sufijo__c
			FROM Contrato__c 
			WHERE Numero_Unico_de_Contrato_Con_Sufijo__c IN :documentosConNumeroDeContrato.keySet()
		];
        
        
        for(Contrato__c contrato : contratos) {
            for (DocumentoContable factura : facturas) {
                if(factura.numeroDeContrato==contrato.Numero_Unico_de_Contrato_Con_Sufijo__c) {
                    factura.Contrato=contrato.id;
                }
            }
        }

        return facturas;
	}

    @AuraEnabled public static Factura contarFactura(Factura facturaCompleta) {	
        decimal sumaDePagos=0;
        for(DocumentoContable notaDeCredito : facturaCompleta.notasDeCredito) {
            sumaDePagos+=notaDeCredito.importeDecimal;
        }
         for(DocumentoContable pago : facturaCompleta.Pagos) {
            sumaDePagos+=pago.importeDecimal;
        }
        facturaCompleta.documento.pagado = ( sumaDePagos>= facturaCompleta.documento.importeDecimal);
        
    	return facturaCompleta;
    }
    
    @AuraEnabled public static DocumentoContable[]  ordernarDocumentos(DocumentoContable[] documentos) {
        for (integer i=0; i<documentos.size(); i++) {
            DocumentoContable intercambiador;
            Date fechMasReciente = Date.today().addYears(-200);
            integer posicion;
            for (integer j=i; j<documentos.size(); j++) {
                if(Documentos[j].fechaDocumento > fechMasReciente) {
                    posicion=j;
                    fechMasReciente=Documentos[j].fechaDocumento;
                }
        	}
            if (posicion!=null) {
                intercambiador = Documentos[i];
                Documentos[i] = Documentos[posicion];
                Documentos[posicion] = intercambiador;
			}
        }
        
    	return documentos;
    }
    
 }
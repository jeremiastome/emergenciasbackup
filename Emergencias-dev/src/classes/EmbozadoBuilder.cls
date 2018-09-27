public class EmbozadoBuilder {

	private static final String CONTROL_CHAR = 'B';
	private static final String SEPARACION_TRACK1_CHAR = '^';
	private static final String SEPARACION_TRACK2_CHAR = '=';
	private static final String NUMERO_COMERCIO = '610361';
	private static final String SERV_CODE = '101';

	public Beneficiario__c beneficiario {get; set;}
	private Integer ver {get; set;}
	public Integer numero {get; set;}
	private String tipoPedido {get; set;}
	private String nombrePlan {get; set;}
	private Id caso {get; set;}

	public EmbozadoBuilder() {}

	public EmbozadoBuilder(Integer numero) {
		this.numero = numero++;
	}

	/*public EmbozadoBuilder(Beneficiario__c beneficiario, Integer numero, String nombrePlan, String tipo, Id caso) {
		this.beneficiario = beneficiario;
		this.numero = numero;
		this.ver = beneficiario.Version__c.intValue() + 1;
		this.tipoPedido = tipo;
		this.nombrePlan = nombrePlan;
		this.caso = caso;
	}

	borre el Id caso
  public EmbozadoBuilder(Beneficiario__c beneficiario, Integer numero, String nombrePlan, ) {
	this(beneficiario, numero, nombrePlan, 'Automático');
  }

  public EmbozadoBuilder(Beneficiario__c beneficiario, Integer numero, String nombrePlan, Id caso, String tipo) {
	this.beneficiario = beneficiario;
	this.numero = numero;
	this.ver = beneficiario.Version__c.intValue() + 1;
	this.tipoPedido = tipo;
	this.nombrePlan = nombrePlan;
	this.caso = caso;
  }*/

	public Pedido_de_Embozado__c obtenerPedido(Beneficiario__c beneficiario, String nombrePlan, Id caso, String tipo) {

		this.beneficiario = beneficiario;
		this.ver = beneficiario.Version__c.intValue() + 1;
		this.tipoPedido = tipo;
		this.nombrePlan = nombrePlan;
		this.caso = caso;
		return obtenerPedido();
	}

	public Pedido_de_Embozado__c obtenerPedido() {

		Pedido_de_Embozado__c pedido = new Pedido_de_Embozado__c();
		Beneficiario__c beneficiarioAActualizar = new Beneficiario__c(Id = beneficiario.Id);

		pedido.Beneficiario__c = beneficiario.Id;
		pedido.Estado__c = 'Pendiente';

		if(beneficiario.TRACK_1__c == null){
			pedido.TRACK1__c = obtenerTrack1();
			beneficiarioAActualizar.TRACK_1__c = pedido.TRACK1__c;
		} else {
			pedido.TRACK1__c = beneficiario.TRACK_1__c;
		}

		if(beneficiario.TRACK_2__c == null){
			pedido.TRACK2__c = obtenerTrack2();
			beneficiarioAActualizar.TRACK_2__c = pedido.TRACK2__c;
		} else {
			pedido.TRACK2__c = beneficiario.TRACK_2__c;
		}

		if(beneficiario.Numero_Club_de_Emergencias__c == null){
			pedido.Numero_de_Club_Emergencias__c = obtenerNumeroClubEmergencias();
			beneficiarioAActualizar.Numero_Club_de_Emergencias__c = pedido.Numero_de_Club_Emergencias__c;
			this.numero ++;
		} else {
			pedido.Numero_de_Club_Emergencias__c = beneficiario.Numero_Club_de_Emergencias__c;
		}
		

		pedido.Tipo_de_Embozado__c = tipoPedido;
		pedido.Nombre_del_Plan__c = nombrePlan.toUpperCase();
		pedido.caso__c = this.caso;
		
		//update beneficiarioAActualizar;
		
		return pedido;
	}

	@testVisible
	private String obtenerTrack1() {

		String track1 = CONTROL_CHAR;
		track1 += obtenerNumeroCredencial(ver, numero);
		track1 += SEPARACION_TRACK1_CHAR;
		track1 += obtenerNombreUsuario(beneficiario);
		track1 += SEPARACION_TRACK1_CHAR;
		track1 += obtenerFechaDeVencimiento(beneficiario);
		track1 += SERV_CODE;

		return track1;
	}

	@testVisible
	private String obtenerTrack2() {

		String track2 = obtenerNumeroCredencial(ver, numero);
		track2 += SEPARACION_TRACK2_CHAR;
		track2 += obtenerFechaDeVencimiento(beneficiario);
		track2 += SERV_CODE;

		return track2;
	}

	private String obtenerNumeroClubEmergencias() {
		return obtenerNumeroCredencial(ver, numero);
	}

	private Integer obtenerCodigoVerificador(String numeroTarjeta) {

		Integer[] digitosASumar = new Integer[] {};

		// Por cada caracter contando desde el final
		for (Integer i = numeroTarjeta.length() - 1; i >= 0; i--) {

			Integer valor = Integer.valueOf(numeroTarjeta.substring(i, i + 1));

			// Si esta en una posicion par, lo multiplico por 2
			if (Math.mod(i, 2) == 0) {
				valor *= 2;
			}

			// Agrego el digito a sumar
			if (valor > 9) {

				// Si el valor en la posicion tiene 2 digitos, los agrego por separado
				digitosASumar.add(1);
				digitosASumar.add(Math.mod(valor, 10));

			} else {

				digitosASumar.add(valor);
			}
		}

		// Sumo todos los digitos
		Integer sumatoria = 0,
		codVerificador;

		for (Integer digitoASumar: digitosASumar) {
			sumatoria += digitoASumar;
		}

		// Asigno el codigo verificador como la diferencia del valor divisible por 10 
		// superior a la sumatoria con la sumatoria en si.
		// Ej: sumatoria = 29, valorSuperior = 30, codVerificador = 30 - 29; 
		if (Math.mod(sumatoria, 10) > 0) {

			Integer valorSup = sumatoria + (10 - Math.mod(sumatoria, 10));
			codVerificador = valorSup - sumatoria;

		} else {

			// Si a sumatoria es divisible por 10, entonces el codigo es 0.
			codVerificador = 0;
		}

		return codVerificador;
	}

	private String obtenerVersion(Integer ver) {

		if (ver > 99) ver = 99;

		return String.valueOf(ver).leftPad(2, '0');
	}

	@testVisible
	private String obtenerNumeroCredencial(Integer ver, Integer numeroTarjeta) {

		String tarjeta = String.valueOf(numeroTarjeta).leftPad(10, '0');

		String credencial = NUMERO_COMERCIO;
		credencial += obtenerVersion(ver);
		credencial += tarjeta;
		credencial += obtenerCodigoVerificador(credencial);

		return credencial;
	}

	@testVisible
	private String obtenerNombreUsuario(Beneficiario__c beneficiario) {

		String nombreFormateado = (!String.isBlank(beneficiario.Nombre__c)) ? beneficiario.Nombre__c: '';
		String apellidoFormateado = (!String.isBlank(beneficiario.Apellido__c)) ? beneficiario.Apellido__c: '';
		String nombreCompleto = nombreFormateado.toUpperCase() + ' ' + apellidoFormateado.toUpperCase();

		if (nombreCompleto.length() > 26) nombreCompleto = nombreCompleto.substring(0, 26);
		nombreCompleto = Utils.toAsciiSiete(nombreCompleto);

		return nombreCompleto.rightPad(26);
	}

	@testVisible
	private String obtenerFechaDeVencimiento(Beneficiario__c beneficiario) {

		Datetime fecha = Datetime.newInstance(
		Date.newInstance(2050, 1, 1), Time.newInstance(0, 0, 0, 0));

		return fecha.format('yyMM');
	}
}
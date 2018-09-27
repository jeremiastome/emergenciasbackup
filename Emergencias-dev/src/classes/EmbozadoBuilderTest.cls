@isTest
public class EmbozadoBuilderTest  {

  static testMethod void sePuedeGenerarUnPedidoDeEmbozado() {

	//EmbozadoBuilder builder = new EmbozadoBuilder(beneficiario, 2, 'PLAN 100', 'Manual', caso.Id);
	EmbozadoBuilder builder = new EmbozadoBuilder(2);


	Test.startTest();
	Pedido_de_Embozado__c pedido = builder.obtenerPedido(beneficiario,'Plan 100', caso.Id, 'Manual');
	Test.stopTest();

	System.assertEquals(beneficiario.Id, pedido.Beneficiario__c);
	System.assertEquals('Manual', pedido.Tipo_de_Embozado__c);
	System.assertEquals('B6103610100000000026^MIRO MARUIN               ^5001101', pedido.TRACK1__c);
	System.assertEquals('6103610100000000026=5001101', pedido.TRACK2__c);
	System.assertEquals('6103610100000000026', pedido.Numero_de_Club_Emergencias__c);
	System.assertEquals('Pendiente', pedido.Estado__c);
	System.assertEquals('PLAN 100', pedido.Nombre_del_Plan__c);
	System.assertEquals(caso.Id, pedido.Caso__c);
  }

  static testMethod void sePuedeObtenerElTrack1DeLaCredencial() {

	//EmbozadoBuilder builder = new EmbozadoBuilder(beneficiario, 2, 'PLAN 100', caso.Id);
	EmbozadoBuilder builder = new EmbozadoBuilder(2);
    Pedido_de_Embozado__C pedido = builder.obtenerPedido(beneficiario,'Plan 100', caso.Id, 'Manual');
	Test.startTest();
	System.assertEquals('B6103610100000000026^MIRO MARUIN               ^5001101', pedido.Track1__c);
	Test.stopTest();
  }

  static testMethod void sePuedeObtenerElTrack2DeLaCredencial() {

	//EmbozadoBuilder builder = new EmbozadoBuilder(beneficiario, 2, 'PLAN 100', caso.Id);
	EmbozadoBuilder builder = new EmbozadoBuilder(2);
    Pedido_de_embozado__C pedido = builder.obtenerPedido(beneficiario,'Plan 100',caso.Id,'Manual');


	Test.startTest();
	System.assertEquals('6103610100000000026=5001101', pedido.Track2__c);
	Test.stopTest();
  }

  static testMethod void sePuedeObtenerElNumeroDeCredencialConSuCodigoVerificador() {

	EmbozadoBuilder builder = new EmbozadoBuilder(2);
    Pedido_de_embozado__c pedido = builder.obtenerPedido(beneficiario,'Plan 100',caso.Id, 'Manual');

	Test.startTest();
	System.assertEquals('6103610100000000026', pedido.Numero_de_club_emergencias__C);
	Test.stopTest();
  }

  static testMethod void sePuedeObtenerLaFechaDeVencimientoDeLaCredencial() {

	//EmbozadoBuilder builder = new EmbozadoBuilder(beneficiario, 1, 'PLAN 100', caso.Id);
	EmbozadoBuilder builder = new EmbozadoBuilder(2);
    Pedido_de_embozado__C pedido = builder.obtenerPedido(beneficiario,'Plan 100', caso.Id, 'Manual');

	Test.startTest();
	System.assertEquals('5001', builder.obtenerFechaDeVencimiento(beneficiario));
	Test.stopTest();
  }

  static testMethod void sePuedeObtenerElNombreDelBeneficiarioFormateadoEn26Caracteres() {

	//EmbozadoBuilder builder = new EmbozadoBuilder(beneficiario, 1, 'PLAN 100', caso.Id);
	EmbozadoBuilder builder = new EmbozadoBuilder(2);
    Pedido_de_embozado__c pedido = builder.obtenerPedido(beneficiario,'Plan 100',caso.Id,'Manual');
	Test.startTest();
	System.assertEquals('A B                       ', builder.obtenerNombreUsuario(cambiarNombreABeneficiario('a', 'b')));
	System.assertEquals('NNOI B                    ', builder.obtenerNombreUsuario(cambiarNombreABeneficiario('ññóí', 'b')));
	System.assertEquals('UNNOMBREQUETIENEQUESER MUY', builder.obtenerNombreUsuario(cambiarNombreABeneficiario('Unnombrequetienequeser', 'Muylargoparamostrar')));
	Test.stopTest();
  }

  static testMethod void sePuedeObtenerElNombreDelBeneficiarioFormateadoEnAscii7() {

	//EmbozadoBuilder builder = new EmbozadoBuilder(beneficiario, 1, 'PLAN 100', caso.Id);
	EmbozadoBuilder builder = new EmbozadoBuilder(2);
    Pedido_de_embozado__c pedido = builder.obtenerPedido(beneficiario,'Plan 100',caso.Id,'Manual');

	Test.startTest();
	System.assertEquals('\'                         ', builder.obtenerNombreUsuario(cambiarNombreABeneficiario('´', '`')));
	System.assertEquals('NNOI B                    ', builder.obtenerNombreUsuario(cambiarNombreABeneficiario('ññóì', 'b')));
	Test.stopTest();
  }

  static Beneficiario__c cambiarNombreABeneficiario(String nombre, String apellido) {

	cuentaBeneficiario.FirstName = nombre;
	cuentaBeneficiario.LastName = apellido;
	update cuentaBeneficiario;

	return [SELECT Nombre__c, Apellido__c, Version__c FROM Beneficiario__c WHERE Id = :beneficiario.Id];
  }

  static Account cuentaBeneficiario;
  static Beneficiario__c beneficiario;
  static Case caso;

  static {

	Id opportunityType = [
	  SELECT Id
	  FROM RecordType
	  WHERE sObjectType = 'Opportunity'
		AND IsActive = true
		AND DeveloperName = 'Venta_Consumidor_Final'
	  LIMIT 1
	].Id;

	caso = Build.aCase().build();
	insert caso;

	Account cuenta = Build.anAccount().isPersonAccount().build();
	cuentaBeneficiario = Build.anAccount()
	  .isPersonAccount()
	  .withRandomCUILCUIT()
	  .withFirstName('MIRO')
	  .withLastName('MARUIN')
	  .build();
	insert new Account[] { cuenta, cuentaBeneficiario };

	Opportunity oportunidad = Build.anOpportunity()
	  .forAccount(cuenta)
	  .withDischargeTypeNew()
	  .withRecordTypeId(opportunityType)
	  .build();
	insert oportunidad;

	Contrato__c contrato = [//Created by a trigger
	  SELECT Id
	  FROM Contrato__c
	  WHERE Id IN (SELECT Contrato__c FROM Opportunity WHERE Id = :oportunidad.Id)
	];

	Titular__c titular = [//Created by a process
	  SELECT Id, Numero_de_Titular__c, Ult_Numero_de_beneficiario__c
	  FROM Titular__c
	  WHERE Contrato__c = :contrato.Id
	];

	beneficiario = Build.aRecipient().
	  forAccount(cuentaBeneficiario).
	  forHolder(titular).
	  forContract(contrato).
	  build();
	insert beneficiario;

	beneficiario = [SELECT Nombre__c, Apellido__c,Track_1__c,Track_2__c,numero_club_de_emergencias__c, Version__c FROM Beneficiario__c WHERE Id = :beneficiario.Id];
  }
}
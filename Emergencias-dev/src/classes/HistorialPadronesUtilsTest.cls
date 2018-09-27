@isTest
public class HistorialPadronesUtilsTest {

	private static testMethod void  whenIRegisterAnUpdateOfANewPadron_anHistorialDePadronIsSaved() {
		aRecpientCoverage.Cantidad_de_Padron__c = 1234;

		List<HistorialPadron> historialAGuardar =
			new List<HistorialPadron>();

		HistorialPadron nuevoHistorial = new HistorialPadron(
			'Producto test',
			'Capital Federal',
			Date.newInstance(2015, 5, 3),
			aRecpientCoverage,
			false);
		historialAGuardar.add(nuevoHistorial);
		Map<Id, Decimal> oldValuesPadron = new Map<Id, Decimal>();

		Test.StartTest();
		HistorialPadronesUtils.registrarActualizacion(
			historialAGuardar,
			oldValuesPadron,
			aContract.id);
		Test.StopTest();

		List<Historial_de_Padron__c> historiales = [SELECT id,
			Tipo_de_operacion__c, Cantidad_de_capitas__c,
			Contrato__c, Producto__c, Provincia__c,
			Fecha_de_padron__c
			FROM Historial_de_Padron__c];

		System.assertEquals(1234, historiales[0].Cantidad_de_capitas__c);
		System.assertEquals('Creacion', historiales[0].Tipo_de_operacion__c);
		System.assertEquals(aContract.id, historiales[0].Contrato__c);
		System.assertEquals('Producto test', historiales[0].Producto__c);
		System.assertEquals('Capital Federal', historiales[0].Provincia__c);
		System.assertEquals(Date.newInstance(2015, 5, 3), historiales[0].Fecha_de_padron__c);
	}

	private static testMethod void  whenTheValueOfCantidadDePadronIsNotChanged_anHistorialDePadronIsNotSaved() {

		aRecpientCoverage.Cantidad_de_Padron__c = 1234;
		insert aRecpientCoverage;
		List<HistorialPadron> historialAGuardar =
			new List<HistorialPadron>();

		HistorialPadron nuevoHistorial = new HistorialPadron(
			'Producto test',
			'Capital Federal',
			null,
			aRecpientCoverage,
			false);
		historialAGuardar.add(nuevoHistorial);
		Map<Id, Decimal> oldValuesPadron = new Map<Id, Decimal>();
		oldValuesPadron.put(aRecpientCoverage.id, 1234);

		Test.StartTest();
		HistorialPadronesUtils.registrarActualizacion(
			historialAGuardar,
			oldValuesPadron,
			aContract.id);
		Test.StopTest();

		List<Historial_de_Padron__c> historiales = [SELECT id FROM Historial_de_Padron__c];

		System.assertEquals(0, historiales.size());
	}

	private static testMethod void  whenTheValueOfCantidadDePadronIsChanged_anHistorialDePadronIsSaved() {
		aRecpientCoverage.Cantidad_de_Padron__c = 1000;
		insert aRecpientCoverage;
		List<HistorialPadron> historialAGuardar =
			new List<HistorialPadron>();

		HistorialPadron nuevoHistorial = new HistorialPadron(
			'Producto test',
			'Capital Federal',
			Date.newInstance(2015, 5, 3),
			aRecpientCoverage,
			false);
		historialAGuardar.add(nuevoHistorial);
		Map<Id, Decimal> oldValuesPadron = new Map<Id, Decimal>();

		HistorialPadronesUtils.registrarActualizacion(
			historialAGuardar,
			oldValuesPadron,
			aContract.id);

		aRecpientCoverage.Cantidad_de_Padron__c = 1234;
		nuevoHistorial.fechaDePadron = Date.newInstance(2016, 7, 1);
		oldValuesPadron.put(aRecpientCoverage.id, 1000);
		Test.StartTest();
		HistorialPadronesUtils.registrarActualizacion(
			historialAGuardar,
			oldValuesPadron,
			aContract.id);
		Test.StopTest();

		List<Historial_de_Padron__c> historiales = [SELECT id,
			Tipo_de_operacion__c, Cantidad_de_capitas__c, Contrato__c,
			Producto__c, Provincia__c,
			Fecha_de_padron__c
			FROM Historial_de_Padron__c];

		System.assertEquals(2, historiales.size());
		System.assertEquals(1000, historiales[0].Cantidad_de_capitas__c);
		System.assertEquals('Creacion', historiales[0].Tipo_de_operacion__c);
		System.assertEquals(aContract.id, historiales[0].Contrato__c);
		System.assertEquals('Producto test', historiales[0].Producto__c);
		System.assertEquals('Capital Federal', historiales[0].Provincia__c);
		System.assertEquals(Date.newInstance(2015, 5, 3), historiales[0].Fecha_de_padron__c);

		System.assertEquals(1234, historiales[1].Cantidad_de_capitas__c);
		System.assertEquals('Modificacion', historiales[1].Tipo_de_operacion__c);
		System.assertEquals(aContract.id, historiales[1].Contrato__c);
		System.assertEquals('Producto test', historiales[1].Producto__c);
		System.assertEquals('Capital Federal', historiales[1].Provincia__c);
		System.assertEquals(Date.newInstance(2016, 7, 1), historiales[1].Fecha_de_padron__c);
	}

	private static testMethod void  whenARecpientCoverageIsDeleted_anHistorialDePadronIsSaved() {
		aRecpientCoverage.Cantidad_de_Padron__c = 1000;
		insert aRecpientCoverage;
		List<HistorialPadron> historialAGuardar =
			new List<HistorialPadron>();

		HistorialPadron nuevoHistorial = new HistorialPadron(
			'Producto test',
			'Capital Federal',
			Date.newInstance(2016, 7, 1),
			aRecpientCoverage,
			true);
		historialAGuardar.add(nuevoHistorial);

		Map<Id, Decimal> oldValuesPadron = new Map<Id, Decimal>();

		Test.StartTest();
		HistorialPadronesUtils.registrarActualizacion(
			historialAGuardar,
			oldValuesPadron,
			aContract.id);
		Test.StopTest();

		List<Historial_de_Padron__c> historiales = [SELECT id,
			Tipo_de_operacion__c, Cantidad_de_capitas__c,
			Contrato__c, Producto__c, Provincia__c,
			Fecha_de_padron__c
			FROM Historial_de_Padron__c];

		System.assertEquals(1, historiales.size());
		System.assertEquals(1000, historiales[0].Cantidad_de_capitas__c);
		System.assertEquals('Eliminacion', historiales[0].Tipo_de_operacion__c);
		System.assertEquals(aContract.id, historiales[0].Contrato__c);
		System.assertEquals('Producto test', historiales[0].Producto__c);
		System.assertEquals('Capital Federal', historiales[0].Provincia__c);
		System.assertEquals(Date.newInstance(2016, 7, 1), historiales[0].Fecha_de_padron__c);
	}

	static Product2 aProduct;
	static Account anAccount;
	static Contrato__c aContract;
	static Cobertura__c aCoverage;
	static Titular__c aHolder;
	static Beneficiario__c aRecipient;
	static Cobertura_de_Beneficiario__c aRecpientCoverage;

	static {
		aProduct = Build.aProduct().build();
		insert aProduct;
		anAccount = Build.anAccount().build();
		insert anAccount;
		aContract = Build.aContract().forAccount(anAccount).withUniqueNumber().build();
		insert aContract;
		aHolder = Build.aHolder().forContract(aContract).forAccount(anAccount).build();
		insert aHolder;
		aRecipient = Build.aRecipient().forContract(aContract)
			.forAccount(anAccount).forHolder(aHolder).withCensusDate(System.today().addDays(-3))
			.build();
		insert aRecipient;
		aCoverage = Build.aCoverage().forContract(aContract).forProduct(aProduct).build();
		insert aCoverage;

		aRecpientCoverage = Build.aCoverageRecipientRelation()
		.forRecipient(aRecipient).forCoverage(aCoverage).withIVATreatmentExempt().withAmountForMassiveRecipient(30).build();
	}
}
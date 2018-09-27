public class GeneratePDFcontractController {
	//==========================================================================
	// Strart Declaration of Variables
	//==========================================================================
	Public String idOfContract { get; set; }
	Public Contrato__c Contrato { get; set; }
	Public Account clietOfContract { get; set; }

	Public Integer day { get; set; }
	Public Integer month { get; set; }
	Public String monthString { get; set; }
	Public Integer Year { get; set; }

	Public Boolean haveBeneficiarios { get; set; }
	Public Boolean havePorduct { Get; set; }

	Public Boolean haveHogarProtegido { get; set; }
	Public Boolean haveAreaProtegida { get; set; }
	Public Boolean haveEmerphone { get; set; }
	Public Boolean haveAutoProtegido { get; set; }
	Public Boolean haveMedicinaEmpresarial { get; set; }
	Public Boolean haveVisitorCard { get; set; }
	Public Boolean haveServicioEca { get; set; }

	Public List<Beneficiario__c> ListBeneficiariosOfContract { get; Set; }
	Public List<Cobertura__c> ListProductOfContract { get; set; }
	Public List<Product2> ListProducts { get; set; }
	Public List<Beneficiario__c> listOfBeneficiariosToPageHogarProtegido { get; set; }
	Public List<Beneficiario__c> listOfBeneficiariosCar { get; set; }
	Public List<Servicio__c> listOfServicios {get; set;}

	Private Map<String, String> meses;
	//id=a010v000001FamkAAC sin beneficiario
	//id=a010v000001FfBpAAK con beneficiario
	//a010v000001GaFZAA0	
	//==========================================================================
	// En Declaration of Variables
	//==========================================================================


	//==========================================================================
	// Strart Constructor
	//==========================================================================
	public GeneratePDFcontractController() {
		haveHogarProtegido = false;
		haveAreaProtegida = false;
		haveAutoProtegido = false;
		haveEmerphone = false;
		haveAutoProtegido = false;
		haveMedicinaEmpresarial = false;
		haveVisitorCard = false;
		haveServicioEca = false;
		listOfBeneficiariosToPageHogarProtegido = new List<Beneficiario__c> ();
		listOfBeneficiariosCar = new List<Beneficiario__c> ();
		listOfServicios = new List<Servicio__c> ();

		idOfContract = ApexPages.currentPage().getParameters().get('ID');

		Contrato = [SELECT name, Cliente__c, Numero_Unico_de_Contrato__c, Numero_unico_de_contrato_numero__c
		            FROM Contrato__c
		            WHERE ID = :idOfContract
		            LIMIT 1];

		clietOfContract = [SELECT name FROM Account
		                   WHERE ID = :Contrato.Cliente__c
		                   LIMIT 1];

		date currentDay = date.today();

		day = currentDay.day();
		month = currentDay.month();
		Year = currentDay.year();

		meses = new Map<String, String> ();
		meses.put('1', 'Enero');
		meses.put('2', 'Febrero');
		meses.put('3', 'Marzo');
		meses.put('4', 'Abril');
		meses.put('5', 'Mayo');
		meses.put('6', 'Junio');
		meses.put('7', 'Julio');
		meses.put('8', 'Agosto');
		meses.put('9', 'Septiembre');
		meses.put('10', 'Octubre');
		meses.put('11', 'Noviembre');
		meses.put('12', 'Diciembre');

		monthString = meses.get(String.valueOf(month));

		ListBeneficiariosOfContract = [SELECT Provincia1__c, Calle__c, Altura__c, Partido__c FROM Beneficiario__c
		                               WHERE Contrato__c = :idOfContract];

		ListProductOfContract = [SELECT ID, name, Producto__c, Precio_total__c, Precio_de_venta__c, Precio_abono__c
		                         FROM Cobertura__c
		                         WHERE Contrato__c = :idOfContract];
		IF (ListProductOfContract.size() != 0) {
			havePorduct = true;
			For (Cobertura__c PorducOfCOntrat : ListProductOfContract) {
				Product2 product = [SELECT id, name FROM Product2
				                    WHERE ID = :PorducOfCOntrat.Producto__c
				                    LIMIT 1];

				IF (product.name.contains('Hogar Protegido')) {
					haveHogarProtegido = true;
					List<Cobertura_de_Beneficiario__c> ListBeneficiadosProduct = [SELECT Beneficiario__c FROM Cobertura_de_Beneficiario__c
					                                                              WHERE Cobertura__c = :PorducOfCOntrat.id];
					For (Cobertura_de_Beneficiario__c cobBen : ListBeneficiadosProduct) {
						Beneficiario__c beneficiarioOfHogarProtegido = [SELECT Provincia1__c, Calle__c, Altura__c, Ciudad__c, Partido__c
						                                                FROM Beneficiario__c
						                                                WHERE id = :cobBen.Beneficiario__c];
						listOfBeneficiariosToPageHogarProtegido.add(beneficiarioOfHogarProtegido);
					}
				}
				IF (product.name.contains('Area Protegida')) {
					haveAreaProtegida = true;
				}
				IF (product.name.contains('Emerphone')) {
					haveEmerphone = true;
				}
				IF (product.name.contains('Auto Protegido')) {
					haveAutoProtegido = true;
					List<Cobertura_de_Beneficiario__c> ListBeneficiadosProduct = [SELECT Beneficiario__c FROM Cobertura_de_Beneficiario__c
					                                                              WHERE Cobertura__c = :PorducOfCOntrat.id];
					For (Cobertura_de_Beneficiario__c cobBen : ListBeneficiadosProduct) {
						Beneficiario__c beneficiarioOfCar = [SELECT Patente_del_auto__c, name
						                                     FROM Beneficiario__c
						                                     WHERE id = :cobBen.Beneficiario__c];
						//beneficiarioOfCar.Patente_del_auto__c = 'Kem066';
						System.debug('car ' + beneficiarioOfCar);
						listOfBeneficiariosCar.add(beneficiarioOfCar);
					}
				}
				IF (product.name.contains('MEDICINA EMPRESARIAL')) {
					haveMedicinaEmpresarial = true;
					//agregar el tema de los servicios de la SOQL deben ser como 2
					List<Servicio_de_Producto__c> servicioOfProduct = [SELECT ID,Servicio__c FROM Servicio_de_Producto__c
					                                                   WHERE Producto__c = :product.Id];
					For(Servicio_de_Producto__c servicio :servicioOfProduct){
						Servicio__c serv = [SELECT Name FROM Servicio__c WHERE Id =: servicio.Servicio__c];
						listOfServicios.add(serv);
					}
				}
				IF (product.name.contains('Visitor Card')) {
					haveVisitorCard = true;
				}
				IF (product.name.contains('Servicio ECA')) {
					haveServicioEca = true;
				}

			}
		}

		//Domicilio 1: Provincia, partido localidad, calle + altura

	}
	//==========================================================================
	// End Constructor
	//==========================================================================

}
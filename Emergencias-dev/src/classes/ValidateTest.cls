@isTest
private class ValidateTest {
	private static testMethod void testCBU() {
		//cbus correctos
		System.assertEquals(Validate.CBU('2850590940090418135201'), true);
		System.assertEquals(Validate.CBU('2850100640094040123748'), true);
		System.assertEquals(Validate.CBU('0440053040000160557800'), true);
		System.assertEquals(Validate.CBU('0440024040000165916790'), true);
		System.assertEquals(Validate.CBU('044-0024-0400-0016-5916-790'), true);
		//cbus incorrectos
		System.assertEquals(Validate.CBU('0170099220000067797371'), false);
		System.assertEquals(Validate.CBU('0850100640094040123748'), false);
		System.assertEquals(Validate.CBU('0440053040002160557801'), false);
		System.assertEquals(Validate.CBU('04400530400021605'), false);
		System.assertEquals(Validate.CBU(null), false);
		System.assertEquals(Validate.CBU('044005304000216055A801'), false);
		System.assertEquals(Validate.CBU(null), false);
		
		
	}
	
	private static testMethod void testVisa() {
		//tarjetas correctas
		system.assertEquals(Validate.visa('4398728045218854'), true);
		system.assertEquals(Validate.visa('4667858768964691'), true);
		//tarjetas incorrectas
		system.assertEquals(Validate.visa('4667858768964690'), false);
		system.assertEquals(Validate.visa('0850100640094040123748'), false);
		system.assertEquals(Validate.visa(''), false);
		system.assertEquals(Validate.visa(null), false);
	}
	
	private static testMethod void testCardNumber() {
		//tarjetas correctas
		system.assertEquals(true, Validate.cardNumber('4398728045218854'));
		system.assertEquals(true, Validate.cardNumber('4667858768964691'));
		system.assertEquals(true, Validate.cardNumber('5028276435949634'));
		system.assertEquals(true, Validate.cardNumber('5980289411573076'));
		system.assertEquals(true, Validate.cardNumber('4667858768964691'));
		
		system.assertEquals(true, Validate.cardNumber('371449635398431'));
		//tarjetas incorrectas
		system.assertEquals(false, Validate.cardNumber('0850100640094040123748'));
		system.assertEquals(false, Validate.cardNumber('0876543210'));
		system.assertEquals(false, Validate.cardNumber(''));
		system.assertEquals(false, Validate.cardNumber(null));
		system.assertEquals(false, Validate.cardNumber('6980289411573076'));
		system.assertEquals(false, Validate.cardNumber('6980289411573076'));
        

	}
    private static testMethod void testCardNumbersByType () {
        		/// Master
		system.assertEquals(true, validate.cardNumberWithType('5103138076353435', '0004'));
		system.assertEquals(false, validate.cardNumberWithType('340000000000009', '0004'));
        
                /// Visa
        system.assertEquals(true, validate.cardNumberWithType( '4667858768964691', '0002'));
		system.assertEquals(false, validate.cardNumberWithType( '4667858768964690', '0002'));
        
                /// American Express
		system.assertEquals(true, validate.cardNumberWithType( '343588229048665', '0005'));
		system.assertEquals(false, validate.cardNumberWithType( '4667858768964690', '0005'));
        
                /// Cabal
		system.assertEquals(true, validate.cardNumberWithType( '6012345678912345', '0006'));
		system.assertEquals(false, validate.cardNumberWithType( '4667858768964690', '0006'));
        
                /// Carreful
		system.assertEquals(true, validate.cardNumberWithType( '8581845845845841', '0017'));
		system.assertEquals(false, validate.cardNumberWithType( '4667858768964690', '0017'));	
        
        		/// Diners
		System.assertEquals(false,validate.cardNumberWithType( '340000000000009', '0001'));	
		System.assertEquals(true,validate.cardNumberWithType( '30123456789134', '0001'));	
        
        
        
        
    }

	private static testMethod void testNSPNumber(){
		//Only if the number has 13 of size
		system.assertEquals(Validate.NSPNumber('1234567890123'), true);
		system.assertEquals(Validate.NSPNumber('12347890123'), false);
	}
	
	private static testMethod void testCobisNumber(){
		//Only if the number has 10 of size
		system.assertEquals(Validate.CobisNumber('1234567890'), true);
		system.assertEquals(Validate.CobisNumber('123478901233243'), false);
	}
	
	private static testMethod void testNaranja() {
		//tarjetas correctas
		system.assertEquals(true, Validate.naranja('4398728045218850'));
		system.assertEquals(true, Validate.naranja('4667858768964694'));
		//tarjetas incorrectas
		system.assertEquals(false, Validate.naranja('4398728045218854'));
		system.assertEquals(false, Validate.naranja('4667858768964691'));
		system.assertEquals(false, Validate.naranja('4667858768964690'));
	}

	private static testMethod void testCarrefour() { 		
		System.assertEquals(false,Validate.carrefour('5q'));
		System.assertEquals(false,Validate.carrefour('5842234111111111111111111111111'));		
		System.assertEquals(true,Validate.carrefour('5855845845845841'));
		System.assertEquals(true,Validate.carrefour('8581845845845841'));		
		System.assertEquals(true,Validate.carrefour('4667858768964691'));
	}
    
    private static testMethod void testAmericanExpress() { 		
		System.assertEquals(false,Validate.americanExpressNumber('5q'));
		System.assertEquals(false,Validate.americanExpressNumber('5842234111111111111111111111111'));		
		System.assertEquals(false,Validate.americanExpressNumber('5555555555554444'));	
		System.assertEquals(true,Validate.americanExpressNumber('340000000000009'));	
		System.assertEquals(true,Validate.americanExpressNumber('343588229048665'));
		System.assertEquals(true,Validate.americanExpressNumber('375164258939470'));
	}
    
    
    private static testMethod void testMasterCardNumber() { 		
		System.assertEquals(false,Validate.masterCardNumber('5q'));
		System.assertEquals(false,Validate.masterCardNumber('5842234111111111111111111111111'));		
		System.assertEquals(false,Validate.masterCardNumber('340000000000009'));	
		System.assertEquals(true,Validate.masterCardNumber('5103138076353435'));	
		System.assertEquals(true,Validate.masterCardNumber('5533814965089823'));
		System.assertEquals(true,Validate.masterCardNumber('5110059945638221'));
	}
    
    
	private static testMethod void testCabalNumber() { 		
		System.assertEquals(false,Validate.cabalNumbers('5q'));
		System.assertEquals(false,Validate.cabalNumbers('5842234111111111111111111111111'));		
		System.assertEquals(false,Validate.cabalNumbers('340000000000009'));	
		System.assertEquals(true,Validate.cabalNumbers('5812345678912345'));	
		System.assertEquals(true,Validate.cabalNumbers('6012345678912345'));
		System.assertEquals(true,Validate.cabalNumbers('6012345159872345'));
	}
    
    private static testMethod void testDinersNumber() { 
        
		System.assertEquals(false,Validate.dinersNumbers('5q'));
		System.assertEquals(false,Validate.dinersNumbers('5842234111111111111111111111111'));		
		System.assertEquals(false,Validate.dinersNumbers('340000000000009'));	
		System.assertEquals(true,Validate.dinersNumbers('30123456789134'));	
		System.assertEquals(true,Validate.dinersNumbers('38123456789134'));
		System.assertEquals(true,Validate.dinersNumbers('36123451598735'));
    
    }
    
	
}
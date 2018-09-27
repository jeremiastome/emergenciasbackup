@isTest
private class XappiaHelperTest {
	@isTest static void testItShouldReturnRightCuits()
    {
        system.assertEquals('27123412341',XappiaHelper.GenerateCUITFromDNI('12341234', false));
        system.assertEquals('23123412214',XappiaHelper.GenerateCUITFromDNI('12341221', false));
        system.assertEquals('20123412223',XappiaHelper.GenerateCUITFromDNI('12341222', true));
        system.assertEquals('20123411030',XappiaHelper.GenerateCUITFromDNI('12341103', true));        
        system.assertEquals('23123411099',XappiaHelper.GenerateCUITFromDNI('12341109', true));                
    }
    
    @isTest static void testItShouldReturnNothingWhenDatesAreWrong()
    {
        system.assertEquals('', XappiaHelper.GenerateCUITFromDNI('',false));
        system.assertEquals('', XappiaHelper.GenerateCUITFromDNI('1234q341',false));
        system.assertEquals('', XappiaHelper.GenerateCUITFromDNI('54131234123',true));
		system.assertEquals('', XappiaHelper.GenerateCUITFromDNI('23-12341109a9',true));
		system.assertEquals('', XappiaHelper.GenerateCUITFromDNI(null,null));
    }	

	@isTest static void testCUITValidationGiveRightAnswers()
	{
		//right CUIT
		System.assertEquals(true,XappiaHelper.IsItValidCUIT('27123412341'));
		System.assertEquals(true,XappiaHelper.IsItValidCUIT('27-12341234-1'));
		System.assertEquals(true,XappiaHelper.IsItValidCUIT('23123412214'));
		System.assertEquals(true,XappiaHelper.IsItValidCUIT('20123412223'));
		System.assertEquals(true,XappiaHelper.IsItValidCUIT('20123411030'));
		System.assertEquals(true,XappiaHelper.IsItValidCUIT('23123411099'));
		//wrong CUIT
		System.assertEquals(false,XappiaHelper.IsItValidCUIT('1234123'));
		System.assertEquals(false,XappiaHelper.IsItValidCUIT(''));
		System.assertEquals(false,XappiaHelper.IsItValidCUIT('1234q341'));
		System.assertEquals(false,XappiaHelper.IsItValidCUIT('54131234123'));
		System.assertEquals(false,XappiaHelper.IsItValidCUIT('20-a123412223'));
		System.assertEquals(false,XappiaHelper.IsItValidCUIT(null));		
	}

	@isTest static void CBUValidtionGiveRightAnswers() {
		//right cbu
		System.assertEquals(XappiaHelper.isItValidCBU('2850590940090418135201'), true);
		System.assertEquals(XappiaHelper.isItValidCBU('2850100640094040123748'), true);
		System.assertEquals(XappiaHelper.isItValidCBU('0440053040000160557800'), true);
		System.assertEquals(XappiaHelper.isItValidCBU('0440024040000165916790'), true);
		System.assertEquals(XappiaHelper.isItValidCBU('044-0024-0400-0016-5916-790'), true);
		//wrong cbu
		System.assertEquals(XappiaHelper.isItValidCBU('0170099220000067797371'), false);
		System.assertEquals(XappiaHelper.isItValidCBU('0850100640094040123748'), false);
		System.assertEquals(XappiaHelper.isItValidCBU('0440053040002160557801'), false);
		System.assertEquals(XappiaHelper.isItValidCBU('04400530400021605'), false);
		System.assertEquals(XappiaHelper.isItValidCBU(null), false);
		System.assertEquals(XappiaHelper.isItValidCBU('044005304000216055A801'), false);		
	}

	@isTest static void testLuhnValidtionGiveRightAnswers() {
		//right Luhn code
		system.assertEquals(true, XappiaHelper.isItValidLuhnCode('4398728045218854'));
		system.assertEquals(true, XappiaHelper.isItValidLuhnCode('4667858768964691'));
		system.assertEquals(true, XappiaHelper.isItValidLuhnCode('5028276435949634'));
		system.assertEquals(true, XappiaHelper.isItValidLuhnCode('5980289411573076'));
		system.assertEquals(true, XappiaHelper.isItValidLuhnCode('4667858768964691'));		
		system.assertEquals(true, XappiaHelper.isItValidLuhnCode('371449635398431'));
		//wrong Luhn code
		system.assertEquals(false, XappiaHelper.isItValidLuhnCode('0850100640094040123748'));
		system.assertEquals(false, XappiaHelper.isItValidLuhnCode('0876543210'));
		system.assertEquals(false, XappiaHelper.isItValidLuhnCode(''));
		system.assertEquals(false, XappiaHelper.isItValidLuhnCode(null));
		system.assertEquals(false, XappiaHelper.isItValidLuhnCode('6980289411573076'));
		system.assertEquals(false, XappiaHelper.isItValidLuhnCode('6980289411573076'));
	}

	@isTest static void testNumericStringGiveRightAnswers()
	{
		System.assertEquals('1234',XappiaHelper.stringToNumericString('1234'));
		System.assertEquals('1234',XappiaHelper.stringToNumericString('x1a2a3-qw4'));
		System.assertEquals('',XappiaHelper.stringToNumericString('hello world!'));
		System.assertEquals('',XappiaHelper.stringToNumericString(''));
		System.assertEquals('',XappiaHelper.stringToNumericString(null));
	}
}
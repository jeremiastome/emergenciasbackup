global class XappiaHelper {	
	/*******************************************************************************************************
	* algorithm by https://virushardrive.wordpress.com/2010/04/04/algoritmo-de-cuil-cuit/, adapted by Xappia
    * @description return CUIT in format xy-DNI-z. If it's not a valid DNI, return ''. Works only to fisical person.
    */
	global static string GenerateCUITFromDNI(string DNI, boolean isMale)
	{
		if (string.isBlank(dni)
		||!dni.isNumeric() 
		|| DNI.length()>8 || DNI.length() <7
		|| isMale==null)
			return '';
		if (DNI.length()==7)
			DNI = '0'+DNI;
		string XY;
		if (isMale)
			XY = '20';
		else
			XY = '27';

		string XYWithDNI = XY + DNI;
		Integer[] serie = new Integer[] { 5, 4, 3, 2, 7, 6, 5, 4, 3, 2 };
		Integer aux = 0;
		for (integer i = 0; i< 10; i++) {
			string simbol = XYWithDNI.substring(i, i + 1);
			aux += integer.valueOf(simbol) * serie[i];
		}
		aux = (Math.mod(aux, 11));		
		string Z = '';
		if (aux == 0)
		{
			Z = '0';
		}
		else if (aux == 1)
		{
			XY = '23';
			if (isMale)
			{
				Z = '9';
			} else
			{
				Z = '4';
			}
		}
		else
		{
			Z = String.valueOf(11 - aux);
		}		
		return XY + dni + Z;
	}

    /*******************************************************************************************************
    * @description accept both formats: xx-xxxxxxxx-x and xxxxxxxxxxx
    */
	global static Boolean IsItValidCUIT(string CUIT)
	{
		if (String.isBlank(CUIT))
			return false;
		string numericCUIT = stringToNumericString(CUIT);
		if (numericCUIT.length()!=11)
			return false;
		if (CUIT.length()==13&&
		   (CUIT.substring(2,3)!='-'
		   ||CUIT.substring(11,12)!='-')
		)
			return false;        
		CUIT = stringToNumericString(CUIT);
        if (CUIT.substring(0,2)!='34'
			&&CUIT.substring(0,2)!='33'
			&&CUIT.substring(0,2)!='30'
            &&CUIT.substring(0,2)!='27'
			&&CUIT.substring(0,2)!='24'
            &&CUIT.substring(0,2)!='23'
            &&CUIT.substring(0,2)!='20'
        )
            return false;
		Integer[] serie = new Integer[] { 5, 4, 3, 2, 7, 6, 5, 4, 3, 2 };
		Integer aux = 0;
		for (integer i = 0; i< 10; i++) {
			string simbol = CUIT.substring(i, i + 1);
			aux += integer.valueOf(simbol) * serie[i];			
		}
		aux = 11 - (Math.mod(aux, 11));		
		if (aux == 11) {
			aux = 0;
		}
		return integer.valueOf(CUIT.substring(10, 11)) == aux;
	}
	
	/*******************************************************************************************************
	*  Source: http://www.codeproject.com/Tips/515367/Validate-credit-card-number-with-Mod-algorithm
    * @description its validation for most credit cards and other stuff
    */
    public static boolean isItValidLuhnCode(string creditCardNumber) {        
		if (String.isBlank(creditCardNumber))
			return false;
		integer sumOfDigits = 0;
		List<String> cardDigits = creditCardNumber.split('');
		integer checkEven = Math.mod(cardDigits.size(), 2);
		for(Integer i = 0; i < cardDigits.size(); i++) {
			Integer d = integer.valueOf(cardDigits[i]);
			if(Math.mod(i, 2) == checkEven) {
				d *= 2;
				if(d >= 10) {
					d = d / 10 + Math.mod(d, 10);
				}
			}
			sumOfDigits += d;
		}		        
        return Math.mod(sumOfDigits, 10) == 0;
    }

	/*******************************************************************************************************
    * @description Sample: 's2w3df41'->'2341'
    */
	global static String stringToNumericString(string str)
	{
		if (String.isBlank(str))
			return '';
		string numericString = '';
		integer strLength = str.length();
		for (integer i = 0; i<str.length(); i++) {
			String s = str.mid(i, 1);
			if (s.isNumeric()) {
				numericString += s;
			}
		}
		return numericString;
	}
    /*******************************************************************************************************
    * @description validate if CBU is well formed - Validation provided by Mauricio Closa - Adapted by Xappia
    */
	global static Boolean isItValidCBU(string CBU) {
		List<Integer> VEC1 = new List<Integer> {7, 1, 3, 9, 7, 1, 3};
		List<Integer> VEC2 = new List<Integer> {3, 9, 7, 1, 3, 9, 7, 1, 3, 9, 7, 1, 3};		
		if(String.isBlank(CBU))
			return false;		
		CBU = CBU.replace('-', '');
		if (CBU.length() == 22 && CBU.isNumeric()){
			Integer acum = 0;
			for (Integer i = 0; i < 7; i++) {				
				acum += Integer.valueOf(CBU.substring(0, 7).substring(i, i + 1)) * VEC1[i];
			}						
			Integer verificador2 = Integer.valueOf(CBU.substring(7, 8));
			Integer diferencia1 = math.mod(10 - (math.mod(acum, 10)), 10);						
			boolean primerBloqueCbuOk = (verificador2 == diferencia1);
			acum = 0;
			for (Integer i = 0; i < 13; i++) {
				acum += Integer.valueOf(CBU.substring(8, 21).substring(i, i + 1)) * VEC2[i];
			}			
			Integer diferencia2 = math.mod(10 - (math.mod(acum, 10)), 10);						
			boolean segundoBloqueCbuOk = (Integer.valueOf(CBU.substring(21)) == diferencia2);			
			return (primerBloqueCbuOk && segundoBloqueCbuOk);
		}
		else {
			return false;
		}
	}	


}
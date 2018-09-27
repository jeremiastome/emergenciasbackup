public class Validate {

	//validate if CBU is well formed - Validation provided by Mauricio Closa - Adapted by Xappia
	public static Boolean cbu(string cbu) {
		List<Integer> VEC1 = new List<Integer> {7, 1, 3, 9, 7, 1, 3};
		List<Integer> VEC2 = new List<Integer> {3, 9, 7, 1, 3, 9, 7, 1, 3, 9, 7, 1, 3};
		
		if(cbu == null) {
			return false;
		}
		
		cbu = cbu.replace('-', '');
		if (cbu.length() == 22 && cbu.isNumeric()){
			Integer acum = 0;
			for (Integer i = 0; i < 7; i++) {
				//system.debug('Al acumulador le sumamos: '  + Integer.valueOf(cbu.substring(0, 7).substring(i, i + 1)) * VEC1[i]);
				acum += Integer.valueOf(cbu.substring(0, 7).substring(i, i + 1)) * VEC1[i];
			}
			
			//8vo digito es el verificador
			//system.debug('El codigo verificador es: ' + Integer.valueOf(cbu.substring(7, 8)));
			Integer verificador2 = Integer.valueOf(cbu.substring(7, 8));
			
			//var diferencia = (10 - (suma % 10)) % 10;
			Integer diferencia1 = math.mod(10 - (math.mod(acum, 10)), 10);
			//Integer diferencia1 = 10 - (math.mod(acum, 10));
			
			boolean primerBloqueCbuOk = (verificador2 == diferencia1);

			acum = 0;
			for (Integer i = 0; i < 13; i++) {
				acum += Integer.valueOf(cbu.substring(8, 21).substring(i, i + 1)) * VEC2[i];
			}
			
			Integer diferencia2 = math.mod(10 - (math.mod(acum, 10)), 10);
			//Integer diferencia2 = 10 - (math.mod(acum,10));
			
			boolean segundoBloqueCbuOk = (Integer.valueOf(cbu.substring(21)) == diferencia2);
			
			return (primerBloqueCbuOk && segundoBloqueCbuOk);
		}
		else {
			return false;
		}
	}
	
	//validate if Visa card number is well formed - Validation provided by Mauricio Closa - Adapted by Xappia
	public static boolean visa(String numero) {
		if(numero == null || numero.length() < 16) {
			return false;
		}
		
		Integer digito = 0;
		Integer suma = 0;
		Integer decena = 0;
		Integer x = 0;
		Integer dig = Integer.valueOf(numero.substring(numero.length() - 1));
		
		for(Integer j = 1; j < numero.length(); j++) {
			Integer i = j - 1;
			digito = Integer.valueOf(numero.substring(i, i + 1));
			if(math.mod(j, 2) != 0) {
				digito = digito * 2;
				if (digito > 9) {
					digito = digito - 9;
				}
			}
			suma = suma + digito;
		}
		
		decena = ((suma / 10) + 1) * 10;
		x = decena - suma;
		
		if (x == 10){
			x = 0;
		}
		if (x != dig){
			return false;
		}
		return true;
	}
	
	//validate if Tarjeta Naranja card number is well formed - Validation provided by Emergencia SA - Adapted by Xappia
	public static boolean naranja(string cardNum) {
        integer digit = integer.valueOf(cardNum.mid(15, 1));
        List<integer> mult = new List<integer> {
			4, 3, 2, 7,
			6, 5, 4, 3,
			2, 7, 6, 5,
			4, 3, 2
		};
        List<String> nums = cardNum.split('');
        integer total = 0;
		
		for(integer i = 0; i < mult.size(); i++) {
            total += integer.valueOf(nums[i]) * mult[i];
        }
		
        integer remainder = 11 - Math.mod(total, 11);
        if(remainder > 9) {
            remainder = 0;
        }
		
        return (remainder == digit);
    }
	
	// Source: http://www.codeproject.com/Tips/515367/Validate-credit-card-number-with-Mod-algorithm
    public static boolean mod10Check(string creditCardNumber) {
        // 1. Starting with the check digit double the value of every other digit
        // 2. If doubling of a number results in a two digits number, add up
        //     the digits to get a single digit number. This will results in eight single digit numbers
        // 3. Get the sum of the digits
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
		
        //// If the final sum is divisible by 10, then the credit card number
        //   is valid. If it is not divisible by 10, the number is invalid.
        return Math.mod(sumOfDigits, 10) == 0;
    }
	public static boolean carrefour(string cardNumber) {
        return (
            String.isNotBlank(cardNumber)
            &&cardNumber.isNumeric()
            &&cardNumber.length()==16
            &&(cardNumber.startsWith('8581')||cardNumber.startsWith('585')) )
            ||cardNumber(cardNumber);
	}
	public static Boolean cardNumberWithType(string cardNumber, string cardType){

		if (cardType=='0017') {
			return carrefour(cardNumber);
		}        
        else if (cardType=='0001') {
            return dinersNumbers(cardNumber);
        }
        else if (cardType=='0002') {
            return visa(cardNumber);
        }
        else if (cardType=='0004') {
            return masterCardNumber(cardNumber);
        }
        else if (cardType=='0005') {
            return americanExpressNumber(cardNumber);
        }
        else if (cardType=='0006') {
            return cabalNumbers(cardNumber);
        } 
        else if(cardType=='0020' || cardType=='0021') {
			return (cardNumber.length() == 16 && naranja(cardNumber) );
		}
		else{
			return cardNumber(cardNumber);
		}
	}
		
	//validate size of credit card number - Validation provided by Mauricio Closa - Adapted by Xappia
	public static boolean cardNumber(String numeroTarjeta) {
		if(String.IsBlank(numeroTarjeta) || numeroTarjeta.length() > 19 || numeroTarjeta.length() < 12 || !numeroTarjeta.isNumeric()) {
            return false;
        }
		else {
			return mod10Check(numeroTarjeta);
		}
	}
	
	public static boolean NSPNumber(String NSPNumber) {
		if (NSPNumber != null && NSPNumber.length() == 13){
			return true;
		}
		return false;
	}
	
	public static boolean CobisNumber(String cobisNumber) {
		if (cobisNumber != null && cobisNumber.length() == 10){
			return true;
		}
		return false;
	}
    
	public static boolean americanExpressNumber(String americanExpressNumber) {
        
		boolean result = (americanExpressNumber.length()==15 &&
                          americanExpressNumber.subString(0, 1)=='3' &&
                         (americanExpressNumber.substring(1,2)=='4' || 
                          americanExpressNumber.substring(1,2)=='7' ) );
               
		return result;
    }
    
    public static boolean masterCardNumber(String masterCardNumber) {
        
		boolean result = (masterCardNumber.length()==16 &&
                         (integer.valueOf(masterCardNumber.subString(0, 2))>=51 ||
                          integer.valueOf(masterCardNumber.subString(0, 2))<=55));
               
        
		return result;
    }
    
    public static boolean cabalNumbers(String cabalNumber) {
        
		boolean result = (cabalNumber.length()==16 &&
                         (cabalNumber.subString(0, 2)=='58' ||
                          cabalNumber.subString(0, 2)=='60'));
               
		return result;
    }
    
	public static boolean dinersNumbers(String dinersNumber) {
        
		boolean result = (dinersNumber.length()==14 &&
                         (dinersNumber.subString(0, 2)=='30' ||
                          dinersNumber.subString(0, 2)=='36' ||
                          dinersNumber.subString(0, 2)=='38' ));
               
		return result;
    }
    
    
}
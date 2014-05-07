component output="false" {
	public string function validator1( fieldName, value, data, justTesting ) validator=true validatorMessage="message for validator1" output=false {
		if ( justTesting ) {
			return arguments.value;
		}

		return "oops";
	}
	public boolean function validator2( fieldName, data, params ) validator=true output=false validatorMessage="message for validator2"  {
		return true;
	}
	public boolean function validator3( fieldName, data, params ) validator=true output=false validatorMessage="message for validator3"  {
		return true;
	}

	public any function notAValidator(){}
}
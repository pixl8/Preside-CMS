component output="false" validationProvider=true {
	public string function validator1( fieldName, value, data, justTesting ) output=false {
		if ( justTesting ) {
			return arguments.value;
		}

		return "oops";
	}
	public boolean function validator2( fieldName, value, data, someParam="test", anotherParam=false ) output=false validatorMessage="validation:some.message.key" {
		return true;
	}
	public string function validator2_js() output=false {
		return "function( value, element, params ){ return true; }";
	}

	public boolean function validator3( fieldName, value, data ) output=false validatorMessage="validation:another.message.key" {
		return true;
	}
	public string function validator3_js() output=false {
		return "function( value, element, params ){ return false; }";
	}

	public any function notAValidator() output=false validator=false {}
}
component output="false" validationProvider=true {
	public string function validator1( fieldName, data, justTesting ) output=false {
		if ( justTesting ) {
			return data[ fieldname ];
		}

		return "oops";
	}
	public boolean function validator2( fieldName, data ) output=false {
		return true;
	}
	public boolean function validator3( fieldName, data, required boolean customValidatorParam ) output=false {
		return true;
	}

	public any function notAValidator() validator=false output=false {}
}
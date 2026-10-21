component {

	private boolean function isEnabled() {
		return true;
	}

	private void function run() {
		getPresideObject( "my_extension_object" ).updateData(
			  filter = { label="E2E Alpha 01" }
			, data   = {
				  sensitive_col       = "E2E-SENSITIVE-ALPHA-01"
				, other_sensitive_col = "E2E-OTHER-SENSITIVE-ALPHA-01"
			  }
		);
	}

}

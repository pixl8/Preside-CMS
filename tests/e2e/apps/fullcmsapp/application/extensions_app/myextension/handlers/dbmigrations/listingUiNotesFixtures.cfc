component {

	private boolean function isEnabled() {
		return true;
	}

	private void function run() {
		getPresideObject( "my_extension_object" ).updateData(
			  filter = { label="E2E Alpha 01" }
			, data   = { notes="E2E-NOTES-ALPHA-01" }
		);
	}

}

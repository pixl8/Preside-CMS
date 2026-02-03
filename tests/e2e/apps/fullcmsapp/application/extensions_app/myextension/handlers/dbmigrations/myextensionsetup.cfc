component {

	private boolean function isEnabled() {
		return true;
	}

	private void function run() {
		getPresideObject( "my_extension_object" ).insertData({ label="Hello world" });
	}
}
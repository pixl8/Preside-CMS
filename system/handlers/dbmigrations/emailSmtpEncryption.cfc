/**
 * @feature emailCenter
 */
component {

	private void function run() {
		getPresideObject( "system_config" ).updateData(
			  filter = { category="emailServiceProvidersmtp", setting="use_tls", value="1" }
			, data   = { setting="encryption", value="tls" }
		);
		getPresideObject( "system_config" ).updateData(
			  filter = { category="emailServiceProvidersmtp", setting="use_tls" }
			, data   = { setting="encryption", value="none" }
		);
	}

}
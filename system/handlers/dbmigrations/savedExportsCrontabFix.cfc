/**
 * @feature dataExport
 */
component {

	private void function runAsync() {
		getPresideObject( "saved_export" ).updateData(
			  filter = "schedule like 'disabled %'"
			, data   = { schedule="disabled" }
		);
	}

}
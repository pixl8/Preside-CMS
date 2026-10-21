component {

	private boolean function isEnabled() {
		return true;
	}

	private void function run() {
		var dao = getPresideObject( "my_extension_notes_object" );

		if ( dao.dataExists( filter={ label="E2E Notes Alpha 01" } ) ) {
			return;
		}

		dao.insertData( {
			  label    = "E2E Notes Alpha 01"
			, status   = "active"
			, category = "widgets"
			, notes    = "E2E-NOTES-ALPHA-01"
		} );
		dao.insertData( {
			  label    = "E2E Notes Beta 01"
			, status   = "draft"
			, category = "gadgets"
			, notes    = "E2E-NOTES-BETA-01"
		} );
	}

}

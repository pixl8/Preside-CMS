/**
 * Handler for display logic of the datamanager
 * Admin Menu Item.
 *
 */
component {

	private boolean function isActive() {
		return ListLast( event.getCurrentHandler(), ".") == "datamanager" && ( IsTrue( prc.objectInDatamanagerUi ?: "" ) || !Len( Trim( prc.objectName ) ) );
	}

}
/**
 * Handler for display logic of the datamanager
 * Admin Menu Item.
 *
 * @feature admin and websiteUsers
 */
component {

	private void function prepare( event, rc, prc, args={} ) {
		var children = args.subMenuItems ?: [];

		// if we only have one child menu (i.e. Website users) - just make it the main menu item
		if ( IsArray( children ) && ArrayLen( children ) == 1 ) {
			args.active       = children[ 1 ].active        ?: false;
			args.link         = children[ 1 ].link          ?: "";
			args.subMenuItems = children[ 1 ].subMenuItems  ?: []
		}
	}

}
/**
 * Expression handler for "Current page has/does not have a main image"
 *
 */
component {

	/**
	 * @expression true
	 */
	private boolean function webRequest(
		required numeric _has
	) {
		var hasImage = Len( Trim( event.getPageProperty( "main_image" ) ) )

		return _has ? hasImage : !hasImage;
	}

}
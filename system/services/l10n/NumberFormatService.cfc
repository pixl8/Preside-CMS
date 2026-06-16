/**
 * @singleton         true
 * @presideService    true
 */
component {

	public any function init() {
		return this;
	}

	public string function getNumberFormatMask( string locale="" ) {
		var resolvedLocale = Len( Trim( arguments.locale ) ) ? Trim( arguments.locale ) : _getSiteLocale();

		switch ( resolvedLocale ) {
			case "en_GB":
			case "en_US":
			default:
				return ",";
		}

		return ",";
	}

// PRIVATE HELPERSs
	private string function _getSiteLocale() {
		var siteId = $getRequestContext().getSiteId();

		if ( Len( siteId ) ) {
			var settings = $getPresideObject( "site" ).selectData(
				  id           = siteId
				, returntype   = "singleRecordStruct"
				, selectFields = [ "locale" ]
			);

			return settings.locale ?: "en_GB";
		}

		return "en_GB";
	}
}
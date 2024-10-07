/**
 * @feature sites
 */
component {
	property name="siteService" inject="SiteService";
	property name="poService"   inject="PresideObjectService";

	private string function getDefaultValue( event, rc, prc ) {
		var activeSiteId = siteService.getActiveSiteId();

		if ( isEmptyString( activeSiteId ) ) {
			var siteQuery = poService.selectData(
				  objectName   = "site"
				, selectFields = [ "id" ]
				, orderBy      = poService.getDateCreatedField( objectName="site" )
				, maxRows      = 1
			);

			activeSiteId = siteQuery.id ?: "";
		}

		return activeSiteId;
	}
}
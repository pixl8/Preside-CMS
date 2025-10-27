/**
 * @singleton      true
 * @presideservice true
 */
component {

	property name="presideObjectService" inject="PresideObjectService";

	public any function init() {
		return this;
	}

	public boolean function isManagerEnabled( required string objectName ) {
		if ( !$isFeatureEnabled( "draftManager" ) ) {
			return false;
		}

		return presideObjectService.getObjectAttribute( objectName=arguments.objectName, attributeName="draftManagerEnabled", defaultValue=false );
	}

	public boolean function isDraftAction() {
		if ( !$isFeatureEnabled( "draftManager" ) ) {
			return false;
		}

		var rc = $getRequestContext().getCollection();

		return ( rc._saveaction ?: "" ) != "publish";
	}

}
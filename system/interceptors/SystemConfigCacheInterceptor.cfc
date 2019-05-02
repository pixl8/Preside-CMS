component extends="coldbox.system.Interceptor" {

	property name="settingsCache" inject="cachebox:PresideSystemSettingsCache";

// PUBLIC
	public void function configure() {}

	public void function postDeleteObjectData( event, interceptData ) {
		_clearSettingsCache( argumentCollection=arguments );
	}
	public void function postInsertObjectData( event, interceptData ) {
		_clearSettingsCache( argumentCollection=arguments );
	}
	public void function postUpdateObjectData( event, interceptData ) {
		_clearSettingsCache( argumentCollection=arguments );
	}

// HELPERS
	private void function _clearSettingsCache( event, interceptData ) {
		var objectName = interceptData.objectName ?: "";
		if ( objectName == "system_config" ) {
			settingsCache.clearAll();
		}
	}
}
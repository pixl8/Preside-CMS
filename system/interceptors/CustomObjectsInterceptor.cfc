/**
 * @feature customObjects
 */
component extends="coldbox.system.Interceptor" {

	property name="customObjectsService" inject="delayedInjector:customObjectsService";

	public void function configure() {}

	public void function postReadPresideObjects( event, interceptData ) {
		customObjectsService.addVirtualObjects( interceptData.objects ?: {} );
	}

	public void function postDbSyncObjects() {
		customObjectsService.ensureRuntimeObjects();
	}

	public void function onApplicationStart() {
		customObjectsService.ensureRuntimeObjects();
	}

	public void function postPresideReload() {
		customObjectsService.ensureRuntimeObjects();
	}

	public void function preSelectObjectData( event, interceptData ) {
		customObjectsService.prepareRecordScope( interceptData );
	}

	public void function preInsertObjectData( event, interceptData ) {
		customObjectsService.prepareRecordScope( interceptData );
	}

	public void function preUpdateObjectData( event, interceptData ) {
		customObjectsService.prepareRecordScope( interceptData );
	}

	public void function preDeleteObjectData( event, interceptData ) {
		customObjectsService.prepareRecordScope( interceptData );
	}

	public void function preUpsertObjectData( event, interceptData ) {
		customObjectsService.prepareRecordScope( interceptData );
	}

	public void function onCreateSelectDataCacheKey( event, interceptData ) {
		var definitionId = customObjectsService.getCustomObjectId( arguments.interceptData.objectName ?: "" );

		if ( !Len( definitionId ) ) {
			return;
		}

		arguments.interceptData.cacheKey = ( arguments.interceptData.cacheKey ?: "" ) & "customObject" & definitionId;
	}

}

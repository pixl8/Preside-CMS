/**
 * Handler that provides admin related helper viewlets,
 * and actions for preside object data
 *
 */
component extends="preside.system.base.adminHandler" {

	property name="adminDataViewsService" inject="adminDataViewsService";
	property name="presideObjectService"  inject="presideObjectService";
	/**
	 * Method that is called from `adminDataViewsService.buildViewObjectRecordLink()`
	 * for objects that are managed in the DataManager. Hint: this can also be invoked with:
	 * `event.buildAdminLink( objectName=myObject, recordId=myRecordId )`
	 *
	 */
	private string function getViewRecordLink( required string objectName, required string recordId ) {
		return event.buildAdminLink(
			  linkto      = "datamanager.viewRecord"
			, queryString = "object=#arguments.objectName#&id=#arguments.recordId#"
		);
	}


	/**
	 * Method for rendering a record for an admin view
	 *
	 */
	private string function viewRecord( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		args.viewGroups = adminDataViewsService.listViewGroupsForObject( objectName );

		return renderView( view="/admin/dataHelpers/viewRecord", args=args );
	}

	/**
	 * Helper viewlet for rendering a admin data view 'display group'
	 * for a given object/record
	 */
	private string function displayGroup( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var recordId   = args.recordId   ?: "";
		var props      = args.properties ?: [];
		var uriRoot    = presideObjectService.getResourceBundleUriRoot( objectName=objectName );

		prc.record = prc.record ?: presideObjectService.selectData( objectName=objectName, id=recordId );

		args.renderedProps = [];
		for( var propertyName in props ) {
			var renderedValue = adminDataViewsService.renderField(
				  objectName   = objectName
				, propertyName = propertyName
				, recordId     = recordId
				, value        = prc.record[ propertyName ] ?: ""
			);
			args.renderedProps.append( {
				  objectName    = objectName
				, propertyName  = propertyName
				, propertyTitle = translateResource( uri="#uriRoot#field.#propertyName#.title", defaultValue=translateResource( uri="cms:preside-objects.default.field.#propertyName#.title", defaultValue=propertyName ) )
				, recordId      = recordId
				, value         = prc.record[ propertyName ] ?: ""
				, rendered      = renderedValue
			} );
		}

		return renderView( view="/admin/dataHelpers/displayGroup", args=args );
	}

	/**
	 * Public action that is expected to be POSTed to with a 'content' variable
	 * that will be rendered within the preview layout
	 */
	public string function richeditorPreview( event, rc, prc ) {
		event.include( "/css/admin/specific/richeditorPreview/" );

		return renderLayout(
			  layout = "richeditorPreview"
			, args   = { content = renderContent( "richeditor", rc.content ?: "" ) }
		);
	}

}
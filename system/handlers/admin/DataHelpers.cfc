/**
 * Handler that provides admin related helper viewlets,
 * and actions for preside object data
 *
 */
component extends="preside.system.base.adminHandler" {

	property name="adminDataViewsService"   inject="adminDataViewsService";
	property name="presideObjectService"    inject="presideObjectService";
	property name="dataExportService"       inject="dataExportService";
	property name="adhocTaskManagerService" inject="adhocTaskManagerService";
	property name="customizationService"    inject="dataManagerCustomizationService";


	/**
	 * Method for rendering a record for an admin view
	 *
	 */
	private string function viewRecord( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		args.viewGroups = adminDataViewsService.listViewGroupsForObject( objectName );

		args.preRenderRecord         = ( customizationService.objectHasCustomization( objectName, "preRenderRecord"          ) ? customizationService.runCustomization( objectName=objectName, action="preRenderRecord"         , args=args ) : "" );
		args.preRenderRecordLeftCol  = ( customizationService.objectHasCustomization( objectName, "preRenderRecordLeftCol"   ) ? customizationService.runCustomization( objectName=objectName, action="preRenderRecordLeftCol"  , args=args ) : "" );
		args.preRenderRecordRightCol = ( customizationService.objectHasCustomization( objectName, "preRenderRecordRightCol"  ) ? customizationService.runCustomization( objectName=objectName, action="preRenderRecordRightCol" , args=args ) : "" );

		args.leftCol  = "";
		args.rightCol = "";

		for( var col in [ "left", "right" ] ) {
			for( var group in args.viewGroups[ col ] ) {
				var groupArgs = args.copy();
				groupArgs.append( group );

				args[ col & "Col" ] &= renderViewlet(
					  event = "admin.datahelpers.displayGroup"
					, args  = groupArgs
				);
			}
		}

		args.postRenderRecordLeftCol  = ( customizationService.objectHasCustomization( objectName, "postRenderRecordLeftCol"  ) ? customizationService.runCustomization( objectName=objectName, action="postRenderRecordLeftCol" , args=args ) : "" );
		args.postRenderRecordRightCol = ( customizationService.objectHasCustomization( objectName, "postRenderRecordRightCol" ) ? customizationService.runCustomization( objectName=objectName, action="postRenderRecordRightCol", args=args ) : "" );
		args.postRenderRecord         = ( customizationService.objectHasCustomization( objectName, "postRenderRecord"         ) ? customizationService.runCustomization( objectName=objectName, action="postRenderRecord"        , args=args ) : "" );


		return renderView( view="/admin/dataHelpers/viewRecord", args=args );
	}

	/**
	 * Helper viewlet for rendering a admin data view 'display group'
	 * for a given object/record
	 */
	private string function displayGroup( event, rc, prc, args={} ) {
		var objectName    = args.objectName ?: "";
		var recordId      = args.recordId   ?: "";
		var props         = args.properties ?: [];
		var version       = Val( args.version ?: "" );
		var uriRoot       = presideObjectService.getResourceBundleUriRoot( objectName=objectName );
		var useVersioning = presideObjectService.objectIsVersioned( objectName );

		if ( useVersioning && Val( version ) ) {
			prc.record = prc.record ?: presideObjectService.selectData( objectName=object, filter={ id=recordId }, useCache=false, fromVersionTable=true, specificVersion=version, allowDraftVersions=true );
		} else {
			prc.record = prc.record ?: presideObjectService.selectData( objectName=object, filter={ id=recordId }, useCache=false, allowDraftVersions=true );
		}

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

	/**
	 * Viewlet for rendering a datatable of related records, i.e.
	 * a many-to-many or one-to-many relationship.
	 *
	 */
	private string function relatedRecordsDatatable( event, rc, prc, args={} ) {
		var objectName    = args.objectName   ?: "";
		var propertyName  = args.propertyName ?: "";
		var recordId      = args.recordId     ?: "";
		var queryString   = "objectName=#args.objectName#&propertyName=#args.propertyName#&recordId=#args.recordId#";
		var datasourceUrl = event.buildAdminLink( linkto="dataHelpers.getRecordsForRelatedRecordsDatatable", queryString=queryString );
		var relatedObject = presideObjectService.getObjectPropertyAttribute( objectName=objectName, propertyName=propertyName, attributeName="relatedTo" );
		var gridFields    = adminDataViewsService.listGridFieldsForRelationshipPropertyTable( objectName, propertyName );

		return renderView( view="/admin/datamanager/_objectDataTable", args={
			  objectName        = relatedObject
			, gridFields        = gridFields
			, dataSourceUrl     = dataSourceUrl
			, id                = "related-object-datatable-#objectName#-#propertyName#-" & CreateUUId()
			, compact           = true
			, useMultiActions   = false
			, isMultilingual    = false
			, draftsEnabled     = false
			, allowSearch       = true
			, allowFilter       = false
			, allowDataExport   = false
			, objectTitlePlural = translatePropertyName( objectName, propertyName )
		} );
	}

	/**
	 * Viewlet for rendering a simple list of related records, i.e.
	 * a many-to-many or one-to-many relationship
	 *
	 */
	private string function relatedRecordsList( event, rc, prc, args={} ) {
		var objectName    = args.objectName   ?: "";
		var propertyName  = args.propertyName ?: "";
		var recordId      = args.recordId     ?: "";
		var relatedObject = presideObjectService.getObjectPropertyAttribute( objectName=objectName, propertyName=propertyName, attributeName="relatedTo" );
		var records       = presideObjectService.selectData( objectName=objectName, id=recordId, selectFields=[ "#propertyName#.id", "#propertyName#.${labelfield} as label" ], forceJoins="inner" );
		var baseLink      = event.buildadminLink( objectName=relatedObject, recordId="{recordId}" );
		var list          = [];

		for( var record in records ) {
			if ( baseLink.len() ) {
				list.append( '<a href="#( baseLink.replace( '{recordId}', record.id ))#">#record.label#</a>' );
			} else {
				list.append( '#record.label#' );
			}
		}

		return list.toList( ", " );
	}

	/**
	 * Ajax event for returning records to populate the relatedRecordsDatatable
	 *
	 */
	public void function getRecordsForRelatedRecordsDatatable( event, rc, prc ) {
		var objectName     = rc.objectName   ?: "";
		var propertyName   = rc.propertyName ?: "";
		var recordId       = rc.recordId     ?: "";
		var gridFields     = adminDataViewsService.listGridFieldsForRelationshipPropertyTable( objectName, propertyName ).toList();
		var relatedObject  = presideObjectService.getObjectPropertyAttribute( objectName=objectName, propertyName=propertyName, attributeName="relatedTo" );
		var relatedIdField = presideObjectService.getIdField( objectName=relatedObject );
		var extraFilters   = [];
		var subquerySelect = presideObjectService.selectData(
			  objectName          = objectName
			, id                  = recordId
			, selectFields        = [ "#propertyName#.#relatedIdField# as id" ]
			, getSqlAndParamsOnly = true
		);
		var subQueryAlias = "relatedRecordsFilter";
		var params        = {};

		for( var param in subquerySelect.params ) { params[ param.name ] = param; }

		extraFilters.append( {
			filter="1=1", filterParams=params, extraJoins=[ {
				  type           = "inner"
				, subQuery       = subquerySelect.sql
				, subQueryAlias  = subQueryAlias
				, subQueryColumn = "id"
				, joinToTable    = relatedObject
				, joinToColumn   = relatedIdField
			} ]
		} );

		prc.viewRecordLink = event.buildAdminLink( objectName=relatedObject, recordId="{id}" );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object          = relatedObject
				, gridFields      = gridFields
				, extraFilters    = extraFilters
				, useMultiActions = false
				, isMultilingual  = false
				, draftsEnabled   = false
				, useCache        = false
				, actionsView     = "admin.dataHelpers.relatedRecordTableActions"
			}
		);
	}

	private string function relatedRecordTableActions( event, rc, prc, args={} ) {
		if ( Len( Trim( prc.viewRecordLink ?: "" ) ) ) {
			args.viewRecordLink = prc.viewRecordLink.replace( "{id}", ( args.id ?: "" ) );

			return renderView( view="/admin/dataHelpers/relatedRecordTableActions", args=args );
		}
		return "";
	}

	/**
	 * Exports data to csv/excel in a background thread run using createTask()
	 *
	 */
	public void function exportDataInBackgroundThread( event, rc, prc, args={}, logger, progress ) {
		dataExportService.exportData(
			  argumentCollection = args
			, logger             = logger   ?: NullValue()
			, progress           = progress ?: NullValue()
		);
	}

	/**
	 * Result handler for background-threaded data export
	 *
	 */
	public void function downloadExport( event, rc, prc ) {
		var taskId          = rc.taskId ?: "";
		var task            = adhocTaskManagerService.getProgress( taskId );
		var localExportFile = task.result.filePath       ?: "";
		var exportFileName  = task.result.exportFileName ?: "";
		var mimetype        = task.result.mimetype       ?: "";

		if ( task.isEmpty() || !localExportFile.len() || !FileExists( localExportFile ) ) {
			event.notFound();
		}

		createTask(
			  event             = "admin.dataHelpers.discardExport"
			, args              = { taskId=taskId }
			, runIn             = CreateTimeSpan( 0, 0, 10, 0 )
			, discardOnComplete = true
		);

		header name="Content-Disposition" value="attachment; filename=""#exportFileName#""";
		content reset=true file=localExportFile deletefile=true type=mimetype;
		abort;
	}

	public void function discardExport( event, rc, prc ) {
		var taskId          = args.taskId ?: "";
		var task            = adhocTaskManagerService.getProgress( taskId );
		var localExportFile = task.result.filePath       ?: "";

		if ( !task.isEmpty() ) {
			adhocTaskManagerService.discardTask( taskId );

			if ( FileExists( localExportFile ) ) {
				FileDelete( localExportFile );
			}
		}
	}

}
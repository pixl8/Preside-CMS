component extends="preside.system.base.AdminHandler" {

	property name="frontendEditingService" inject="frontendEditingService";
	property name="contentRendererService" inject="contentRendererService";
	property name="presideObjectService"   inject="presideObjectService";
	property name="siteTreeService"        inject="siteTreeService";

<!--- actions --->
	public any function saveAction( event, rc, prc ) {
		var pageId   = rc.pageId   ?: "";
		var object   = rc.object   ?: "";
		var property = rc.property ?: "";
		var recordId = rc.recordId ?: "";
		var content  = rc.content  ?: "";
		var renderer = rc.renderer ?: "";
		var success  = "";

		_denyUnlessPageOrPageType( event=event, object=object );
		_denyUnlessPagePermission( event=event, permissionKey="sitetree.edit", pageId=pageId );
		_denyUnlessRecordIsPage( event=event, pageId=pageId, recordId=recordId );

		if ( !presideObjectService.fieldExists( object, property ) ) {
			event.adminAccessDenied();
		}

		success = frontendEditingService.saveContent(
			  object   = object
			, property = property
			, recordId = pageId
			, content  = content
		);

		if ( success ) {
			event.renderData( type="json", data={
				  success  = true
				, message  = translateResource( "cms:frontendeditor.save.success" )
				, rendered = renderViewlet( event="admin.frontendediting.renderPreview", args={ content=content, renderer=renderer, pageId=pageId } )
			} );
		} else {
			event.renderData( type="json", data={ success=false, message=translateResource( "cms:frontendeditor.save.unknown.error" ) } );
		}
	}

	public void function publishAction( event, rc, prc ) {
		var object   = rc.object   ?: "";
		var recordId = rc.recordId ?: "";
		var pageId   = rc.pageId   ?: "";

		_denyUnlessPageOrPageType( event=event, object=object );
		_denyUnlessPagePermission( event=event, permissionKey="sitetree.publish", pageId=pageId );
		_denyUnlessRecordIsPage( event=event, pageId=pageId, recordId=recordId );

		siteTreeService.publishDraft( pageId );

		event.renderData( type="json", data={
			  success  = true
			, message  = translateResource( "cms:frontendeditor.publish.success" )
		} );
	}

	public void function getHistoryForAjaxDataTables( event, rc, prc ) {
		var recordId = rc.id       ?: "";
		var object   = rc.object   ?: "";
		var property = rc.property ?: "";

		_denyUnlessPageOrPageType( event=event, object=object );
		_denyUnlessPagePermission( event=event, permissionKey="sitetree.viewversions", pageId=recordId );

		runEvent(
			  event          = "admin.DataManager._getRecordHistoryForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object     = object
				, recordId   = recordId
				, property   = property
				, gridFields = 'datemodified,_version_author'
				, actionsView = "admin/frontendediting/_historyActions"
			}
		);
	}

	public void function getVersionContent( event, rc, prc ) {
		var recordId = rc.id       ?: "";
		var object   = rc.object   ?: "";
		var property = rc.property ?: "";
		var version  = Val( rc.version  ?: "" );
		var result   = { success=true, content="" };

		_denyUnlessPageOrPageType( event=event, object=object );
		_denyUnlessPagePermission( event=event, permissionKey="sitetree.viewversions", pageId=recordId );

		if ( !presideObjectService.fieldExists( object, property ) ) {
			event.adminAccessDenied();
		}

		var record   = presideObjectService.selectData(
			  objectName       = object
			, selectFields     = [ property ]
			, id               = recordId
			, fromVersionTable = true
			, specificVersion  = version
		);

		if ( record.recordCount ) {
			result.content = record[ property ];
		}

		event.renderData( type="json", data=result );
	}

	public void function previewVersionContent( event, rc, prc ) {
		var recordId = rc.id       ?: "";
		var object   = rc.object   ?: "";
		var property = rc.property ?: "";
		var version  = Val( rc.version  ?: "" );
		var preview  = "";

		_denyUnlessPageOrPageType( event=event, object=object );
		_denyUnlessPagePermission( event=event, permissionKey="sitetree.viewversions", pageId=recordId );

		if ( !presideObjectService.fieldExists( object, property ) ) {
			event.adminAccessDenied();
		}

		var record   = presideObjectService.selectData(
			  objectName       = object
			, selectFields     = [ property ]
			, id               = recordId
			, fromVersionTable = true
			, specificVersion  = version
		);

		if ( record.recordCount ) {
			preview = renderField(
				  object   = object
				, property = property
				, data     = record[ property ]
				, context  = "preview"
			);
		}

		event.renderData( type="html", data=preview );
	}

	public void function getPublishPrompt( event, rc, prc ) {
		var object        = rc.object   ?: "";
		var recordId      = rc.recordId ?: "";
		var pageId        = rc.pageId   ?: "";
		var changedFields = [];
		var i18nBase      = "";
		var objectTitle   = "";
		var recordLabel   = "";

		_denyUnlessPageOrPageType( event=event, object=object );
		_denyUnlessPagePermission( event=event, permissionKey="sitetree.publish", pageId=pageId );
		_denyUnlessRecordIsPage( event=event, pageId=pageId, recordId=recordId );

		i18nBase    = presideObjectService.getResourceBundleUriRoot( object );
		objectTitle = LCase( translateResource( "#i18nBase#title.singular" ) );
		recordLabel = renderLabel( object, pageId );
		changedFields = siteTreeService.getDraftChangedFields( pageId );

		if ( changedFields.len() ) {
			for( var i=changedFields.len(); i>0; i-- ) {
				changedFields[ i ] = translateResource( "#i18nBase#field.#changedFields[i]#.title", "" );
				if ( changedFields[ i ] == "" ) {
					changedFields.deleteAt( i );
				} else {
					changedFields[ i ] = "<li>" & changedFields[ i ] & "</li>";
				}
			}

			changedFields = "<ul>" & changedFields.toList( " " ) & "</ul>"
			var prompt =  "<p>" & translateResource( uri="cms:frontendeditor.publish.prompt", data=[ objectTitle, recordLabel ] ) & "</p>";
			    prompt &= "<p>" & translateResource( "cms:frontendeditor.publish.prompt.changed.fields.title" ) & "</p>";
			    prompt &= changedFields;

			event.renderData(
				  type = "json"
				, data = { prompt=prompt, publishable=true, nondraft=false }
			);
		} else {
			event.renderData(
				  type = "json"
				, data = { prompt=translateResource( "cms:frontendeditor.publish.not.required.alert" ), publishable=false, nondraft=false }
			);
		}
	}

// VIEWLETS
	private string function renderFrontendEditor( event, rc, prc, struct args={} ) {
		var objectName = args.object ?: "";

		if ( !event.isAdminUser() || !_isPageOrPageType( objectName ) ) {
			return args.renderedContent ?: ( args.rawContent ?: "" );
		}

		var control  = args.control  ?: "richeditor";

		args.renderer = args.renderer ?: contentRendererService.getRendererForField( fieldAttributes = { control = control } );

		return renderView( view="/admin/frontendediting/renderFrontendEditor", args=args );
	}


	private string function renderPreview( event, rc, prc, struct args={} ) {
		var pageId   = args.pageId   ?: 0;
		var renderer = args.renderer ?: "";
		var content  = args.content  ?: "";

		event.initializePresideSiteteePage( pageId=pageId );

		if ( Len( Trim( renderer ) ) and contentRendererService.rendererExists( name=renderer, context="container" ) ) {
			return contentRendererService.render(
				  renderer = renderer
				, data     = content
				, context  = "container"
			);
		};

		return content;
	}

	private boolean function _isPageOrPageType( required string object ) {
		if ( arguments.object == "page" ) {
			return true;
		}

		return presideObjectService.objectExists( arguments.object ) && presideObjectService.isPageType( arguments.object );
	}

	private void function _denyUnlessPageOrPageType( required any event, required string object ) {
		if ( !_isPageOrPageType( arguments.object ) ) {
			arguments.event.adminAccessDenied();
		}
	}

	private void function _denyUnlessPagePermission( required any event, required string permissionKey, required string pageId ) {
		if ( !Len( Trim( arguments.pageId ) ) || !hasCmsPermission( permissionKey=arguments.permissionKey, context="page", contextKeys=[ arguments.pageId ] ) ) {
			arguments.event.adminAccessDenied();
		}
	}

	private void function _denyUnlessRecordIsPage( required any event, required string pageId, required string recordId ) {
		if ( Len( Trim( arguments.recordId ) ) && arguments.recordId != arguments.pageId ) {
			arguments.event.adminAccessDenied();
		}
	}
}
component {

	property name="frontendEditingService" inject="frontendEditingService";
	property name="contentRendererService" inject="contentRendererService";
	property name="presideObjectService"   inject="presideObjectService";
	property name="versioningService"      inject="versioningService";
	property name="siteTreeService"        inject="siteTreeService";


<!--- actions --->
	public void function saveAction( event, rc, prc ) {
		var pageId   = rc.pageId   ?: "";
		var object   = rc.object   ?: "";
		var property = rc.property ?: "";
		var recordId = rc.recordId ?: "";
		var content  = rc.content  ?: "";
		var renderer = rc.renderer ?: "";
		var success  = "";

		success = frontendEditingService.saveContent(
			  object   = object
			, property = property
			, recordId = ( object == "page" ? pageId : recordId )
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


		if ( !hasCmsPermission( permissionKey="sitetree.publish", context="page", contextKeys=[ pageId ] ) ) {
			event.adminAccessDenied();
		}

		if ( object == "page" || presideObjectService.isPageType( object ) ) {
			siteTreeService.publishDraft( recordId );
		} else {
			versioningService.publishLatestDraft( object, recordId );
			event.audit(
				 action   = "frontend_publish_changes"
				, type     = "frontendeditor"
				, detail   = { object=object, recordId=recordId }
				, recordId = recordId
			);
		}

		event.renderData( type="json", data={
			  success  = true
			, message  = translateResource( "cms:frontendeditor.publish.success" )
		} );
	}

	public void function getHistoryForAjaxDataTables( event, rc, prc ) {
		var recordId = rc.id       ?: "";
		var object   = rc.object   ?: "";
		var property = rc.property ?: "";

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
		var i18nBase      = presideObjectService.getResourceBundleUriRoot( object );
		var objectTitle   = LCase( translateResource( "#i18nBase#title.singular" ) );
		var recordLabel   = renderLabel( object, recordId );
		var changedFields = [];

		if ( object == "page" || presideObjectService.isPageType( object ) ) {
			changedFields = siteTreeService.getDraftChangedFields( recordId );
		} else {
			changedFields = versioningService.getDraftChangedFields( object, recordId );
		}

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
				, data = { prompt=prompt, publishable=true }
			);
		} else {
			event.renderData(
				  type = "json"
				, data = { prompt=translateResource( "cms:frontendeditor.publish.not.required.alert" ), publishable=false }
			);
		}
	}

// VIEWLETS
	private string function renderFrontendEditor( event, rc, prc, struct args={} ) {
		if ( !event.isAdminUser() ) {
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
}
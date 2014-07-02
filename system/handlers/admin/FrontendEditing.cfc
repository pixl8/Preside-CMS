component output=false {

	property name="frontendEditingService" inject="frontendEditingService";
	property name="contentRendererService" inject="contentRendererService";
	property name="presideObjectService"   inject="presideObjectService";


<!--- actions --->
	public void function saveAction( event, rc, prc ) output=false {
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
			frontendEditingService.discardDraft(
				  object   = object
				, property = property
				, recordId = recordId
				, content  = content
				, owner    = event.getAdminUserId()
			);

			event.renderData( type="json", data={
				  success  = true
				, message  = translateResource( "cms:frontendeditor.save.success" )
				, rendered = renderViewlet( event="admin.frontendediting.renderPreview", args={ content=content, renderer=renderer, pageId=pageId } )
			} );
		} else {
			event.renderData( type="json", data={ success=false, message=translateResource( "cms:frontendeditor.save.unknown.error" ) } );
		}
	}

	public void function saveDraftAction( event, rc, prc ) output=false {
		var success = frontendEditingService.saveDraft(
			  object   = rc.object   ?: ""
			, property = rc.property ?: ""
			, recordId = rc.recordId ?: ""
			, content  = rc.content  ?: ""
			, owner    = event.getAdminUserId()
		);

		if ( success ) {
			event.renderData( type="json", data={ success = true } );
		} else {
			event.renderData( type="json", data={ success=false, error=translateResource( "cms:frontendeditor.save.unknown.error" ) } );
		}
	}

	public void function discardDraftAction( event, rc, prc ) output=false {
		var success = frontendEditingService.discardDraft(
			  object   = rc.object   ?: ""
			, property = rc.property ?: ""
			, recordId = rc.recordId ?: ""
			, owner    = event.getAdminUserId()
		);

		if ( success ) {
			event.renderData( type="json", data={ success = true, message=translateResource( "cms:frontendeditor.draft.discarded.success" ) } );
		} else {
			event.renderData( type="json", data={ success=false, error=translateResource( "cms:frontendeditor.discard.draft.unknown.error" ) } );
		}
	}

	public void function getHistoryForAjaxDataTables( event, rc, prc ) output=false {
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

	public void function getVersionContent( event, rc, prc ) output=false {
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

	public void function previewVersionContent( event, rc, prc ) output=false {
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

			preview = '<div class="version-preview">#preview#</div>';
		}

		event.renderData( type="html", data=preview );
	}

// VIEWLETS
	private string function renderFrontendEditor( event, rc, prc, struct args={} ) output=false {
		if ( !event.isAdminUser() ) {
			return args.renderedContent ?: ( args.rawContent ?: "" );
		}

		var control  = args.control  ?: "richeditor";

		args.renderer = args.renderer ?: contentRendererService.getRendererForField( fieldAttributes = { control = control } );
		args.draftContent = frontendEditingService.getDraft(
			  object   = args.object   ?: ""
			, property = args.property ?: ""
			, recordId = args.recordId ?: ""
			, owner    = event.getAdminUserId()
		);

		return renderView( view="/admin/frontendediting/renderFrontendEditor", args=args );
	}


	private string function renderPreview( event, rc, prc, struct args={} ) output=false {
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
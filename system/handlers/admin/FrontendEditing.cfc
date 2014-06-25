<cfcomponent output="false">

	<cfproperty name="frontendEditingService" inject="frontendEditingService" />
	<cfproperty name="contentRendererService" inject="contentRendererService" />


<!--- actions --->
	<cffunction name="saveAction" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
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
		</cfscript>
	</cffunction>

	<cffunction name="saveDraftAction" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
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
		</cfscript>
	</cffunction>

	<cffunction name="discardDraftAction" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
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
		</cfscript>
	</cffunction>

<!--- viewlets --->
	<cffunction name="renderFrontendEditor" access="private" returntype="string" output="false">
		<cfargument name="event"       type="any"    required="true" />
		<cfargument name="rc"          type="struct" required="true" />
		<cfargument name="prc"         type="struct" required="true" />
		<cfargument name="viewletArgs" type="struct" required="false" default="#StructNew()#" />

		<cfscript>
			if ( !event.isAdminUser() ) {
				return viewletArgs.renderedContent ?: ( viewletArgs.rawContent ?: "" );
			}

			var control  = viewletArgs.control  ?: "richeditor";

			viewletArgs.renderer = viewletArgs.renderer ?: contentRendererService.getRendererForField( fieldAttributes = { control = control } );
			viewletArgs.draftContent = frontendEditingService.getDraft(
				  object   = viewletArgs.object   ?: ""
				, property = viewletArgs.property ?: ""
				, recordId = viewletArgs.recordId ?: ""
				, owner    = event.getAdminUserId()
			);

			return renderView( view="/admin/frontendediting/renderFrontendEditor", args=viewletArgs );
		</cfscript>
	</cffunction>

	<cffunction name="renderPreview" access="private" returntype="string" output="false">
		<cfargument name="event"       type="any"    required="true" />
		<cfargument name="rc"          type="struct" required="true" />
		<cfargument name="prc"         type="struct" required="true" />
		<cfargument name="viewletArgs" type="struct" required="false" default="#StructNew()#" />

		<cfscript>
			var pageId   = viewletArgs.pageId   ?: 0;
			var renderer = viewletArgs.renderer ?: "";
			var content  = viewletArgs.content  ?: "";

			event.initializePresideSiteteePage( pageId=pageId );

			if ( Len( Trim( renderer ) ) and contentRendererService.rendererExists( name=renderer, context="container" ) ) {
				return contentRendererService.render(
					  renderer = renderer
					, data     = content
					, context  = "container"
				);
			};

			return content;
		</cfscript>
	</cffunction>

</cfcomponent>
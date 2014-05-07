<cfcomponent output="false" extends="preside.system.base.AdminHandler">

	<cfproperty name="siteTreeService"  inject="siteTreeService"  />
	<cfproperty name="formsService"     inject="formsService"     />
	<cfproperty name="pageTypesService" inject="pageTypesService" />
	<cfproperty name="validationEngine" inject="validationEngine" />

	<cffunction name="preHandler" access="public" returntype="void" output="false">
		<cfargument name="event"          type="any"    required="true" />
		<cfargument name="action"         type="string" required="true" />
		<cfargument name="eventArguments" type="struct" required="true" />

		<cfscript>
			super.preHandler( argumentCollection = arguments );

			if ( !event.hasAdminPermission( "sitetree" ) ) {
				event.adminAccessDenied();
			}

			prc.homepage = siteTreeService.getSiteHomepage();

			event.addAdminBreadCrumb(
				  title = translateResource( "cms:sitetree" )
				, link  = event.buildAdminLink( linkTo="sitetree" )
			);
		</cfscript>
	</cffunction>

	<cffunction name="index" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			prc.activeTree = siteTreeService.getTree( trash = false, format="nestedArray", selectFields=[ "id", "label", "slug", "active", "page_type", "datecreated", "datemodified", "_hierarchy_slug as full_slug", "trashed" ] );
			prc.treeTrash  = siteTreeService.getTree( trash = true , format="nestedArray", selectFields=[ "id", "label", "slug", "active", "page_type", "datecreated", "datemodified", "_hierarchy_slug as full_slug", "trashed", "old_slug" ] );
		</cfscript>
	</cffunction>

	<cffunction name="addPage" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var parentPageId = rc.parent_page ?: "";
			var pageType     = rc.page_type ?: "";

			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:sitetree.addPage.title" )
				, link  = ""
			);

			prc.parentPage = siteTreeService.getPage(
				  id              = parentPageId
				, includeInactive = true
				, selectFields    = [ "label" ]
			);
			if ( not prc.parentPage.recordCount ) {
				getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.page.not.found.error" ) );
				setNextEvent( url = event.buildAdminLink( linkTo="sitetree" ) );
			}

			if ( !pageTypesService.pageTypeExists( pageType ) ) {
				getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
			}
			pageType = pageTypesService.getPageType( pageType );

			prc.mainFormName  = "preside-objects.page.add";
			prc.mergeFormName = _getPageTypeFormName( pageType, "add" );
		</cfscript>
	</cffunction>

	<cffunction name="addPageAction" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var parent            = rc.parent_page ?: "";
			var pageType          = rc.page_type   ?: "";
			var formName          = "preside-objects.page.add";
			var formData          = "";
			var validationResult  = "";
			var newId             = "";
			var persist           = "";

			if ( !pageTypesService.pageTypeExists( pageType ) ) {
				getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
			}
			pageType = pageTypesService.getPageType( pageType );
			var mergeFormName = _getPageTypeFormName( pageType, "add" );
			if ( Len( Trim( mergeFormName ) ) ) {
				formName = formsService.getMergedFormName( formName, mergeFormName );
			}

			formData             = event.getCollectionForForm( formName );
			formData.parent_page = parent;
			formData.page_type   = rc.page_type;
			formData.site        = siteTreeService.getDefaultSiteId();

			validationResult = validateForm( formName=formName, formData=formData );

			if ( not validationResult.validated() ) {
				getPlugin( "MessageBox" ).error( translateResource( "cms:sitetree.data.validation.error" ) );
				persist = formData;
				persist.validationResult = validationResult;
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree.addPage" ), persistStruct=persist );
			}

			newId = siteTreeService.addPage( argumentCollection = formData );

			getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.pageAdded.confirmation" ) );
			if ( Val( event.getValue( name="_addanother", defaultValue=0 ) ) ) {
				persist = formData;
				StructDelete( persist, "id" );
				StructDelete( persist, "label" );
				StructDelete( persist, "slug" );

				setNextEvent( url=event.buildAdminLink( linkTo="sitetree.addPage", queryString="parent_page=#parent#&page_type=#rc.page_type#" ), persistStruct=persist );
			} else {
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree", querystring="selected=#newId#" ) );
			}
		</cfscript>
	</cffunction>

	<cffunction name="editPage" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var pageId           = event.getValue( "id", "" );
			var validationResult = event.getValue( name="validationResult", defaultValue="" );
			var pageType         = "";

			prc.page = siteTreeService.getPage( id = pageId );

			if ( not prc.page.recordCount ) {
				getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.page.not.found.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
			}

			if ( !pageTypesService.pageTypeExists( prc.page.page_type ) ) {
				getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
			}
			pageType = pageTypesService.getPageType( prc.page.page_type );

			prc.mainFormName  = "preside-objects.page.edit";
			prc.mergeFormName = _getPageTypeFormName( pageType, "edit" )

			prc.page = QueryRowToStruct( prc.page );
			var savedData = getPresideObject( pageType.getPresideObject() ).selectData( filter={ page = pageId } );
			StructAppend( prc.page, QueryRowToStruct( savedData ) );

			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:sitetree.editPage.crumb", data=[ prc.page.label ] )
				, link  = ""
			);
		</cfscript>
	</cffunction>

	<cffunction name="editPageAction" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var pageId            = event.getValue( "id", "" );
			var validationRuleset = "";
			var validationResult  = "";
			var newId             = "";
			var persist           = "";
			var formName          = "preside-objects.page.edit";
			var formData          = "";
			var page              =  siteTreeService.getPage(
				  id              = pageId
				, includeInactive = true
			);

			if ( not page.recordCount ) {
				getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.page.not.found.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
			}

			if ( !pageTypesService.pageTypeExists( page.page_type ) ) {
				getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
			}
			pageType = pageTypesService.getPageType( page.page_type );
			var mergeFormName = _getPageTypeFormName( pageType, "edit" )
			if ( Len( Trim( mergeFormName ) ) ) {
				formName = formsService.getMergedFormName( formName, mergeFormName );
			}

			formData         = event.getCollectionForForm( formName );
			formData.id      = pageId;
			formData.site    = siteTreeService.getDefaultSiteId();
			validationResult = validateForm( formName=formName, formData=formData );

			if ( not validationResult.validated() ) {
				getPlugin( "MessageBox" ).error( translateResource( "cms:sitetree.data.validation.error" ) );
				persist = formData;
				persist.validationResult = validationResult;
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editPage", querystring="id=#pageId#" ), persistStruct=persist );
			}

			try {
				siteTreeService.editPage( argumentCollection = formData );
			} catch( "SiteTreeService.BadParent" e ) {
				validationResult.addError( fieldname="parent_page", message="cms:sitetree.validation.badparent.error" );

				getPlugin( "MessageBox" ).error( translateResource( "cms:sitetree.data.validation.error" ) );
				persist = formData;
				persist.validationResult = validationResult;
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editPage", querystring="id=#pageId#" ), persistStruct=persist );
			}

			getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.pageEdited.confirmation" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree", querystring="selected=#pageId#" ) );
		</cfscript>
	</cffunction>

	<cffunction name="trashPageAction" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var pageId  = event.getValue( "id", "" );
			var page    = siteTreeService.getPage( id=pageId, includeInactive=true );

			if ( pageId eq prc.homepage.id ) {
				getPlugin( "MessageBox" ).error( translateResource( uri="cms:sitetree.pageDelete.error.root.page" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
			}

			if ( not page.recordCount ) {
				getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.page.not.found.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
			}

			siteTreeService.trashPage( pageId );

			getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.pageTrashed.confirmation" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree", querystring="selected=#page.parent_page#"  ) );
		</cfscript>
	</cffunction>

	<cffunction name="deletePageAction" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var pageId = event.getValue( "id", "" );

			if ( pageId eq prc.homepage.id ) {
				getPlugin( "MessageBox" ).error( translateResource( uri="cms:sitetree.pageDelete.error.root.page" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
			}

			siteTreeService.permanentlyDeletePage( event.getValue( "id", "" ) );

			getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.pageDeleted.confirmation" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		</cfscript>
	</cffunction>

	<cffunction name="emptyTrashAction" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			siteTreeService.emptyTrash();

			getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.trashEmptied.confirmation" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		</cfscript>
	</cffunction>

	<cffunction name="restorePage" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var pageId = event.getValue( "id", "" );
			prc.page =  siteTreeService.getPage(
				  id          = pageId
				, includeInactive = true
				, includeTrash    = true
			);

			if ( not prc.page.recordCount ) {
				getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.page.not.found.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
			}

			prc.page = QueryRowToStruct( prc.page );

			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:sitetree.restorePage.crumb", data=[ prc.page.label ] )
				, link  = ""
			);
		</cfscript>
	</cffunction>

	<cffunction name="restorePageAction" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var pageId            = event.getValue( "id", "" );
			var formName          = "preside-objects.page.restore";
			var formData          = event.getCollectionForForm( formName );
			var validationResult  = "";
			var newId             = "";
			var persist           = "";

			formData.site = siteTreeService.getDefaultSiteId();
			validationResult = validateForm( formName = formName, formData = formData );

			if ( not validationResult.validated() ) {
				getPlugin( "MessageBox" ).error( translateResource( "cms:sitetree.data.validation.error" ) );
				persist = formData;
				persist.validationResult = validationResult;
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree.restorePage", querystring="id=#pageId#" ), persistStruct=persist );
			}

			siteTreeService.restorePage(
				  id      = pageId
				, parent_page = event.getValue( "parent_page", "" )
				, slug        = event.getValue( "slug", "" )
				, active      = event.getValue( "active", "" )
			);

			getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.pageRestored.confirmation" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree", queryString="selected=#pageId#" ) );
		</cfscript>
	</cffunction>

	<cffunction name="reorderChildren" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var pageId = event.getValue( "id", "" );

			prc.page = siteTreeService.getPage(
				  id          = pageId
				, includeInactive = true
			);

			if ( not prc.page.recordCount ) {
				getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.page.not.found.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
			}

			prc.childPages = siteTreeService.getDescendants(
				  id       = pageId
				, depth        = 1
				, selectFields = [ "id", "label" ]
			);

			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:sitetree.reorderChildren.crumb", data=[ prc.page.label ] )
				, link  = ""
			);
		</cfscript>
	</cffunction>

	<cffunction name="reorderChildrenAction" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var pageId  = event.getValue( "id", "" );
			var sortedPages = ListToArray( event.getValue( "ordered", "" ) );
			var i = 0;

			for( i=1; i lte ArrayLen( sortedPages ); i++ ){
				siteTreeService.editPage(
					  id     = sortedPages[i]
					, sort_order = i
				);
			}

			getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.childrenReordered.confirmation" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree", queryString="selected=#pageId#" ) );
		</cfscript>
	</cffunction>

	<cffunction name="picker" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			prc.tree = siteTreeService.getTree(
				  trash        =  false
				, format       = "nestedArray"
				, selectFields = [ "id", "label" ]
			);

			event.setView( noLayout=true, view="/admin/sitetree/picker" );
		</cfscript>
	</cffunction>

	<cffunction name="pageTypeDialog" access="private" returntype="string" output="false">
		<cfargument name="event"       type="any"    required="true" />
		<cfargument name="rc"          type="struct" required="true" />
		<cfargument name="prc"         type="struct" required="true" />
		<cfargument name="viewletArgs" type="struct" required="false" default="#StructNew()#" />

		<cfscript>
			viewletArgs.pageTypes = pageTypesService.listPageTypes();

			return renderView( view="admin/sitetree/pageTypeDialog", args=viewletArgs );
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="_getPageTypeFormName" access="private" returntype="string" output="false">
		<cfargument name="pageType" type="any" required="true" />
		<cfargument name="addorEdit" type="string" required="true" />

		<cfscript>
			var specificForm = addOrEdit == "add" ? pageType.getAddForm() : pageType.getEditForm();
			var defaultForm  = pageType.getDefaultForm();


			if ( formsService.formExists( specificForm ) ) {
				return specificForm;
			}
			if ( formsService.formExists( defaultForm ) ) {
				return defaultForm;
			}

			return "";
		</cfscript>
	</cffunction>
</cfcomponent>
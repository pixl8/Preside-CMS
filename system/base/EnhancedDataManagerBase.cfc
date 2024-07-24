component extends="preside.system.base.AdminHandler" {

	property name="datamanagerService"    inject="datamanagerService";
	property name="customizationService"  inject="dataManagerCustomizationService";
	property name="presideObjectService"  inject="presideObjectService";
	property name="permissionService"     inject="permissionService";
	property name="adminDataViewsService" inject="adminDataViewsService";
	property name="messageBox"            inject="messagebox@cbmessagebox";

	variables.permissionSubBase  = "";
	variables.systemDateRenderer = { renderer = "datetime", context="relative" };
	variables.permissionKeyCache = {};
	variables.maxTabCount        = 6;
	variables.sidebarNavigation  = false;

// PUBLIC ACTIONS
	public void function viewRecord( event, rc, prc ){
		var objectName = event.getCurrentEvent().reReplaceNoCase( "admin\.datamanager\.(.*?)\.viewRecord", "\1" );
		var recordId = rc.id ?: "";

		event.initializeDatamanagerPage( objectName=objectName, recordId=recordId, includeAllFormulaFields=true );

		if ( !isQuery( prc.record ) || !prc.record.recordcount ) {
			messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ prc.objectTitle ?: objectName  ] ) );
			setNextEvent( url=event.buildAdminLink( objectName=objectName ) );
		}

		var record   = QueryRowToStruct( prc.record );
		record.datecreated = _getNonVersionDateCreated( objectName, recordId );

		prc.pageTitle = prc.recordLabel ?: "";
		prc.pageIcon  = translateResource( uri="preside-objects.#objectName#:iconClass", defaultValue="fa-database" )
		prc.infoCard  = customizationService.runCustomization(
			  objectName     = objectName
			, action         = "renderInfoCard"
			, defaultHandler = "admin.datamanager.#objectName#._infoCard"
			, args           = {
				  objectName = objectName
				, recordId   = prc.recordId
				, record     = record
			  }
		);
		var defaultTabMethod = variables.sidebarNavigation ? "_tabWithSidebar" : "_tabs";
		prc.tabs  = customizationService.runCustomization(
			  objectName     = objectName
			, action         = "renderTabs"
			, defaultHandler = "admin.datamanager.#objectName#.#defaultTabMethod#"
			, args           = {
				  objectName = objectName
				, recordId   = prc.recordId
				, record     = record
			  }
		);

		prc.topRightButtons = customizationService.runCustomization(
			  objectName     = objectName
			, action         = "topRightButtons"
			, defaultHandler = "admin.datamanager.topRightButtons"
			, args           = { objectName=objectName, action="viewRecord", record=record, recordId=prc.recordId }
		);

		_overrideAdminLayout( argumentCollection=arguments );
		event.setView( "/admin/datamanager/_viewRecord" );
	}

// CUSTOMIZATIONS
	private boolean function checkPermission( event, rc, prc, args={} ) {
		var objectName       = args.object ?: "";
		var allowedOps       = datamanagerService.getAllowedOperationsForObject( objectName );
		var disallowedOps    = presideObjectService.getObjectAttribute( attributeName="datamanagerDisallowedOperations", objectName=objectName );
		var permissionBase   = variables.permissionBase ?: customizationService.runCustomization(
			  objectName    = ""
			, action        = "getPermissionBaseFromObjectName"
			, defaultResult = objectName
			, args          = { objectName=objectName }
		);
		var alwaysDisallowed = ListToArray( ListAppend( disallowedOps, "manageContextPerms" ) );
		var operationMapped  = [ "read", "add", "edit", "delete", "clone" ];
		var permissionKey    = _getPermissionKey( permissionBase, args.key );
		var hasPermission    = !alwaysDisallowed.find( args.key )
		                    && ( !operationMapped.find( args.key ) || allowedOps.find( args.key ) )
		                    && hasCmsPermission( permissionKey );

		if ( !hasPermission && IsTrue( args.throwOnError ?: "" ) ) {
			event.adminAccessDenied();
		}

		return hasPermission;
	}

	private string function recordBreadcrumb() {
		var objectName  = args.objectName  ?: "";
		var recordLabel = args.recordLabel ?: "";
		var recordId    = args.recordId    ?: "";
		var currentTab  = rc.tab ?: "";
		var firstTab    = variables.tabs[ 1 ] ?: "";

		if ( IsStruct( firstTab ) ) {
			firstTab = firstTab.id;
		}

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:datamanager.viewrecord.breadcrumb.title", data=[ recordLabel ] )
			, link  = event.buildAdminLink( objectName=objectName, recordId=recordId )
		);

		if ( variables.sidebarNavigation && Len( currentTab ) && currentTab != firstTab ) {
			var tabTitle = translateResource( uri="preside-objects.#objectName#:viewtab.#currentTab#.title", defaultValue=translateResource( uri="adminui:viewtab.#currentTab#.title", default="" ) );
			if ( Len( tabTitle ) ) {
				event.addAdminBreadCrumb(
					  title = tabTitle
					, link  = event.buildAdminLink( objectName=objectName, recordId=recordId, queryString="tab=#currentTab#" )
				);
			}
		}
	}

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		var objectName  = args.objectname ?: "";
		var recordId    = args.recordId   ?: "";
		var queryString = args.queryString ?: "";
		var qs          = "id=#recordId#";

		if ( Len( Trim( queryString ) ) ) {
			qs &= "&#queryString#";
		}

		return event.buildAdminLink( linkto="datamanager.#objectName#.viewRecord", queryString=qs );
	}

// HELPERS/VIEWLETS
	private string function _infoCard( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var record     = args.record ?: {};
		var _render    = function( field ) {
			var rendererEvent = "admin.datamanager.#objectName#._infoCard#field#";
			if ( getController().viewletExists( rendererEvent ) ) {
				return renderViewlet( event=rendererEvent, args=args );
			} else if ( record.keyExists( field ) ) {
				return adminDataViewsService.renderField( objectName, field, record.id, record[ field ] );
			} else {
				return '<em class="light-grey"><i class="fa fa-fw fa-exclamation-triangle"></i> ' & translateResource( uri="adminui:no.infocard.renderer", data=[ field ] ) & '</em>';
			}
		};

		args.infoDescription = variables.infoDescription ?: "";
		if ( Len( Trim( args.infoDescription ) ) ) {
			args.infoDescription = _render( args.infoDescription );
		}

		args.col1 = Duplicate( variables.infoCol1 ?: [] );
		args.col2 = Duplicate( variables.infoCol2 ?: [] );
		args.col3 = Duplicate( variables.infoCol3 ?: [ "created", "modified" ] );

		announceInterception( "preRenderDataManagerObjectInfoCard", args );

		for( var i=1; i<=3; i++ ) {
			for( var n=args[ "col#i#" ].len(); n>0; n-- ) {
				var field = args[ "col#i#" ][ n ];
				var rendered = _render( field );

				if ( rendered.trim().len() ) {
					args[ "col#i#" ][ n ] = rendered;
				} else {
					args[ "col#i#" ].deleteAt( n );
				}
			}
		}

		if ( args.col1.len() || args.col2.len() || args.col3.len() ) {
			if ( !IsArray( args.infoColSizes ?: "" ) ) {
				if ( IsArray( variables.infoColSizes ?: "" ) && ArrayLen( variables.infoColSizes ) == 3 ) {
					args.infoColSizes = variables.infoColSizes;

				} else {
					args.infoColSizes = [ 4, 4, 4 ];

					if ( !ArrayLen( args.col2 ) ) {
						if ( !ArrayLen( args.col3 ) ) {
							args.infoColSizes = [ 12, 0, 0 ];
						} else {
							args.infoColSizes = [ 8, 0, 4 ];
						}
					}
				}
			}

			event.include( "/css/admin/specific/datamanager/infocard/" );
			return renderView( view="/admin/datamanager/_infoCard", args=args );
		}

		return "";
	}

	private string function _tabWithSidebar( event, rc, prc, args={} ) {
		var objectName  = args.objectName ?: "";
		args.tabs       = Duplicate( variables.tabs ?: [ "default" ] );
		args.currentTab = rc.tab ?: "";

		announceInterception( "preRenderDataManagerObjectTabs", args );

		var sidebarMenuItems = [];
		var menuItem         = {};
		var firstTab         = "";
		args.availableTabs   = [];

		for( var tabId in args.tabs ) {
			menuItem = _buildSidebarMenuItem( argumentCollection=arguments, tabId=tabId );
			if ( StructCount( menuItem ) ) {
				if ( firstTab == "" ) {
					firstTab = IsStruct( tabId ) ? tabId.id : tabId;
				}
				if ( args.currentTab == "" && arrayIsEmpty( sidebarMenuItems ) ) {
					menuItem.active = true;
				}
				ArrayAppend( sidebarMenuItems, menuItem );
			}
		}

		var activeTab        = ArrayFind( args.availableTabs, args.currentTab ) ? args.currentTab : firstTab;
		var activeTabContent = customizationService.runCustomization( objectName=objectName, action="_#activeTab#Tab", args=args )

		if ( ArrayLen( sidebarMenuItems ) ) {
			prc.adminSidebarItems  = sidebarMenuItems;
			prc.adminSidebarHeader = customizationService.runCustomization(
				  objectName    = objectName
				, action        = "renderSidebarHeader"
				, defaultResult = ""
				, args          = args
			);
		}

		return activeTabContent;
	}

	private struct function _buildSidebarMenuItem( event, rc, prc, args={}, required any tabId ) {
		var tabId        = arguments.tabId;
		var subMenuItems = [];
		if ( isStruct( tabId ) ) {
			for( var tabChild in tabId.children ) {
				var childMenuItem = _buildSidebarMenuItem( argumentCollection=arguments, tabId=tabChild );
				if ( StructCount( childMenuItem ) ) {
					ArrayAppend( subMenuItems, _buildSidebarMenuItem( argumentCollection=arguments, tabId=tabChild ) );
				}
			}
			tabId = tabId.id;
		}

		var objectName = args.objectName ?: "";
		var itemArgs   = {
			  objectName   = objectName
			, recordId     = prc.recordId ?: ""
			, tabId        = tabId
			, currentTab   = args.currentTab ?: ""
			, subMenuItems = subMenuItems
		};
		var menuItem   = _newSidebarMenuItem( argumentCollection=itemArgs );

		var menuItemCustomisation = customizationService.runCustomization(
			  objectName = objectName
			, action     = "_#tabId#MenuItem"
			, args       = itemArgs
		);

		StructAppend( menuItem, menuItemCustomisation ?: {} );

		if ( menuItem.display ) {
			if ( ArrayIsEmpty( menuItem.subMenuItems ) ) {
				ArrayAppend( args.availableTabs, tabId );
			}
			return menuItem;
		}
		return {};
	}

	private struct function _newSidebarMenuItem(
		  required string objectName
		, required string recordId
		, required string tabId
		,          string currentTab   = ""
		,          array  subMenuItems = []
	) {
		var i18nBase        = "preside-objects.#arguments.objectName#:";
		var i18nDefaultBase = "adminui:";
		var hasChildren     = !ArrayIsEmpty( arguments.subMenuItems );
		var isOpen          = false;

		for( var child in arguments.subMenuItems ) {
			if ( isTrue( child.open ?: "" ) ) {
				isOpen = true;
				break;
			}
		}

		return {
			  link         = hasChildren ? "##" : getRequestContext().buildAdminLink( objectName=arguments.objectName, recordId=arguments.recordId, querystring="tab=#arguments.tabId#" )
			, title        = translateResource( uri=i18nBase & "viewtab.#arguments.tabId#.title", defaultValue=translateResource( i18nDefaultBase & "viewtab.#arguments.tabId#.title" ) )
			, badge        = ""
			, badgeClass   = ""
			, active       = !hasChildren && ( arguments.tabId == arguments.currentTab )
			, display      = true
			, open         = isOpen
			, submenuItems = arguments.subMenuItems
		}
	}

	private string function _tabs( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var i18nBase   = "preside-objects.#objectName#:";
		var i18nDefaultBase = "adminui:";

		args.tabs    = Duplicate( variables.tabs ?: [ "default" ] );
		args.maxTabs = variables.maxTabCount;

		announceInterception( "preRenderDataManagerObjectTabs", args );

		for( var i=1; i<=args.tabs.len(); i++ ) {
			var tabId = args.tabs[ i ];

			args.tabs[ i ] = {
				  id        = tabId
				, iconClass = translateResource( uri=i18nBase & "viewtab.#tabId#.iconclass", defaultValue=translateResource( i18nDefaultBase & "viewtab.#tabId#.iconclass" ) )
				, content   = customizationService.runCustomization( objectName=objectName, action="_#tabId#Tab", args=args )
				, title     = customizationService.runCustomization( objectName=objectName, action="_#tabId#TabTitle", args=args, defaultResult=translateResource( uri=i18nBase & "viewtab.#tabId#.title", defaultValue=translateResource( i18nDefaultBase & "viewtab.#tabId#.title" ) ) )
			};
		}
		for( var i=args.tabs.len(); i>0; i-- ) {
			if ( !Len( Trim( args.tabs[ i ].content ?: "" ) ) ) {
				args.tabs.deleteAt( i );
			}
		}

		if ( arrayLen( args.tabs ) ) {
			event.include( "/css/admin/specific/datamanager/viewtabs/" );
			return renderView( view="/admin/datamanager/_tabs", args=args );
		}
		return "";
	}

	private string function _infoCardCreated( event, rc, prc, args={} ) {
		var dateCreated = args.record.dateCreated;
		var createdBy   = args.record.created_by_plain ?: "";
		var text        = "";

		if ( createdBy.trim().len() ) {
			text = translateResource( uri="adminui:info.card.created", data=[ "<strong title=""#HtmlEditFormat( DateTimeFormat( dateCreated, "yyyy-mm-dd HH:nn:ss" ) )#"">" & renderContent( variables.systemDateRenderer.renderer, dateCreated, variables.systemDateRenderer.context ) & "</strong>", "<strong>" & createdBy & "</strong>" ] );
		} else {
			text = translateResource( uri="adminui:info.card.created.no.user", data=[ "<strong title=""#HtmlEditFormat( DateTimeFormat( dateCreated, "yyyy-mm-dd HH:nn:ss" ) )#"">" & renderContent( variables.systemDateRenderer.renderer, dateCreated, variables.systemDateRenderer.context ) & "</strong>" ] );
		}

		return "<span class=""grey""><i class=""fa fa-fw fa-plus""></i>&nbsp; " & text & "</span>";

	}

	private string function _infoCardModified( event, rc, prc, args={} ) {
		var dateCreated  = args.record.dateCreated;
		var dateModified = args.record.dateModified;

		if ( dateCreated == dateModified ) {
			return "";
		}

		var modifiedBy = args.record.lastupdated_by_plain ?: "";
		var text       = "";

		if ( modifiedBy.trim().len() ) {
			text = translateResource( uri="adminui:info.card.modified", data=[ "<strong title=""#HtmlEditFormat( DateTimeFormat( dateModified, "yyyy-mm-dd HH:nn:ss" ) )#"">" & renderContent( variables.systemDateRenderer.renderer, dateModified, variables.systemDateRenderer.context ) & "</strong>", "<strong>" & modifiedBy & "</strong>" ] );
		} else {
			text = translateResource( uri="adminui:info.card.modified.no.user", data=[ "<strong title=""#HtmlEditFormat( DateTimeFormat( dateModified, "yyyy-mm-dd HH:nn:ss" ) )#"">" & renderContent( variables.systemDateRenderer.renderer, dateModified, variables.systemDateRenderer.context ) & "</strong>" ] );
		}

		return "<span class=""grey""><i class=""fa fa-fw fa-pencil""></i>&nbsp; " & text & "</span>";
	}

	private string function _defaultTab( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		return "<p><em class=""light-grey""><i class=""fa fa-fw fa-exclamation-triangle""></i> TODO: implement your own <code>admin.datamanager.#objectName#._defaultTab</code> viewlet for your entity.</em></p>";
	}

	private string function _auditTrailTab( event, rc, prc, args={} ) {
		return renderViewlet( event="admin.audittrail.recordTrailViewlet", args={ recordId=args.recordId ?: "" } );
	}

	private string function _getNonVersionDateCreated( required string objectName, required string recordId ) {
		var record = presideObjectService.selectData(
			  id               = arguments.recordId
			, objectName       = arguments.objectName
			, fromVersionTable = false
			, allowDrafts      = true
			, selectFields     = [ "datecreated" ]
		);

		return record.datecreated ?: "";
	}

	private void function _overrideAdminLayout() {
		var objectName = prc.objectName ?: "";

		if ( !len( objectName ) ) {
			return;
		}

		var adminApplication = presideObjectService.getObjectAttribute( objectName=objectName, attributeName="dataManagerAdminApplication", defaultValue="" );
		var adminLayout      = applicationsService.getLayout( adminApplication );

		if ( !len( adminApplication ) || !len( adminLayout ) ) {
			return;
		}

		event.setLayout( adminLayout );
		event.getAdminBreadCrumbs()[ 1 ].link = event.buildLink( linkTo=applicationsService.getDefaultEvent( adminApplication ) );
	}

	private string function _getPermissionKey(
		  required string permissionBase
		, required string key
	) {
		var permissionKey = "#arguments.permissionBase#.#( arguments.key ?: "" )#";

		if ( !StructKeyExists( variables.permissionKeyCache, permissionKey ) ) {
			variables.permissionKeyCache[ permissionKey ] = permissionKey;

			if ( !_permissionExists( permissionKey ) ) {
				// map undefined permissions to sensible defaults
				switch( arguments.key ) {
					case "navigate":
					case "viewversions":
					case "usefilters":
						variables.permissionKeyCache[ permissionKey ] = _getPermissionKey( arguments.permissionBase, "read" );
					break;

					case "batchedit":
					case "translate":
					case "publish":
					case "savedraft":
						variables.permissionKeyCache[ permissionKey ] = _getPermissionKey( arguments.permissionBase, "edit" );
					break;

					case "batchdelete":
						variables.permissionKeyCache[ permissionKey ] = _getPermissionKey( arguments.permissionBase, "delete" );
					break;

					case "clone":
						variables.permissionKeyCache[ permissionKey ] = _getPermissionKey( arguments.permissionBase, "add" );
					break;

					case "managefilters":
						variables.permissionKeyCache[ permissionKey ] = "rulesengine.edit";
					break;
				}
			}
		}

		return variables.permissionKeyCache[ permissionKey ];
	}

	private boolean function _permissionExists( required string key ) {
		var allKeys = permissionService.listPermissionKeys();

		return ArrayFindNoCase( allKeys, arguments.key );
	}

}
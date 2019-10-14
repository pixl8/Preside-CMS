/**
 * @singleton
 * @presideservice
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @loginService.inject                loginService
	 * @pageTypesService.inject            pageTypesService
	 * @siteService.inject                 siteService
	 * @i18nService.inject                 i18n
	 * @coldboxController.inject           coldbox
	 * @presideObjectService.inject        presideObjectService
	 * @versioningService.inject           versioningService
	 * @websitePermissionService.inject    websitePermissionService
	 * @rulesEngineConditionService.inject rulesEngineConditionService
	 * @cloningService.inject              presideObjectCloningService
	 */
	public any function init(
		  required any loginService
		, required any pageTypesService
		, required any siteService
		, required any presideObjectService
		, required any coldboxController
		, required any i18nService
		, required any versioningService
		, required any websitePermissionService
		, required any rulesEngineConditionService
		, required any cloningService
	) {
		_setLoginService( arguments.loginService );
		_setPageTypesService( arguments.pageTypesService );
		_setSiteService( arguments.siteService );
		_setPresideObjectService( arguments.presideObjectService );
		_setColdboxController( arguments.coldboxController );
		_setI18nService( arguments.i18nService );
		_setVersioningService( arguments.versioningService );
		_setWebsitePermissionService( arguments.websitePermissionService );
		_setRulesEngineConditionService( arguments.rulesEngineConditionService );
		_setCloningService( arguments.cloningService );
		_setPageSlugsAreMultilingual();

		if ( $isFeatureEnabled( "sitetree" ) ) {
			_ensureSystemPagesExistInTree();
		}

		return this;
	}

// PUBLIC API METHODS
	public any function getTree(
		  boolean trash        = false
		, array   selectFields = []
		, string  format       = "query"
		, boolean useCache     = true
		, string  rootPageId   = ""
		, numeric maxDepth     = -1
		, boolean allowDrafts  = $getRequestContext().showNonLiveContent()

	) {
		var tree             = "";
		var rootPage         = "";
		var allowedPageTypes = _getPageTypesService().listSiteTreePageTypes();

		var filter           = "page.trashed = :trashed";
		if( !arguments.trash ){
			filter &= " and page.page_type in (:page_type)";
		}

		var maxDepth = arguments.maxDepth;
		var args     = {
			  orderBy            = "page._hierarchy_sort_order"
			, filter             = filter
			, filterParams       = { trashed = arguments.trash, page_type = allowedPageTypes }
			, useCache           = arguments.useCache
			, autoGroupBy        = true
			, allowDraftVersions = arguments.allowDrafts
		};

		if ( ArrayLen( arguments.selectFields ) ) {
			args.selectFields = arguments.selectFields;
			if ( format eq "nestedArray" and not args.selectFields.find( "_hierarchy_depth" ) and not args.selectFields.find( "page._hierarchy_depth" ) ) {
				ArrayAppend( args.selectFields, "page._hierarchy_depth" );
			}

			if ( !args.selectFields.find( "page._hierarchy_sort_order" ) ) {
				args.selectFields.append( "page._hierarchy_sort_order" );
			}
		}

		if ( Len( Trim( arguments.rootPageId ) ) ) {
			rootPage = getPage( id = arguments.rootPageId, selectField = [ "_hierarchy_child_selector", "_hierarchy_depth" ] );

			args.filter       &= " and page._hierarchy_lineage like :_hierarchy_lineage";
			args.filterParams._hierarchy_lineage = rootPage._hierarchy_child_selector;

			if ( maxDepth >= 0 && !isNull( rootPage._hierarchy_depth ) && isNumeric( rootPage._hierarchy_depth ) ) {
				maxDepth += rootPage._hierarchy_depth+1;
			}
		}

		if ( maxDepth >= 0 ) {
			args.filter       &= " and page._hierarchy_depth <= :_hierarchy_depth";
			args.filterParams._hierarchy_depth = maxDepth;
		}

		tree = _getPObj().selectData( argumentCollection = args );

		if ( arguments.format eq "nestedArray" ) {
			if ( Len( Trim( arguments.rootPageId ) ) ) {
				return _treeQueryToNestedArray( tree, rootPage );
			}
			return _treeQueryToNestedArray( tree );
		}

		return tree;
	}

	public query function getPage(
		  string  id
		, string  slug
		, string  systemPage
		, boolean includeTrash = false
		, array   selectFields = []
		, boolean useCache     = true
		, numeric version      = 0
		, boolean getLatest    = false
		, boolean allowDrafts  = $getRequestContext().showNonLiveContent()
		, string  site         = ""
		, array   bypassTenants = []

	) {
		var args = {
			  filter             = ""
			, filterParams       = {}
			, useCache           = arguments.useCache
			, allowDraftVersions = arguments.allowDrafts
			, bypassTenants      = arguments.bypassTenants
		};

		if ( StructKeyExists( arguments, "id" ) ) {
			args.filter = "page.id = :id";
			args.filterParams.id = arguments.id;

		} else if ( StructKeyExists( arguments, "slug" ) ) {
			args.filter          = "page.id = :id";
			args.filterParams.id = getPageIdBySlug( arguments.slug );

		} else if ( StructKeyExists( arguments, "systemPage" ) ) {
			args.filter       = "page.page_type = :page_type"
			args.filterParams = { page_type = arguments.systemPage }

		} else {
			throw(
				  type    = "SiteTreeService.GetPage.MissingArgument"
				, message = "Neither [id], [system_key] nor [slug] was passed to the getPage() method. You must specify one of either argument"
			);
		}

		if ( Len( Trim( arguments.site ) ) ) {
			args.tenantIds = { site=arguments.site };
		}

		if ( not arguments.includeTrash ) {
			args.filter &= " and page.trashed = '0'";
		}

		if ( ArrayLen( arguments.selectFields ) ) {
			args.selectFields = arguments.selectFields;
		}

		if ( arguments.version ) {
			args.fromVersionTable = true;
			args.specificVersion  = arguments.version;
		} else if ( arguments.getLatest ) {
			args.fromVersionTable = true;
		}

		return _getPObj().selectData( argumentCollection = args );
	}

	public query function getPagesForAjaxSelect(
		  numeric maxRows      = 1000
		, string  searchQuery  = ""
		, string  childPage    = ""
		, string  site         = ""
		, array   ids          = []
		, array   extraFilters = []
	) {
		var filter = { "page.trashed" = false };
		var extra  = Duplicate( arguments.extraFilters );
		var params = {};

		if ( arguments.ids.len() ) {
			extra.append( { filter={ "page.id"=arguments.ids } } );
		}
		if ( Len( Trim( arguments.searchQuery ) ) ) {
			extra.append( {
				  filter       = "page.title like :title"
				, filterParams = { title="%#arguments.searchQuery#%" }
			} );
		}

		if ( Len( Trim( arguments.childPage ) ) ) {
			var childPageRecord = getPage( id=arguments.childPage );
			extra.append( {
				  filter       = "page.id != :childpage and page._hierarchy_lineage not like :childpageselector"
				, filterParams = {
					  childPage         = { type="cf_sql_varchar", value=arguments.childPage }
					, childpageselector = { type="cf_sql_varchar", value="%/#childPageRecord._hierarchy_id#/%" }
				  }
			} );

			var pageTypes              = _getPageTypesService().listPageTypes( allowedAboveChild=childPageRecord.page_type );
			var allowedParentPageTypes = [];

			for( var pt in pageTypes ) {
				allowedParentPageTypes.append( pt.getId() );
			}

			extra.append( { filter={ page_type=allowedParentPageTypes } } );
		}

		return _getPobj().selectData(
			  selectFields       = [ 
				    "page.id as value"
				  , "page.title as text"
				  , "parent_page.title as parent"
				  , "page._hierarchy_depth as depth"
				  , "page.page_type"
				  , "page.active as active" 
			  ]
			, filter             = filter
			, extraFilters       = extra
			, maxRows            = arguments.maxRows
			, orderBy            = "page._hierarchy_sort_order"
			, allowDraftVersions = true
			, bypassTenants      = Len( Trim( arguments.site ) ) ? [ "site" ] : []
		);
	}

	public struct function getExtendedPageProperties(
		  required string  id
		, required string  pageType
		,          boolean getLatest   = false
		,          boolean allowDrafts = $getRequestContext().showNonLiveContent()
	) {
		var ptSvc = _getPageTypesService();

		if ( !ptSvc.pageTypeExists( arguments.pageType ) ) {
			return {};
		}

		var pt = ptSvc.getPageType( arguments.pageType );
		var pobj   = _getPresideObject( pt.getPresideObject() );
		var args  = { filter={ page=arguments.id }, allowDraftVersions=arguments.allowDrafts };
		if ( arguments.getLatest ) {
			args.fromVersionTable = true;
		}
		var record = pobj.selectData( argumentCollection=args );

		if ( !record.recordCount ) {
			return {};
		}

		for( var r in record ) { record = r; } // query to struct hack
		StructDelete( record, "id" );
		StructDelete( record, "datecreated" );
		StructDelete( record, "datemodified" );

		return record;
	}

	public any function getPageProperty(
		  required string  propertyName
		, required struct  page
		,          array   ancestors        = []
		,          any     defaultValue     = ""
		,          boolean cascading        = false
		,          string  cascadeMethod    = "closest"
		,          string  cascadeSkipValue = "inherit"

	) {
		var value          = "";
		var poService      = _getPresideObjectService();
		var collectedValue = [];
		var __valueExists  = function( v ) { return !IsNull( arguments.v ) && (!IsSimpleValue( arguments.v ) || Len( Trim( arguments.v ) ) ); };

		if ( StructKeyExists( arguments.page, arguments.propertyName ) ) {
			value = arguments.page[ arguments.propertyName ];
			if ( __valueExists( value ) && ( !IsSimpleValue( value ) || value != arguments.cascadeSkipValue ) ) {
				if ( arguments.cascading && arguments.cascadeMethod == "collect" ) {
					collectedValue.append( value );
				} else {
					return value;
				}
			}
		} else {
			var sourceObject = _getSourceObjectForPageProperty( arguments.propertyName, arguments.page.page_type ?: "" );
			if ( Len( Trim( sourceObject ) ) ) {
				if ( poService.isManyToManyProperty( sourceObject, arguments.propertyName ) ) {
					var relatedRecords = poService.selectManyToManyData(
						  objectName   = sourceObject
						, propertyName = arguments.propertyName
						, filter       = ( sourceObject == "page" ? { id = arguments.page.id } : { page = arguments.page.id } )
					);

					if ( relatedRecords.recordCount ) {
						if ( arguments.cascading && arguments.cascadeMethod == "collect" ) {
							collectedValue.append( relatedRecords );
						} else {
							return relatedRecords;
						}
					}
				} else {
					if ( Len( Trim( arguments.page.page_type ?: "" ) ) ) {
						StructAppend( arguments.page, getExtendedPageProperties( arguments.page.id, arguments.page.page_type ) );
					}

					if ( StructKeyExists( arguments.page, arguments.propertyName ) ) {
						value = arguments.page[ arguments.propertyName ];
						if ( __valueExists( value ) ) {
							if ( arguments.cascading && arguments.cascadeMethod == "collect" ) {
								collectedValue.append( value );
							} else {
								return value;
							}
						}
					}
				}
			}
		}

		if ( arguments.cascading ) {
			for( var i=arguments.ancestors.len(); i >= 1; i-- ){
				value = getPageProperty(
					  propertyName = arguments.propertyName
					, page         = arguments.ancestors[i]
				);

				if ( __valueExists( value ) ) {
					if ( arguments.cascading && arguments.cascadeMethod == "collect" ) {
						collectedValue.append( value );
					} else {
						return value;
					}
				}
			}
		}

		if ( collectedValue.len() ) {
			return collectedValue;
		}

		return arguments.defaultValue;
	}

	public query function getDescendants(
		  required string  id
		,          numeric depth        = 0
		,          array   selectFields = []
		,          boolean allowDrafts  = $getRequestContext().showNonLiveContent()
	) {
		var page = getPage( id = arguments.id, selectField = [ "_hierarchy_child_selector", "_hierarchy_depth" ], allowDrafts=arguments.allowDrafts );
		var args = "";

		if ( page.recordCount ) {
			args = {
				  filter             = "_hierarchy_lineage like :_hierarchy_lineage"
				, filterParams       = { _hierarchy_lineage = page._hierarchy_child_selector }
				, orderBy            = "_hierarchy_sort_order"
				, allowDraftVersions = arguments.allowDrafts
			};

			if ( arguments.depth ) {
				args.filter &= " and _hierarchy_depth <= :_hierarchy_depth";
				args.filterParams._hierarchy_depth = page._hierarchy_depth + arguments.depth;
			}

			if ( ArrayLen( arguments.selectFields ) ) {
				args.selectFields = arguments.selectFields;
			}

			return _getPObj().selectData( argumentCollection = args );
		}

		return QueryNew('');
	}

	public struct function getManagedChildrenForDataTable(
		  required string  parentId
		, required string  pageType
		, required string  objectName
		,          array   selectFields = []
		,          numeric startRow     = 1
		,          numeric maxRows      = 10
		,          string  orderBy      = "title"
		,          string  searchQuery  = ""
	) {
		var result = {};
		var args = {
			  objectName         = arguments.objectName
			, selectFields       = _prepareGridFieldsForSqlSelect( arguments.selectFields, arguments.objectName )
			, maxRows            = arguments.maxRows
			, startRow           = arguments.startRow
			, orderBy            = arguments.orderBy
			, filter             = "page.parent_page = :page.parent_page and page.page_type = :page.page_type and page.trashed = :page.trashed"
			, filterParams       = { "page.parent_page"=arguments.parentId, "page.page_type"=arguments.pageType, "page.trashed"=false }
			, allowDraftVersions = true
		};

		if ( Len( Trim( arguments.searchQuery ) ) ) {
			args.filter &= " and page.title like :page.title";
			args.filterParams[ "page.title" ] = "%" & arguments.searchQuery & "%";
		}

		if ( ListLen( args.orderBy, "." ) == 1 ) {
			var col = ListFirst( args.orderBy, " " );
			if ( StructKeyExists( _getPresideObjectService().getObjectProperties( arguments.pageType ), col ) ) {
				args.orderBy = "#arguments.pageType#.#args.orderBy#";
			} else {
				args.orderBy = "page.#args.orderBy#";
			}
		}

		result.records = _getPresideObjectService().selectData( argumentCollection = args );

		if ( arguments.startRow eq 1 and result.records.recordCount lt arguments.maxRows ) {
			result.totalRecords = result.records.recordCount;
		} else {
			args.maxRows = 0;
			args.startRow = 1;
			args.selectFields = [ "count( * ) as nRows" ];
			result.totalRecords = _getPresideObjectService().selectData( argumentCollection=args ).nRows;
		}

		return result;
	}

	public query function getAncestors(
		  required string  id
		,          numeric depth           = 0
		,          array   selectFields    = []
		,          boolean includeSiblings = false
		,          boolean allowDrafts     = $getRequestContext().showNonLiveContent()
		,          string  site            = ""
	) {
		var page = getPage( id = arguments.id, selectField = [ "_hierarchy_depth", "_hierarchy_lineage" ], allowDrafts=arguments.allowDrafts, site=arguments.site );
		var args = "";

		if ( page.recordCount and page._hierarchy_lineage neq "/" ) {
			args = {
				  filter             = "( _hierarchy_id in (:_hierarchy_id)"
				, filterParams       = { _hierarchy_id = { value=page._hierarchy_lineage, list=true, separator="/" } }
				, orderBy            = "_hierarchy_sort_order"
				, allowDraftVersions = arguments.allowDrafts
			};

			if ( arguments.includeSiblings ) {
				// would be nice not to have to make this additional call here, necessary due to using _hierarchy_id instead of id to form lineage
				var ancestors = getAncestors( id=arguments.id, selectFields=[ "id" ], allowDraftVersions=arguments.allowDrafts );
				args.filter &= " or parent_page in (:parent_page) or parent_page is null";
				args.filterParams.parent_page = { value=ValueList( ancestors.id ), list=true };
			}

			if ( arguments.depth ) {
				args.filter &= " ) and _hierarchy_depth >= :_hierarchy_depth";
				args.filterParams._hierarchy_depth = page._hierarchy_depth - arguments.depth;
			} else {
				args.filter &= " )";
			}

			if ( ArrayLen( arguments.selectFields ) ) {
				args.selectFields = arguments.selectFields;
			}

			if ( Len( Trim( arguments.site ) ) ) {
				args.tenantIds = { site=arguments.site };
			}

			return _getPObj().selectData( argumentCollection = args );
		}

		return QueryNew('');
	}

	public query function getSiteHomepage(
		  array   selectFields      = []
		, boolean createIfNotExists = true
		, boolean getLatest         = false
		, boolean allowDrafts       = false
		, numeric version           = 0
		, string  site              = ""
	) {
		var homepageArgs   = {
			  maxRows            = 1
			, orderBy            = "_hierarchy_sort_order"
			, selectFields       = arguments.selectFields
			, allowDraftVersions = arguments.allowDrafts
			, filter             = {
				  _hierarchy_depth = 0
				, active           = true
				, trashed          = false
			  }
		};

		if ( Len( Trim( arguments.site ) ) ) {
			homepageArgs.tenantIds = { site=arguments.site };
		}

		if ( arguments.version ) {
			homepageArgs.fromVersionTable = true;
			homepageArgs.specificVersion  = arguments.version;
		} else if ( arguments.getLatest ) {
			homepageArgs.fromVersionTable = true;
		}

		var homepage = _getPobj().selectData( argumentCollection=homepageArgs );


		if ( homepage.recordCount || !arguments.createIfNotExists ) {
			return homepage;
		}

		var loginSvc = _getLoginService();
		homepage = addPage(
			  title         = "Home"
			, slug          = ""
			, page_type     = "homepage"
			, active        = 1
			, userId        = ( loginSvc.isLoggedIn() ? loginSvc.getLoggedInUserId() : loginSvc.getSystemUserId() )
		);

		return getPage( argumentCollection=arguments, id=homepage );
	}

	public array function getPagesForNavigationMenu(
		  string  rootPage              = getSiteHomepage().id
		, numeric depth                 = 1
		, boolean includeInactive       = false
		, array   activeTree            = []
		, boolean expandAllSiblings     = true
		, array   selectFields          = [ "page.id", "page.title", "page.navigation_title", "page.exclude_children_from_navigation", "page.page_type" ]
		, boolean isSubMenu             = false
		, boolean allowDrafts           = $getRequestContext().showNonLiveContent()
		, boolean delayConditionalItems = $isFeatureEnabled( "fullPageCaching" )
	) {
		var args = arguments;
		var requiredSelectFields = [ "id", "title", "navigation_title", "exclude_children_from_navigation", "page_type", "exclude_from_navigation_when_restricted", "access_restriction" ];
		for( var field in requiredSelectFields) {
			if ( !args.selectFields.find( field ) && !args.selectFields.find( "page." & field ) ) {
				args.selectFields.append( "page." & field );
			}
		}

		var getNavChildren = function( parent, currentDepth, disallowedPageTypes ){
			filterParams.parent_page = parent;

			var result   = [];
			var extraFilters = [];

			if ( disallowedPageTypes.len() ) {
				extraFilters.append({
					  filter = "page_type not in (:page_type)"
					, filterParams = { page_type = arguments.disallowedPageTypes }
				});
			}

			var children = _getPObj().selectData(
				  selectFields       = args.selectFields
				, filter             = filter
				, filterParams       = filterParams
				, extraFilters       = extraFilters
				, savedFilters       = savedFilters
				, orderBy            = "sort_order"
				, allowDraftVersions = args.allowDrafts
			);

			for( var child in children ){
				var hasRestrictions = IsBoolean( child.exclude_from_navigation_when_restricted ) && child.exclude_from_navigation_when_restricted;
				var excluded        = hasRestrictions && !args.delayConditionalItems && !userHasPageAccess( child.id );

				if ( excluded ) {
					continue;
				}

				var fetchChildren = arguments.currentDepth < maxDepth;
				    fetchChildren = fetchChildren && !Val( child.exclude_children_from_navigation );
				    fetchChildren = fetchChildren && ( expandAllSiblings || activeTree.find( child.id ) );

				if (  fetchChildren  ) {
					child.children = getNavChildren( child.id, currentDepth+1, getManagedChildTypesForParentType( child.page_type ) );
				}

				var page = {
					  id              = child.id
					, title           = Len( Trim( child.navigation_title ?: "" ) ) ? child.navigation_title : child.title
					, children        = child.children ?: []
					, active          = ( activeTree.find( child.id ) > 0 )
					, hasRestrictions = args.delayConditionalItems && hasRestrictions
				};

				for( var field in child ) {
					if ( !StructKeyExists( page, field ) ) {
						page[ field ] = child[ field ];
					}
				}

				result.append( page );
			}

			return result;
		};

		var page = getPage(
			  id           = arguments.rootPage
			, selectFields = [
				  "page.id"
				, "page.exclude_from_navigation"
				, "page.exclude_from_sub_navigation"
				, "page.exclude_children_from_navigation"
				, "page._hierarchy_depth"
				, "page.page_type"
				, "parent_page.page_type as parent_type"
			]
		);

		var isManagedType   = Len( Trim( page.parent_type ) ) && getManagedChildTypesForParentType( page.parent_type ).findNoCase( page.page_type );
		var excludedFromNav = arguments.isSubMenu ? Val( page.exclude_children_from_navigation ) : Val( page.exclude_from_navigation );
		if ( isManagedType || excludedFromNav ) {
			return [];
		}

		var maxDepth            = Val( page._hierarchy_depth ) + ( arguments.depth < 1 ? 1 : arguments.depth );
		var disallowedPageTypes = getManagedChildTypesForParentType( page.page_type );

		var exclusionField = ( arguments.isSubMenu ? "exclude_from_sub_navigation" : "exclude_from_navigation" );
		var filter         = "parent_page = :parent_page and trashed = '0' and ( #exclusionField# is null or #exclusionField# = '0' )";
		var filterParams   = {};
		var savedFilters   = [];

		if ( !arguments.includeInactive ) {
			filter &= " and active = '1'";
			ArrayAppend( savedFilters, "livePages" );
		}

		return getNavChildren( rootPage, Val( page._hierarchy_depth )+1, disallowedPageTypes );
	}

	public string function addPage(
		  required string  title
		, required string  slug
		, required string  page_type
		,          string  parent_page
		,          string  userId      = _getLoginService().getLoggedInUserId()
		,          boolean isDraft     = false
		,          boolean audit       = true
	) {
		var data            = _getValidAddAndEditPageFieldsFromArguments( argumentCollection = arguments );
		var homepage        = getSiteHomepage( [ "id" ], false );
		var pageType        = _getPageTypesService().getPageType( arguments.page_type );
		var pobj            = _getPObj();
		var page            = "";
		var pageId          = "";
		var updated         = "";
		var parent          = "";
		var pageTypeObjData = {};
		var versionNumber   = "";

		if ( homepage.recordCount && !Len( Trim( arguments.parent_page ?: "" ) ) ) {
			throw(
				  type    = "SiteTreeService.MissingParent"
				, message = "Error when adding site tree page. You have not supplied a parent page and there is already a root page for the site. There can only be a single root page per site."
			);
		}

		if ( pageType.isSystemPageType() && getPage( systemPage=arguments.page_type ).recordCount ) {
			throw(
				  type    = "SiteTreeService.SystemPageExists"
				, message = "Error when adding site tree page. There can only be a single page of type [#arguments.page_type#] per site."
			);
		}

		StructAppend( data, {
			  created_by = arguments.userId
			, updated_by = arguments.userId
		} );

		transaction {
			StructAppend( data, _calculateSortOrderAndHierarchyFields( argumentCollection=arguments ) );

			versionNumber = _getPresideObjectService().getNextVersionNumber();

			pageId = pobj.insertData( data=data, versionNumber=versionNumber, insertManyToManyRecords=true, isDraft=arguments.isDraft, skipTrivialInterceptors=pageType.isSystemPageType() );

			if ( not Len( pageId ) and StructKeyExists( arguments, "id" ) ) {
				pageId = arguments.id;
			}

			pageTypeObjData = Duplicate( arguments );
			pageTypeObjData.page = pageTypeObjData.id = pageId;
			_getPresideObject( pageType.getPresideObject() ).insertData( data=pageTypeObjData, versionNumber=versionNumber, insertManyToManyRecords=true, isDraft=arguments.isDraft, skipTrivialInterceptors=pageType.isSystemPageType() );
		}

		$announceInterception( "postAddSiteTreePage", pageTypeObjData );

		if ( Len( Trim( pageId ) ) && arguments.audit ) {
			var auditDetail = Duplicate( arguments );
			auditDetail.id = pageId;

			$audit(
				  action   = arguments.isDraft ? "add_draft_page" : "add_page"
				, type     = "sitetree"
				, detail   = auditDetail
				, recordId = pageId
			);
		}

		return pageId;
	}

	public boolean function editPage( required string id, boolean isDraft=false, boolean skipAudit=false, boolean skipVersioning=false, boolean forceVersionCreation ) {
		var data             = _getValidAddAndEditPageFieldsFromArguments( argumentCollection = arguments );
		var pobj             = _getPObj();
		var existingPage     = "";
		var parent           = "";
		var newParent        = "";
		var updated          = 0;
		var sortOrderChanged = false;
		var slugChanged      = false;
		var parentChanged    = false;
		var pageType         = "";
		var versionNumber    = "";
		var pageTypeObj      = "";

		_checkForBadHomepageOperations( argumentCollection = arguments );

		transaction {
			existingPage = getPage( id=arguments.id, includeTrash=true, useCache=false, allowDrafts=true );
			if ( not existingPage.recordCount ) {
				return false;
			}

			if ( StructKeyExists( data, "sort_order" ) or StructKeyExists( data, "slug" ) or StructKeyExists( data, "parent_page" ) ) {

				sortOrderChanged = StructKeyExists( data, "sort_order"  ) and data.sort_order  neq existingPage.sort_order;
				slugChanged      = StructKeyExists( data, "slug"        ) and data.slug        neq existingPage.slug;
				parentChanged    = StructKeyExists( data, "parent_page" ) and data.parent_page neq ( IsNull( existingPage.parent_page ) ? "" : existingPage.parent_page );

				if ( parentChanged ) {
					if ( Len( arguments.parent_page ) ) {
						if ( arguments.parent_page eq arguments.id ) {
							throw(
								  type    = "SiteTreeService.BadParent"
								, message = "A page in the site tree can not be set as the parent of itself"
								, detail  = "Page with id, [#arguments.id#], was trying to set its parent page to itself"
							);
						}
						newParent = getPage( id = arguments.parent_page, useCache = false );
						if ( not newParent.recordCount ) {
							throw(
								  type    = "SiteTreeService.MissingParent"
								, message = "Error when moving site tree page. Parent page with id, [#arguments.parent_page#], was not found."
							);
						}
						if ( newParent._hierarchy_lineage contains "/#existingPage._hierarchy_id#/" ) {
							throw(
								  type    = "SiteTreeService.BadParent"
								, message = "A page in the site tree can not be the parent of one of its ancestors"
								, detail  = "Page with id, [#arguments.id#], was trying to set its parent page one of its descendants, [#arguments.parent_page#]"
							);
						}

						data.sort_order                = _calculateSortOrder( arguments.parent_page );
						data._hierarchy_lineage        = newParent._hierarchy_lineage & newParent._hierarchy_id & "/";
						data._hierarchy_child_selector = data._hierarchy_lineage & existingPage._hierarchy_id & "/%";
						data._hierarchy_depth          = newParent._hierarchy_depth + 1;
						data._hierarchy_sort_order     = newParent._hierarchy_sort_order & _paddedSortOrder( data.sort_order ) & "/";
						data._hierarchy_slug           = newParent._hierarchy_slug & ( slugChanged ? data : existingPage ).slug & "/";

					} else if ( IsBoolean( arguments.trashed ?: "" ) && arguments.trashed ) {
						data.sort_order                = _calculateSortOrder();
						data.parent_page               = "";
						data._hierarchy_lineage        = "/";
						data._hierarchy_child_selector = "/" & existingPage._hierarchy_id & "/%";
						data._hierarchy_depth          = 0;
						data._hierarchy_sort_order     = "/" & _paddedSortOrder( data.sort_order ) & "/";
						data._hierarchy_slug           = "/" & ( slugChanged ? data : existingPage ).slug & "/";
					} else {
						throw(
							  type    = "SiteTreeService.MissingParent"
							, message = "Cannot set empty parent page on a page that is not the homepage"
						);
					}

				} else if ( sortOrderChanged || slugChanged ) {
					parent = getPage( id=existingPage.parent_page, useCache=false );
					if ( sortOrderChanged ) {
						data._hierarchy_sort_order = parent._hierarchy_sort_order & "#_paddedSortOrder( data.sort_order )#/";
					}
					if ( slugChanged ) {
						data._hierarchy_slug = parent._hierarchy_slug & "#data.slug#/";
					}
				}
			}

			if ( StructKeyExists( data, "parent_page" ) and not Len( Trim( data.parent_page ) ) ) {
				data.parent_page = NullValue();
			}

			versionNumber = _getPresideObjectService().getNextVersionNumber();

			var pageDataHasChanged     = _getVersioningService().dataHasChanged( objectName="page", recordId=arguments.id, newData=arguments );
			var pageTypeDataHasChanged = false;

			if ( _getPageTypesService().pageTypeExists( existingPage.page_type ) ) {
				pageType               = _getPageTypesService().getPageType( existingPage.page_type );
				pageTypeObj            = _getPresideObject( pageType.getPresideObject() );
				pageTypeDataHasChanged = _getVersioningService().dataHasChanged( objectName=pageType.getPresideObject(), recordId=arguments.id, newData=arguments );
			}

			updated = pobj.updateData(
				  data                    = data
				, id                      = arguments.id
				, useVersioning           = !arguments.skipVersioning
				, versionNumber           = versionNumber
				, updateManyToManyRecords = true
				, forceVersionCreation    = arguments.forceVersionCreation ?: ( pageDataHasChanged || pageTypeDataHasChanged )
				, isDraft                 = arguments.isDraft
			);

			if ( _getPageTypesService().pageTypeExists( existingPage.page_type ) ) {
				if ( pageTypeObj.dataExists( filter={ page=arguments.id }, allowDraftVersions=true ) ) {
					_getPresideObject( pageType.getPresideObject() ).updateData(
						  data                    = arguments
						, filter                  = { page=arguments.id }
						, versionNumber           = versionNumber
						, updateManyToManyRecords = true
						, forceVersionCreation    = arguments.forceVersionCreation ?: ( pageDataHasChanged || pageTypeDataHasChanged )
						, isDraft                 = arguments.isDraft
						, useVersioning           = !arguments.skipVersioning
					);
				} else {
					var insertData = Duplicate( arguments );
					insertData.page = arguments.id;
					_getPresideObject( pageType.getPresideObject() ).insertData(
						  data                    = insertData
						, versionNumber           = versionNumber
						, insertManyToManyRecords = true
						, isDraft                 = arguments.isDraft
					);
				}
			}

			if ( !arguments.isDraft && ( sortOrderChanged or parentChanged or slugChanged ) ) {
				pobj.updateChildHierarchyHelpers(
					  oldData = existingPage
					, newData = data
				);
			}

			_getPresideObjectService().clearRelatedCaches( "page" );
			_getPresideObjectService().clearRelatedCaches( existingPage.page_type );
		}

		var interceptionArgs              = arguments;
		    interceptionArgs.existingPage = existingPage;

		$announceInterception( "postEditSiteTreePage", interceptionArgs );

		if ( updated && !arguments.skipAudit ) {
			for( var p in existingPage ) { existingPage = p };
			$audit(
				  action   = arguments.isDraft ? "save_draft_page" : "edit_page"
				, type     = "sitetree"
				, detail   = existingPage
				, recordId = arguments.id
			);
		}

		return updated;
	}

	public boolean function trashPage( required string id ) {
		var pobj     = _getPObj();
		var page    = "";
		var updated = 0;

		transaction {
			page = getPage( id = arguments.id );

			if ( page.recordCount ) {
				if ( _getPageTypesService().isSystemPageType( page.page_type ) ) {
					throw(
						  type    = "SiteTreeService.CannotTrashPage"
						, message = "You can not delete pages with a [#page.page_type#] page type"
					);
				}

				updated = editPage(
					  id          = arguments.id
					, parent_page = ""
					, trashed     = true
					, old_slug    = page.slug
					, slug        = CreateUUId()
					, skipAudit   = true
				);
			}
		}

		if ( updated ) {
			for( var p in page ) { var auditDetail = p; }
			$audit(
				  action   = "trash_page"
				, type     = "sitetree"
				, detail   = auditDetail
				, recordId = auditDetail.id
			);
		}

		return updated;
	}

	public boolean function restorePage(
		  required string id
		, required string parent_page
		, required string slug
		, required string active

	) {
		var pobj    = _getPObj();
		var page    = "";
		var updated = 0;

		transaction {
			page = getPage( id = arguments.id, includeTrash = true );

			if ( page.recordCount ) {
				updated = editPage(
					  id          = arguments.id
					, parent_page = arguments.parent_page
					, slug        = arguments.slug
					, active      = arguments.active
					, trashed     = false
					, skipAudit   = true
				);
			}
		}

		if ( updated ) {
			for( var p in page ) { var auditDetail = p; }
			$audit(
				  action   = "restore_page"
				, type     = "sitetree"
				, detail   = auditDetail
				, recordId = auditDetail.id
			);
		}

		return updated;
	}

	public string function clonePage(
		  required string  sourcePageId
		, required struct  newPageData
		, required boolean createAsDraft
		, required boolean cloneChildren
	) {
		var cloningService = _getCloningService();
		var bypassTenants  = Len( Trim( newPageData.site ?: "" ) ) ? [ "site" ] : [];
		var existingPage   = getPage( id=arguments.sourcePageId, useCache=false, allowDrafts=true, bypassTenants=bypassTenants );
		var versionNumber  = _getPresideObjectService().getNextVersionNumber();
		var newData        = StructCopy( arguments.newPageData );

		StructAppend( newData, _calculateSortOrderAndHierarchyFields(
			  parent_page   = newData.parent_page ?: existingPage.parent_page
			, slug          = newData.slug        ?: existingPage.slug
			, site          = newData.site        ?: existingPage.site
		) );

		var newPageId = cloningService.cloneRecord(
			  objectName    = "page"
			, recordId      = arguments.sourcePageId
			, data          = newData
			, isDraft       = arguments.createAsDraft
			, versionNumber = versionNumber
			, bypassTenants = bypassTenants
		);

		var pageTypeData = StructCopy( arguments.newPageData );
		    pageTypeData.page = newPageId;

		cloningService.cloneRecord(
			  objectName    = existingPage.page_type
			, recordId      = arguments.sourcePageId
			, newRecordId   = newPageId
			, data          = pageTypeData
			, isDraft       = arguments.createAsDraft
			, versionNumber = versionNumber
			, bypassTenants = bypassTenants
		);


		if ( arguments.cloneChildren ) {
			var children = _getPObj().selectData(
				  selectFields  = [ "id" ]
				, filter        = { parent_page=arguments.sourcePageId, trashed=false }
				, bypassTenants = bypassTenants
				, orderBy       = "sort_order"
			);

			var childPageData = { parent_page=newPageId };
			if ( Len( Trim( newPageData.site ) ) ) {
				childPageData.site = newPageData.site;
			}
			for( var child in children ) {
				clonePage(
					  sourcePageId   = child.id
					, newPageData    = childPageData
					, createAsDraft  = arguments.createAsDraft
					, cloneChildren  = true
					, bypassTenants  = bypassTenants
				);
			}
		}

		var auditDetail = StructCopy( arguments.newPageData );
		for( var p in existingPage ) {
			StructAppend( auditDetail, p, false );
		}
		auditDetail.id = newPageId;

		$audit(
			  action   = "clonepage"
			, type     = "sitetree"
			, detail   = auditDetail
			, recordId = newPageId
		);

		return newPageId;
	}

	public boolean function permanentlyDeletePage( required string id ) {
		var pobj     = _getPObj();
		var homepage = getSiteHomepage( [ "id" ] );
		var rootPage = "";
		var nDeleted = 0;

		if ( homepage.id eq arguments.id ) {
			throw(
				  type    = "SiteTreeService.BadHomepageOperation"
				, message = "You can not delete the homepage!"
			);
		}

		transaction {
			rootPage = getPage( id = arguments.id, includeTrash = true );

			if ( rootPage.recordCount ) {
				nDeleted = pobj.deleteData(
					  filter       = "id = :id or _hierarchy_lineage like :_hierarchy_lineage"
					, filterParams = { id = arguments.id, _hierarchy_lineage = rootPage._hierarchy_child_selector }
				);
			}
		}

		if ( nDeleted ) {
			for( var p in rootPage ) { var auditDetail = p; }
			$audit(
				  action   = "permanently_delete_page"
				, type     = "sitetree"
				, detail   = auditDetail
				, recordId = auditDetail.id
			);
		}

		return nDeleted;
	}

	public boolean function emptyTrash() {
		var pagesDeleted = _getPObj().deleteData( filter = { trashed = true } );

		if ( pagesDeleted ) {
			$audit(
				  action = "empty_trash"
				, type   = "sitetree"
			);
		}

		return pagesDeleted;
	}

	public struct function getActivePageFilter( string pageTableAlais="page" ) {
		return {
			  filter       = "#pageTableAlais#.trashed != '1' and #pageTableAlais#.active = '1' and ( #pageTableAlais#.embargo_date is null or now() > #pageTableAlais#.embargo_date ) and ( #pageTableAlais#.expiry_date is null or now() < #pageTableAlais#.expiry_date )"
			, filterParams = {}
		};
	}

	public void function ensureSystemPagesExistForSite( required string siteId ) {
		var siteService        = _getSiteService();
		var pageTypesService   = _getPageTypesService();
		var site               = siteService.getSite( arguments.siteId );
		var event              = _getColdboxController().getRequestService().getContext();
		var originalActiveSite = event.getSite();

		event.setSite( site );

		var pageTypes          = pageTypesService.listPageTypes();

		for( var pageType in pageTypes ) {
			var pageTypeId = pageType.getId();
			if ( pageTypesService.isSystemPageType( pageTypeId ) ) {
				var page = getPage( systemPage=pageTypeId, useCache=false );

				if ( !page.recordCount ) {
					_createSystemPage( pageType );
				}
			}
		}

		event.setSite( originalActiveSite );
	}

	public struct function getAccessRestrictionRulesForPage( required string pageId ) {
		var page = getPage( id=arguments.pageId, selectFields=[ "id", "parent_page", "access_restriction", "access_condition", "full_login_required", "grantaccess_to_all_logged_in_users" ] );

		if ( !page.recordCount ) {
			return {
				  access_restriction                 = "none"
				, access_condition                   = ""
				, full_login_required                = false
				, grantaccess_to_all_logged_in_users = false
			};
		}
		if ( !Len( Trim( page.access_restriction ?: "" ) ) || page.access_restriction == "inherit" ) {
			if ( Len( Trim( page.parent_page ) ) ) {
				return getAccessRestrictionRulesForPage( page.parent_page );
			} else {
				return {
					  access_restriction                 = "none"
					, access_condition                   = ""
					, full_login_required                = false
					, grantaccess_to_all_logged_in_users = false
				};
			}
		}

		return {
			  access_restriction                 = page.access_restriction
			, access_condition                   = page.access_condition
			, full_login_required                = page.full_login_required
			, grantaccess_to_all_logged_in_users = page.grantaccess_to_all_logged_in_users
			, access_defining_page               = page.id
		};
	}

	public boolean function userHasPageAccess( required string pageId ) {
		var restrictionRules = getAccessRestrictionRulesForPage( arguments.pageId );

		if ( [ "none", "partial" ].find( restrictionRules.access_restriction ) ) {
			return true;
		}

		if ( Len( Trim( restrictionRules.access_condition ) ) ) {
			return _getRulesEngineConditionService().evaluateCondition(
				  conditionId = restrictionRules.access_condition
				, context     = "webrequest"
			);
		} else {
			return _getWebsitePermissionService().hasPermission(
				  permissionKey = "pages.access"
				, context       = "page"
				, contextKeys   = [ restrictionRules.access_defining_page ]
				, forceGrantByDefault = IsBoolean( restrictionRules.grantaccess_to_all_logged_in_users ) && restrictionRules.grantaccess_to_all_logged_in_users
			);
		}
	}

	public numeric function getTrashCount() {
		var trashed = _getPobj().selectData(
			  selectFields = [ "Count(*) as page_count" ]
			, filter       = { trashed = true }
		);

		return Val( trashed.page_count ?: "" );
	}

	public array function getManagedChildTypesForParentType( required string parentType ) {
		return _getPageTypesService().getPageType( arguments.parentType ).getManagedChildTypes().listToArray();
	}

	public boolean function arePageSlugsMultilingual() {
		if ( _pageSlugsAreMultilingual ) {
			var featureEnabled = $getPresideSetting( "multilingual", "urls_enabled", false );

			return IsBoolean( featureEnabled ) && featureEnabled;
		}

		return false;
	}

	public array function getDraftChangedFields( required string pageId, string pageType ) {
		if ( !StructKeyExists( arguments, "pageType" ) ) {
			var page = getPage(
				  id          = arguments.pageId
				, getLatest   = true
				, allowDrafts = true
				, selectFields = [ "page.page_type" ]
			);

			if ( !page.recordCount ) {
				return [];
			}

			arguments.pageType = page.page_type;
		}

		var changedFields = _getVersioningService().getDraftChangedFields( "page", arguments.pageId );
		    changedFields.append( _getVersioningService().getDraftChangedFields( arguments.pageType, arguments.pageId ), true );

		return changedFields;
	}

	public boolean function publishDraft( required string pageId ) {
		var page = getPage(
			  id          = arguments.pageId
			, getLatest   = true
			, allowDrafts = true
		);

		if ( page.recordCount ) {
			for( var p in page ) { page = p; }

			page.append( getExtendedPageProperties(
				  id          = page.id
				, pageType    = page.page_type
				, getLatest   = true
				, allowDrafts = true
			) );

			var changedFields = getDraftChangedFields( page.id, page.page_type );
			var dataToSubmit = {};
			for( var field in changedFields ) {
				if ( StructKeyExists( page, field ) ) {
					dataToSubmit[ field ] = page[ field ];
				}
			}

			if ( dataToSubmit.count() ) {
				return editPage( argumentCollection=dataToSubmit, id=page.id, isDraft=false, forceVersionCreation=true );
			}
		}

		return false;
	}

	public boolean function discardDrafts( required string pageId ) {
		var page = getPage(
			  id          = arguments.pageId
			, getLatest   = true
			, allowDrafts = true
		);

		if ( page.recordCount ) {
			var versioningService = _getVersioningService();
			var latestPublishedVersion = versioningService.getLatestVersionNumber(
				  objectName    = "page"
				, recordId      = arguments.pageId
				, publishedOnly = true
			);

			if ( latestPublishedVersion ) {
				var newVersionNumber = versioningService.getNextVersionNumber();

				versioningService.promoteVersion(
					  objectName       = "page"
					, recordId         = arguments.pageId
					, versionNumber    = latestPublishedVersion
					, newVersionNumber = newVersionNumber
				);

				versioningService.promoteVersion(
					  objectName    = page.page_type
					, recordId      = arguments.pageId
					, versionNumber = latestPublishedVersion
					, newVersionNumber = newVersionNumber
				);

				for( var p in page ) { var auditDetail = p; }
				$audit(
					  action   = "discard_page_drafts"
					, type     = "sitetree"
					, detail   = auditDetail
					, recordId = page.id
				);

				return true;
			}
		}

		return false;
	}

	public string function getPageIdBySlug( required string slug ) {
		if ( arePageSlugsMultilingual() ) {
			return _getPageIdWithMultilingualSlug( arguments.slug );
		}
		var page = _getPObj().selectData(
			  selectFields = [ "page.id" ]
			, filter       = "page.slug = :slug and page._hierarchy_slug = :_hierarchy_slug" // this double match is for performance - the full slug cannot be indexed because of its potential size
			, filterParams = { slug = ListLast( arguments.slug, "/" ), _hierarchy_slug = arguments.slug }
		);

		if ( !page.recordcount && _isAutoRedirectEnabled() ) {
			_checkPageHistoryForSlug( arguments.slug );
		}

		return page.id ?: "";
	}

	public string function getPageIdBySystemPageType( required string pageType ) {
		var page = _getPObj().selectData(
			  selectFields = [ "page.id" ]
			, filter       = "page.page_type = :page_type"
			, filterParams = { page_type = arguments.pageType }
		);

		return page.id ?: "";
	}


// PRIVATE HELPERS
	private numeric function _calculateSortOrder( string parent_page="", string site="" ) {
		var result        = "";
		var filter        = "";
		var filterParams  = {};
		var extraFilters  = [];
		var bypassTenants = [];

		if ( !Len( Trim( arguments.parent_page ) ) ) {
			filter = "parent_page is null";
		} else {
			filter = { parent_page = arguments.parent_page };
		}

		if ( Len( Trim( arguments.site ) ) ) {
			extraFilters.append( { filter={ site=arguments.site } } );
			bypassTenants = [ "site" ];
		}

		result = _getPObj().selectData(
			  selectFields  = [ "Max( sort_order ) as sort_order" ]
			, filter        = filter
			, filterParams  = filterParams
			, useCache      = false
			, extraFilters  = extraFilters
			, bypassTenants = bypassTenants
		);

		if ( isNull( result.sort_order ) ) {
			return 1;
		}

		return Val( result.sort_order ) + 1;
	}

	private struct function _getValidAddAndEditPageFieldsFromArguments() {
		var data        = {};
		var arg         = "";
		var exists      = "";
		var systemField = "";

		for( arg in arguments ) {
			exists      = _getPresideObjectService().fieldExists( objectName="page", fieldName=arg );
			systemField = ListFindNoCase( "id,datecreated,datemodified,_hierarchy_id", arg ) or arg contains "_hierarchy_";

			if ( exists and not systemField and not IsNull( arguments[ arg ] ) ) {
				data[ arg ] = arguments[ arg ];
			}
		}

		return data;
	}

	private array function _treeQueryToNestedArray( required query treeQuery, any rootPage ) {
		var treeArray       = [];
		var node            = "";
		var parents         = [];
		var parent          = "";
		var startDepth      = StructKeyExists( arguments, "rootPage" ) ? arguments.rootPage._hierarchy_depth : 0;
		var firstLevelDepth = StructKeyExists( arguments, "rootPage" ) ? arguments.rootPage._hierarchy_depth + 1 : 0;

		for( node in treeQuery ){
			parents[ ( node._hierarchy_depth+1 ) - startDepth ] = node;
			node.children    = [];
			node.hasChildren = false;

			if ( ( node._hierarchy_depth - startDepth ) > firstLevelDepth ) {
				parent = parents[ ( node._hierarchy_depth ) - startDepth ];
				parent.hasChildren = true;
				ArrayAppend( parent.children, node );
			} else {
				ArrayAppend( treeArray, node );
			}
		}

		return treeArray;
	}

	private numeric function _getNextAvailableHierarchyId( string site="" ) {
		var filter = {};
		var bypassTenants = [];

		if ( Len( Trim( arguments.site ) ) ) {
			filter = { site=arguments.site };
			bypassTenants = [ "site" ];
		}
		var qry = _getPObj().selectData(
			  selectFields       = [ "Max( _hierarchy_id ) as max_id" ]
			, allowDraftVersions = true
			, filter             = filter
			, bypassTenants      = bypassTenants
			, useCache           = false
		);

		return IsNull( qry.max_id ) ? 1 : Val( qry.max_id ) + 1;
	}

	private void function _checkForBadHomepageOperations( required string id ) {
		var homepage = getSiteHomepage( [ "id" ], false );

		if ( arguments.id != homepage.id ) {
			return;
		}

		if ( Len( Trim( arguments.parent_page ?: "" ) ) ) {
			throw(
				  type    = "SiteTreeService.BadHomepageOperation"
				, message = "The homepage must not have a parent page"
			);
		}

		if ( IsBoolean( arguments.trashed ?: "" ) && arguments.trashed ) {
			throw(
				  type    = "SiteTreeService.BadHomepageOperation"
				, message = "You cannot send the homepage to the recycle bin!"
			);
		}

		if ( IsBoolean( arguments.active ?: "" ) && !arguments.active ) {
			throw(
				  type    = "SiteTreeService.BadHomepageOperation"
				, message = "You cannot deactivate the homepage!"
			);
		}
	}

	private string function _getSourceObjectForPageProperty( required string propertyName, required string pageType ) {
		var poService    = _getPresideObjectService();
		var ptService    = _getPageTypesService();
		var sourceObject = "page";
		var pt           = "";

		if ( poService.fieldExists( sourceObject, arguments.propertyname ) ) {
			return sourceObject;
		}

		if ( ptService.pageTypeExists( arguments.pageType ) ) {
			pt = ptService.getPageType( arguments.pageType );
			sourceObject = pt.getPresideObject();
			if ( poService.fieldExists( sourceObject, arguments.propertyname ) ) {
				return sourceObject;
			}
		}

		return "";
	}

	private void function _ensureSystemPagesExistInTree() {
		_getSiteService().ensureDefaultSiteExists();
		for( var site in _getSiteService().listSites() ) {
			ensureSystemPagesExistForSite( site.id );
		}
	}

	private string function _createSystemPage( required any pageType ) {
		var parentType = pageType.getParentSystemPageType();
		var loginSvc   = _getLoginService();

		if ( Len( Trim( parentType ) ) && parentType != "none" ) {
			var parent = getPage( systemPage=parentType, useCache=false );
			if ( !parent.recordCount ) {
				parent = _createSystemPage( _getPageTypesService().getPageType( parentType ) );
			} else {
				parent = parent.id;
			}
		}

		var addPageArgs = {
			  title                   = _getI18nService().translateResource( uri=pageType.getName(), defaultValue=pageType.getid() )
			, page_type               = pageType.getId()
			, slug                    = pageType.getId() == "homepage" ? "" : LCase( ReReplace( pageType.getId(), "[\W_]", "-", "all" ) )
			, active                  = 1
			, userId                  = ( loginSvc.isLoggedIn() ? loginSvc.getLoggedInUserId() : loginSvc.getSystemUserId() )
			, exclude_from_navigation = pageType.getId() != "homepage"
			, audit                   = false
		};
		if ( Len( Trim( parent ?: "" ) ) ) {
			addPageArgs.parent_page = parent;
		}

		return addPage( argumentCollection=addPageArgs );
	}

	private string function _paddedSortOrder( required numeric sortOrder ) {
		return NumberFormat( arguments.sortOrder, '000000' );
	}

	public array function listGridFields( required string objectName ) {
		var fields = _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "sitetreeGridFields"
			, defaultValue  = "page.title,page.datemodified"
		);

		return ListToArray( fields );
	}

	public string function getDefaultSortOrderForDataGrid( required string objectName ) {
		return _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "sitetreeDefaultSortOrder"
			, defaultValue  = ""
		);
	}

	private array function _prepareGridFieldsForSqlSelect( required array gridFields, required string objectName, boolean versionTable=false ) output=false {
		var sqlFields          = Duplicate( arguments.gridFields );
		var field              = "";
		var fieldObject        = "";
		var i                  = "";
		var props              = {};
		var prop               = "";
		var objName            = arguments.versionTable ? "vrsn_" & arguments.objectName : arguments.objectName;
		var labelField         = _getPresideObjectService().getObjectAttribute( objName, "labelField", "label" );
		var replacedLabelField = !Find( ".", labelField ) ? "#objName#.${labelfield} as #ListLast( labelField, '.' )#" : "${labelfield} as #ListLast( labelField, '.' )#";

		sqlFields.delete( "id" );
		sqlFields.append( "#objName#.id" );
		if ( sqlFields.find( labelField ) ) {
			sqlFields.delete( labelField );
			sqlFields.append( replacedLabelField );
		}
		sqlFields.append( "page._version_is_draft"   );
		sqlFields.append( "page._version_has_drafts" );
		sqlFields.append( "page.active"              );
		sqlFields.append( "page.embargo_date"        );
		sqlFields.append( "page.expiry_date"         );

		// ensure all fields are valid + get labels from join tables
		for( i=ArrayLen( sqlFields ); i gt 0; i-- ){
			field       = ListLen( sqlFields[i], "." ) > 1 ? ListRest( sqlFields[i], "." ) : sqlFields[i];
			fieldObject = ListLen( sqlFields[i], "." ) > 1 ? ListFirst( sqlFields[i], "." ) : arguments.objectName;

			if ( sqlFields[ i ] == "#objName#.id" || sqlFields[ i ] == replacedLabelField ) {
				continue;
			}

			props[ fieldObject ] = props[ fieldObject ] ?: _getPresideObjectService().getObjectProperties( fieldObject );

			if ( not StructKeyExists( props[ fieldObject ], field ) ) {
				if ( arguments.versiontable && field.reFindNoCase( "^_version_" ) ) {
					sqlFields[i] = objName & "." & field;
				} else {
					sqlFields[i] = "'' as " & field;
				}
				continue;
			}

			prop = props[ fieldObject ][ field ];

			switch( prop.relationship ?: "none" ) {
				case "one-to-many":
				case "many-to-many":
					sqlFields[i] = "'' as " & field;
				break;

				case "many-to-one":
					sqlFields[i] = sqlFields[i] & ".${labelfield} as " & field;
				break;

				default:
					sqlFields[i] = fieldObject & "." & field;
			}

			if ( arguments.versionTable ) {
				sqlFields.append( objName & "._version_number" );
			}
		}

		return sqlFields;
	}

	private string function _getPageIdWithMultilingualSlug( required string slug ) {
		var slugPieces      = slug.listToArray( "/" );
		var pageObject      = _getPobj();
		var page            = getSiteHomepage( selectFields=[ "page.id" ] );
		var args            = { filter={}, selectFields=[ "page.id" ] };
		var currentLanguage = $getColdbox().getRequestContext().getLanguage();

		for( var i=1; i<=slugPieces.len(); i++ ) {
			args.filter       = "( IfNull( _translations.slug, page.slug ) = :page.slug and ( _translations.slug is null or _translations._translation_language = :_translations._translation_language ) ) and page.parent_page = :page.parent_page"
			args.filterParams = {
				  "page.slug"                           = slugPieces[ i ]
				, "_translations._translation_language" = currentLanguage
				, "page.parent_page"                    = page.id
			};

			page = pageObject.selectData( argumentCollection=args );

			if ( !page.recordCount ) {
				break;
			}
		}

		return page.id ?: "";
	}

	private void function _checkPageHistoryForSlug( required string slug ) {
		var versionObjectName = _getPresideObjectService().getVersionObjectName( "page" );
		var pageFromHistory   = _getPresideObjectService().selectData(
			  objectName   = versionObjectName
			, selectFields = [ "#versionObjectName#.id" ]
			, filter       = "#versionObjectName#.slug = :slug and #versionObjectName#._hierarchy_slug = :_hierarchy_slug"
			, filterParams = { slug = ListLast( arguments.slug, "/" ), _hierarchy_slug = arguments.slug }
			, orderBy      = "#versionObjectName#._version_number desc"
			, maxRows      = 1
		);

		if ( pageFromHistory.recordcount ) {
			var currentPage = _getPObj().selectData(
				  filter       = { id=pageFromHistory.id, trashed=false }
				, selectFields = [ "id" ]
			);
			if ( currentPage.recordCount ) {
				var redirectUrl = $getRequestContext().buildLink( page=pageFromHistory.id );
				location addtoken=false url=redirectUrl statusCode=301;
			}
		}
	}

	private boolean function _isAutoRedirectEnabled() {
		var site = $getRequestContext().getSite();
		return isBoolean( site.auto_redirect ) && site.auto_redirect;
	}

	private struct function _calculateSortOrderAndHierarchyFields( required string slug, string parent_page="", string site="" ) {
		var data = {
			  _hierarchy_child_selector = ""
			, _hierarchy_lineage        = "/"
			, _hierarchy_depth          = 0
			, _hierarchy_slug           = Len( Trim( arguments.slug ) ) ? "/#arguments.slug#/" : "/"
		};
		var bypassTenants = Len( Trim( arguments.site ) ) ? [ "site" ] : [];

		data.sort_order            = _calculateSortOrder( argumentCollection = arguments );
		data._hierarchy_id         = _getNextAvailableHierarchyId( site=arguments.site );
		data._hierarchy_sort_order = "/#_paddedSortOrder( data.sort_order )#/";

		if ( Len( Trim( arguments.parent_page ) ) ) {
			var parent = getPage( id = arguments.parent_page, selectFields=[ "_hierarchy_id", "_hierarchy_lineage", "_hierarchy_depth", "_hierarchy_slug", "_hierarchy_sort_order" ], includeTrash = true, useCache=false, bypassTenants=bypassTenants );
			if ( !parent.recordCount ) {
				throw(
					  type    = "SiteTreeService.MissingParent"
					, message = "Error when adding site tree page. Parent page with id, [#arguments.parent_page#], was not found."
				);
			}
			data.parent_page           = arguments.parent_page;
			data._hierarchy_lineage    = parent._hierarchy_lineage    & parent._hierarchy_id                & "/";
			data._hierarchy_slug       = parent._hierarchy_slug       & arguments.slug                      & "/";
			data._hierarchy_sort_order = parent._hierarchy_sort_order & _paddedSortOrder( data.sort_order ) & "/";
			data._hierarchy_depth      = parent._hierarchy_depth + 1;
		}
		data._hierarchy_child_selector = "#data._hierarchy_lineage##data._hierarchy_id#/%";

		return data;
	}

// GETTERS AND SETTERS
	private any function _getLoginService() {
		return _loginService;
	}
	private void function _setLoginService( required any loginService ) {
		_loginService = arguments.loginService;
	}

	private any function _getPageTypesService() {
		return _pageTypesService;
	}
	private void function _setPageTypesService( required any pageTypesService ) {
		_pageTypesService = arguments.pageTypesService;
	}

	private any function _getSiteService() {
		return _siteService;
	}
	private void function _setSiteService( required any siteService ) {
		_siteService = arguments.siteService;
	}

	private any function _getColdboxController() {
		return _coldboxController;
	}
	private void function _setColdboxController( required any coldboxController ) {
		_coldboxController = arguments.coldboxController;
	}

	private any function _getI18nService() {
		return _i18nService;
	}
	private void function _setI18nService( required any i18nService ) {
		_i18nService = arguments.i18nService;
	}

	private any function _getPresideObject() {
		return _getPresideObjectService().getObject( argumentCollection=arguments );
	}

	private any function _getPobj() {
		return _getPresideObject( "page" );
	}

	private any function _getPresideObjectService() {
		return _PresideObjectService;
	}
	private void function _setPresideObjectService( required any PresideObjectService ) {
		_PresideObjectService = arguments.PresideObjectService;
	}

	private any function _getVersioningService() {
		return _versioningService;
	}
	private void function _setVersioningService( required any versioningService ) {
		_versioningService = arguments.versioningService;
	}

	private any function _getWebsitePermissionService() {
		return _websitePermissionService;
	}
	private void function _setWebsitePermissionService( required any websitePermissionService ) {
		_websitePermissionService = arguments.websitePermissionService;
	}

	private any function _getRulesEngineConditionService() {
		return _rulesEngineConditionService;
	}
	private void function _setRulesEngineConditionService( required any rulesEngineConditionService ) {
		_rulesEngineConditionService = arguments.rulesEngineConditionService;
	}

	private any function _getCloningService() {
		return _cloningService;
	}
	private void function _setCloningService( required any cloningService ) {
		_cloningService = arguments.cloningService;
	}

	private void function _setPageSlugsAreMultilingual() {
		var featureEnabled    = $isFeatureEnabled( "multilingual" );
		var slugMultilingual = $getPresideObjectService().getObjectPropertyAttribute(
			  objectName    = "page"
			, propertyName  = "slug"
			, attributeName = "multilingual"
			, defaultValue  = false
		);

		_pageSlugsAreMultilingual = featureEnabled && IsBoolean( slugMultilingual ) && slugMultilingual;
	}
}
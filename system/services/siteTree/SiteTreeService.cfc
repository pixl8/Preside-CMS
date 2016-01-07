component singleton=true {

// CONSTRUCTOR
	/**
	 * @loginService.inject             loginService
	 * @pageTypesService.inject         pageTypesService
	 * @siteService.inject              siteService
	 * @i18nService.inject              coldbox:plugin:i18n
	 * @coldboxController.inject        coldbox
	 * @presideObjectService.inject     presideObjectService
	 * @versioningService.inject        versioningService
	 * @websitePermissionService.inject websitePermissionService
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
	) {
		_setLoginService( arguments.loginService );
		_setPageTypesService( arguments.pageTypesService );
		_setSiteService( arguments.siteService );
		_setPresideObjectService( arguments.presideObjectService );
		_setColdboxController( arguments.coldboxController );
		_setI18nService( arguments.i18nService );
		_setVersioningService( arguments.versioningService );
		_setWebsitePermissionService( arguments.websitePermissionService );

		_ensureSystemPagesExistInTree();

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

	) {
		var tree             = "";
		var rootPage         = "";
		var allowedPageTypes = _getPageTypesService().listSiteTreePageTypes();

		var filter           = "page.trashed = :trashed";
		if( !arguments.trash ){
			filter &= " and page.page_type in (:page_type)"
		}

		var maxDepth         = arguments.maxDepth;
		var args = {
			  orderBy      = "page._hierarchy_sort_order"
			, filter       = filter
			, filterParams = { trashed = arguments.trash, page_type = allowedPageTypes }
			, useCache     = arguments.useCache
			, groupBy      = "page.id"
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

	) {
		var args = { filter="", filterParams={}, useCache=arguments.useCache };

		if ( StructKeyExists( arguments, "id" ) ) {
			args.filter          = "page.id = :id";
			args.filterParams.id = arguments.id;

		} else if ( StructKeyExists( arguments, "slug" ) ) {
			args.filter                       = "page.slug = :slug and page._hierarchy_slug = :_hierarchy_slug"; // this double match is for performance - the full slug cannot be indexed because of its potential size
			args.filterParams.slug            = ListLast( arguments.slug, "/" );
			args.filterParams._hierarchy_slug = arguments.slug;

		} else if ( StructKeyExists( arguments, "systemPage" ) ) {
			args.filter                 = "page.page_type = :page_type";
			args.filterParams.page_type = arguments.systemPage;

		} else {
			throw(
				  type    = "SiteTreeService.GetPage.MissingArgument"
				, message = "Neither [id], [system_key] nor [slug] was passed to the getPage() method. You must specify one of either argument"
			);
		}

		if ( not arguments.includeTrash ) {
			args.filter &= " and page.trashed = 0";
		}

		if ( ArrayLen( arguments.selectFields ) ) {
			args.selectFields = arguments.selectFields;
		}

		if ( arguments.version ) {
			args.fromVersionTable = true
			args.specificVersion  = arguments.version
		}

		return _getPObj().selectData( argumentCollection = args );
	}

	public query function getPagesForAjaxSelect(
		  numeric maxRows     = 1000
		, string  searchQuery = ""
		, array   ids         = []
	) {
		var filter = "( page.trashed = 0 )";
		var params = {};

		if ( arguments.ids.len() ) {
			filter &= " and ( page.id in (:id) )";
			params.id = { value=ArrayToList( arguments.ids ), list=true };
		}
		if ( Len( Trim( arguments.searchQuery ) ) ) {
			filter &= " and ( page.title like (:title) )";
			params.title = "%#arguments.searchQuery#%";
		}

		return _getPobj().selectData(
			  selectFields = [ "page.id as value", "page.title as text", "parent_page.title as parent", "page._hierarchy_depth as depth", "page.page_type" ]
			, filter       = filter
			, filterParams = params
			, maxRows      = arguments.maxRows
			, orderBy      = "page._hierarchy_sort_order"
		);
	}

	public struct function getExtendedPageProperties( required string id, required string pageType ) {
		var ptSvc = _getPageTypesService();

		if ( !ptSvc.pageTypeExists( arguments.pageType ) ) {
			return {};
		}

		var pt = ptSvc.getPageType( arguments.pageType );
		var pobj   = _getPresideObject( pt.getPresideObject() );
		var record = pobj.selectData( filter={ page = arguments.id } );

		if ( !record.recordCount ) {
			return {};
		}

		for( var r in record ) { record = r }; // query to struct hack
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
		var __valueExists  = function( v ) { return !IsNull( v ) && (!IsSimpleValue( v ) || Len( Trim( v ) ) ); };

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

	public query function getDescendants( required string id, numeric depth=0, array selectFields=[] ) {
		var page = getPage( id = arguments.id, selectField = [ "_hierarchy_child_selector", "_hierarchy_depth" ] );
		var args = "";

		if ( page.recordCount ) {
			args = {
				  filter       = "_hierarchy_lineage like :_hierarchy_lineage"
				, filterParams = { _hierarchy_lineage = page._hierarchy_child_selector }
				, orderBy      = "_hierarchy_sort_order"
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
		  required string  pageType
		,          array   selectFields = []
		,          numeric startRow     = 1
		,          numeric maxRows      = 10
		,          string  orderBy      = "title"
		,          string  searchQuery  = ""
	) {
		var result = {};
		var args = {
			  objectName   = "page"
			, filter       = "parent_page = :parent_page and page_type = :page_type and trashed = :trashed"
			, filterParams = { parent_page=arguments.parentId, page_type=arguments.pageType, trashed=false }
			, selectFields = arguments.selectFields
			, maxRows      = arguments.maxRows
			, startRow     = arguments.startRow
			, orderBy      = arguments.orderBy
		};

		args.selectFields.prepend( "id" );

		if ( Len( Trim( arguments.searchQuery ) ) ) {
			args.filter &= " and title like :title";
			args.filterParams.title = "%" & arguments.searchQuery & "%";
		}

		result.records = _getPresideObjectService().selectData( argumentCollection = args );

		if ( arguments.startRow eq 1 and result.records.recordCount lt arguments.maxRows ) {
			result.totalRecords = result.records.recordCount;
		} else {
			args.maxRows = 0;
			args.startRow = 1;
			args.selectFields = [ "count( * ) as nRows" ]
			result.totalRecords = _getPresideObjectService().selectData( argumentCollection=args ).nRows;
		}

		return result;
	}

	public query function getAncestors( required string id, numeric depth=0, array selectFields=[], boolean includeSiblings=false ) {
		var page = getPage( id = arguments.id, selectField = [ "_hierarchy_depth", "_hierarchy_lineage" ] );
		var args = "";

		if ( page.recordCount and page._hierarchy_lineage neq "/" ) {
			args = {
				  filter       = "( _hierarchy_id in (:_hierarchy_id)"
				, filterParams = { _hierarchy_id = { value=page._hierarchy_lineage, list=true, separator="/" } }
				, orderBy      = "_hierarchy_sort_order"
			};

			if ( arguments.includeSiblings ) {
				// would be nice not to have to make this additional call here, necessary due to using _hierarchy_id instead of id to form lineage
				var ancestors = getAncestors( id=arguments.id, selectFields=[ "id" ] );
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

			return _getPObj().selectData( argumentCollection = args );
		}

		return QueryNew('');
	}

	public query function getSiteHomepage( array selectFields=[], boolean createIfNotExists=true ) {
		var loginSvc       = _getLoginService();
		var homepage       = _getPobj().selectData(
			  maxRows      = 1
			, orderBy      = "_hierarchy_sort_order"
			, selectFields = arguments.selectFields
			, filter       = {
				  _hierarchy_depth = 0
				, active           = true
				, trashed          = false
			  }
		);

		if ( homepage.recordCount or not arguments.createIfNotExists ) {
			return homepage;
		}

		homepage = addPage(
			  title         = "Home"
			, slug          = ""
			, page_type     = "homepage"
			, active        = 1
			, userId        = ( loginSvc.isLoggedIn() ? loginSvc.getLoggedInUserId() : loginSvc.getSystemUserId() )
		);

		return getPage( id=homepage, selectFields=arguments.selectFields );
	}

	public array function getPagesForNavigationMenu(
		  string  rootPage          = getSiteHomepage().id
		, numeric depth             = 1
		, boolean includeInactive   = false
		, array   activeTree        = []
		, boolean expandAllSiblings = true
		, array   selectFields      = [ "page.id", "page.title", "page.navigation_title", "page.exclude_children_from_navigation", "page.page_type" ]
		, boolean isSubMenu         = false
	) {
		var args = arguments;
		var requiredSelectFields = [ "id", "title", "navigation_title", "exclude_children_from_navigation", "page_type", "exclude_from_navigation_when_restricted", "access_restriction" ]
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
				  selectFields = args.selectFields
				, filter       = filter
				, filterParams = filterParams
				, extraFilters = extraFilters
				, orderBy      = "sort_order"
			);

			for( var child in children ){
				var excluded = IsBoolean( child.exclude_from_navigation_when_restricted ) && child.exclude_from_navigation_when_restricted && !userHasPageAccess( child.id );

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
					  id       = child.id
					, title    = Len( Trim( child.navigation_title ?: "" ) ) ? child.navigation_title : child.title
					, children = child.children ?: []
					, active   = ( activeTree.find( child.id ) > 0 )
				};

				for( var field in child ) {
					if ( !requiredSelectFields.find( field ) ) {
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
		var excludedFromNav = arguments.isSubMenu ? Val( page.exclude_from_sub_navigation ) : ( Val( page.exclude_from_navigation ) || Val( page.exclude_children_from_navigation ) )
		if ( isManagedType || excludedFromNav ) {
			return [];
		}

		var maxDepth = Val( page._hierarchy_depth ) + ( arguments.depth < 1 ? 1 : arguments.depth );
		var disallowedPageTypes = getManagedChildTypesForParentType( page.page_type );

		var exclusionField = ( arguments.isSubMenu ? "exclude_from_sub_navigation" : "exclude_from_navigation" );
		var filter = "parent_page = :parent_page and trashed = 0 and ( #exclusionField# is null or #exclusionField# = 0 )";
		var filterParams = {};
		if ( !arguments.includeInactive ) {
			filter &= " and active = 1";
		}

		return getNavChildren( rootPage, Val( page._hierarchy_depth )+1, disallowedPageTypes );
	}

	public string function addPage(
		  required string title
		, required string slug
		, required string page_type
		,          string parent_page
		,          string userId      = _getLoginService().getLoggedInUserId()

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
			  created_by                = arguments.userId
			, updated_by                = arguments.userId
			, _hierarchy_child_selector = ""
			, _hierarchy_lineage        = "/"
			, _hierarchy_depth          = 0
			, _hierarchy_slug           = Len( Trim( arguments.slug ) ) ? "/#arguments.slug#/" : "/"
		} );

		transaction {
			data.sort_order            = _calculateSortOrder( argumentCollection = arguments );
			data._hierarchy_id         = _getNextAvailableHierarchyId();
			data._hierarchy_sort_order = "/#_paddedSortOrder( data.sort_order )#/";

			if ( StructKeyExists( arguments, "parent_page" ) ) {
				parent = getPage( id = arguments.parent_page, selectFields=[ "_hierarchy_id", "_hierarchy_lineage", "_hierarchy_depth", "_hierarchy_slug", "_hierarchy_sort_order" ], includeTrash = true, useCache=false );
				if ( not parent.recordCount ) {
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

			versionNumber = _getPresideObjectService().getNextVersionNumber();
			pageId = pobj.insertData( data=data, versionNumber=versionNumber, insertManyToManyRecords=true );
			if ( not Len( pageId ) and StructKeyExists( arguments, "id" ) ) {
				pageId = arguments.id;
			}


			pageTypeObjData = Duplicate( arguments );
			pageTypeObjData.page = pageTypeObjData.id = pageId;
			_getPresideObject( pageType.getPresideObject() ).insertData( data=pageTypeObjData, versionNumber=versionNumber, insertManyToManyRecords=true );
		}

		return pageId;
	}

	public boolean function editPage( required string id ) {
		var data             = _getValidAddAndEditPageFieldsFromArguments( argumentCollection = arguments );
		var pobj             = _getPObj();
		var existingPage     = "";
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
			existingPage = getPage( id = arguments.id, includeTrash = true, useCache = false );
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

					} elseif ( IsBoolean( arguments.trashed ?: "" ) && arguments.trashed ) {
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

				} else {
					if ( sortOrderChanged ) {
						data._hierarchy_sort_order = ReReplace( existingPage._hierarchy_sort_order, "/#ListLast( existingPage._hierarchy_sort_order, '/' )#/$", "/#_paddedSortOrder( data.sort_order )#/" );
					}
					if ( slugChanged ) {
						data._hierarchy_slug = ReReplace( existingPage._hierarchy_slug, "/#existingPage.slug#/$", "/#data.slug#/" );
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
				, versionNumber           = versionNumber
				, updateManyToManyRecords = true
				, forceVersionCreation    = pageDataHasChanged || pageTypeDataHasChanged
			);

			if ( _getPageTypesService().pageTypeExists( existingPage.page_type ) ) {
				if ( pageTypeObj.dataExists( filter={ page=arguments.id } ) ) {
					_getPresideObject( pageType.getPresideObject() ).updateData(
						  data                    = arguments
						, filter                  = { page=arguments.id }
						, versionNumber           = versionNumber
						, updateManyToManyRecords = true
						, forceVersionCreation    = pageDataHasChanged || pageTypeDataHasChanged
					);
				} else {
					var insertData = Duplicate( arguments );
					insertData.page = arguments.id;
					_getPresideObject( pageType.getPresideObject() ).insertData(
						  data                    = insertData
						, versionNumber           = versionNumber
						, insertManyToManyRecords = true
					);
				}
			}

			if ( sortOrderChanged or parentChanged or slugChanged ) {
				pobj.updateChildHierarchyHelpers(
					  oldData = existingPage
					, newData = data
				);
			}
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
				);
			}
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
				);
			}
		}

		return updated;
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

		return nDeleted;
	}

	public boolean function emptyTrash() {
		return _getPObj().deleteData( filter = { trashed = true } );
	}

	public struct function getActivePageFilter( string pageTableAlais="page" ) {
		return {
			  filter       = "#pageTableAlais#.trashed != 1 and #pageTableAlais#.active = 1 and ( #pageTableAlais#.embargo_date is null or now() > #pageTableAlais#.embargo_date ) and ( #pageTableAlais#.expiry_date is null or now() < #pageTableAlais#.expiry_date )"
			, filterParams = {}
		};
	}

	public void function ensureSystemPagesExistForSite( required string siteId ) {
		var siteService        = _getSiteService();
		var pageTypesService   = _getPageTypesService();
		var site               = siteService.getSite( arguments.siteId );
		var pageTypes          = pageTypesService.listPageTypes();
		var event              = _getColdboxController().getRequestService().getContext();
		var originalActiveSite = event.getSite();

		event.setSite( site );

		for( var pageType in pageTypes ) {
			var pageTypeId = pageType.getId();
			if ( pageTypesService.isSystemPageType( pageTypeId ) && pageTypesService.isPageTypeAvailableToSiteTemplate( pageTypeId, site.template ?: "" ) ) {
				var page = getPage( systemPage=pageTypeId );

				if ( !page.recordCount ) {
					_createSystemPage( pageType );
				}
			}
		}

		event.setSite( originalActiveSite );
	}

	public struct function getAccessRestrictionRulesForPage( required string pageId ) {
		var page = getPage( id=arguments.pageId, selectFields=[ "id", "parent_page", "access_restriction", "full_login_required", "grantaccess_to_all_logged_in_users" ] );

		if ( !page.recordCount ) {
			return {
				  access_restriction                 = "none"
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
					, full_login_required                = false
					, grantaccess_to_all_logged_in_users = false
				};
			}
		}

		return {
			  access_restriction                 = page.access_restriction
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

		return _getWebsitePermissionService().hasPermission(
			  permissionKey = "pages.access"
			, context       = "page"
			, contextKeys   = [ restrictionRules.access_defining_page ]
			, forceGrantByDefault = IsBoolean( restrictionRules.grantaccess_to_all_logged_in_users ) && restrictionRules.grantaccess_to_all_logged_in_users
		);
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

// PRIVATE HELPERS
	private numeric function _calculateSortOrder( string parent_page ) {
		var result       = "";
		var filter       = "";
		var filterParams = {};

		if ( not StructKeyExists( arguments, "parent_page" ) or not Len( Trim( arguments.parent_page ) ) ) {
			filter       = "parent_page is null";
		} else {
			filter = { parent_page = arguments.parent_page };
		}

		result = _getPObj().selectData(
			  selectFields = [ "Max( sort_order ) as sort_order" ]
			, filter       = filter
			, filterParams = filterParams
			, useCache     = false
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

	private numeric function _getNextAvailableHierarchyId() {
		var qry = _getPObj().selectData( selectFields=[ "Max( _hierarchy_id ) as max_id" ] );

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
			var parent = getPage( systemPage=parentType );
			if ( !parent.recordCount ) {
				_createSystemPage( _getPageTypesService().getPageType( parentType ) );
			}
			parent = getPage( systemPage=parentType );

			parent = parent.id ?: "";
		}

		var addPageArgs = {
			  title                   = _getI18nService().translateResource( uri=pageType.getName(), defaultValue=pageType.getid() )
			, page_type               = pageType.getId()
			, slug                    = pageType.getId() == "homepage" ? "" : LCase( ReReplace( pageType.getId(), "[\W_]", "-", "all" ) )
			, active                  = 1
			, userId                  = ( loginSvc.isLoggedIn() ? loginSvc.getLoggedInUserId() : loginSvc.getSystemUserId() )
			, exclude_from_navigation = pageType.getId() != "homepage"
		};
		if ( Len( Trim( parent ?: "" ) ) ) {
			addPageArgs.parent_page = parent;
		}

		return addPage( argumentCollection=addPageArgs );
	}

	private string function _paddedSortOrder( required numeric sortOrder ) {
		return NumberFormat( arguments.sortOrder, '000000' );
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
}
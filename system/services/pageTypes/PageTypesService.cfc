component singleton=true {

// CONSTRUCTOR
	/**
	 * @autoDiscoverDirectories.inject presidecms:directories
	 * @presideObjectService.inject    presideObjectService
	 * @siteService.inject             siteService
	 */
	public any function init( required array autoDiscoverDirectories, required any presideObjectService, required any siteService ) {
		_setAutoDiscoverDirectories( arguments.autoDiscoverDirectories );
		_setPresideObjectService( arguments.presideObjectService );
		_setSiteService( arguments.siteService );

		reload();

		return this;
	}

// PUBLIC API
	public array function listPageTypes(
		  string  allowedBeneathParent   = ""
		, boolean includeSystemPageTypes = true
		, string  allowedAboveChild      = ""
	) {
		var pageTypes          = _getRegisteredPageTypes();
		var result             = [];
		var activeSiteTemplate = _getSiteService().getActiveSiteTemplate();

		for( var id in pageTypes ){
			var allowedBeneathParent = !Len( Trim( arguments.allowedBeneathParent ) ) || typeIsAllowedBeneathParentType( id, arguments.allowedBeneathParent );
			var allowedBeneathChild  = !Len( Trim( arguments.allowedAboveChild    ) ) || typeIsAllowedBeneathParentType( arguments.allowedAboveChild, id );
			var allowedInSiteTemplate = isPageTypeAvailableToSiteTemplate( id, activeSiteTemplate );

			if ( allowedBeneathParent && allowedBeneathChild && allowedInSiteTemplate && ( arguments.includeSystemPageTypes || !isSystemPageType( id ) ) ) {
				result.append( pageTypes[ id ] );
			}
		}

		return result;
	}

	public array function listSiteTreePageTypes() {
		var pageTypes = _getRegisteredPageTypes();
		var result    = [];

		for( var id in pageTypes ) {
			if ( pageTypes[id].showInSiteTree() ) {
				result.append( id );
			}
		}

		return result;
	}

	public boolean function pageTypeExists( required string id ) {
		return StructKeyExists( _getRegisteredPageTypes(), arguments.id );
	}

	public any function getPageType( required string id ) {
		var pageTypes = _getRegisteredPageTypes();

		if ( StructKeyExists( pageTypes, arguments.id ) ) {
			return pageTypes[ arguments.id ];
		}

		throw( type="PageTypesService.missingPageType", message="The template, [#arguments.id#], was not registered with the Preside page types system" );
	}

	public array function listLayouts( required string pageTypeId ) {
		return [ "default" ];
	}

	public void function reload() {
		_setRegisteredPageTypes({});
		_autoDiscoverPageTypes();
	}

	public boolean function typeIsAllowedBeneathParentType( required string child, required string parent ) {
		var allowedParentTypes = getPageType( arguments.child ).getAllowedParentTypes();
		var allowedChildTypes  = ListAppend( getPageType( arguments.parent ).getAllowedChildTypes(), getPageType( arguments.parent ).getManagedChildTypes() );


		if ( allowedChildTypes == "none" || allowedParentTypes == "none" ) {
			return false;
		}

		if ( allowedParentTypes != "*" && !ListFindNoCase( allowedParentTypes, arguments.parent ) ) {
			return false;
		}

		if ( allowedChildTypes != "*" && !ListFindNoCase( allowedChildTypes, arguments.child ) ) {
			return false;
		}


		return true;
	}

	public boolean function isSystemPageType( required string pageTypeId ) {
		return getPageType( arguments.pageTypeId ).isSystemPageType();
	}

	public boolean function isPageTypeAvailableToSiteTemplate( required string pageTypeId, string siteTemplate=_getSiteService().getActiveSiteTemplate() ) {
		var pageType = getPageType( arguments.pageTypeId );
		var siteTemplates = pageType.getSiteTemplates();

		if ( arguments.siteTemplate == "" ) {
			arguments.siteTemplate = "default";
		}

		return siteTemplates == "*" || ListFindNoCase( siteTemplates, arguments.siteTemplate );
	}

// PRIVATE HELPERS
	private void function _autoDiscoverPageTypes() {
		var objectsPath             = "/preside-objects/page-types";
		var ids                     = {};
		var autoDiscoverDirectories = _getAutoDiscoverDirectories();

		for( var objectName in _getPresideObjectService().listObjects() ) {
			if ( _getPresideObjectService().getObjectAttribute( objectName, "isPageType", false ) ) {
				var viewlet       = _getPresideObjectService().getObjectAttribute( objectName, "pageTypeViewlet", "" );
				var isSystemType  = _getPresideObjectService().getObjectAttribute( objectName, "isSystemPageType", false );
				var handlerExists = Len( Trim( viewlet ) );
				var layouts       = {};

				for( var dir in autoDiscoverDirectories ) {
					dir = ReReplace( dir, "/$", "" );

					if ( !handlerExists) {
						handlerExists = _fileExistsNoCase( dir & "/handlers/page-types/#objectName#.cfc" );
					}

					if ( !isSystemType ) {
						var viewDir = dir & "/views/page-types/#objectName#/";
						var layoutFiles = DirectoryList( viewDir, false, "name", "*.cfm" );

						for( var file in layoutFiles ) {
							if ( !file.reFind( "^_" ) ) {
								layouts[ ReReplaceNoCase( file, "\.cfm$", "" ) ] = true;
							}
						}
					}
				}

				_registerPageType(
					  id         = objectName
					, hasHandler = handlerExists
					, layouts    = layouts.keyList()
				);
			}
		}

		for( var id in ids ) {
			var handlerExists = false;
			var layouts       = {};

			for( var dir in autoDiscoverDirectories ) {
				dir = ReReplace( dir, "/$", "" );

				if ( !handlerExists) {
					handlerExists = _fileExistsNoCase( dir & "/handlers/page-types/#id#.cfc" );
				}

				var viewDir = dir & "/views/page-types/#id#/";
				var layoutFiles = DirectoryList( viewDir, false, "name", "*.cfm" );

				for( var file in layoutFiles ) {
					if ( !file.reFind( "^_" ) ) {
						layouts[ ReReplaceNoCase( file, "\.cfm$", "" ) ] = true;
					}
				}
			}

			_registerPageType(
				  id         = id
				, hasHandler = handlerExists
				, layouts    = layouts.keyList()
			);
		}

		_calculateManagedPageTypes();
	}

	private void function _registerPageType( required string id, required boolean hasHandler, required string layouts ) {
		var pageTypes = _getRegisteredPageTypes();
		var poService = _getPresideObjectService();

		pageTypes[ arguments.id ] = new PageType(
			  id                   = arguments.id
			, name                 = _getConventionsBasePageTypeName( arguments.id )
			, description          = _getConventionsBasePageTypeDescription( arguments.id )
			, addForm              = _getConventionsBasePageTypeAddForm( arguments.id )
			, defaultForm          = _getConventionsBasePageTypeDefaultForm( arguments.id )
			, editForm             = _getConventionsBasePageTypeEditForm( arguments.id )
			, cloneForm            = _getConventionsBasePageTypeCloneForm( arguments.id )
			, presideObject        = _getConventionsBasePageTypePresideObject( arguments.id )
			, hasHandler           = arguments.hasHandler
			, layouts              = arguments.layouts
			, viewlet              = poService.getObjectAttribute( arguments.id, "pageTypeViewlet", _getConventionsBasePageTypeViewlet( arguments.id ) )
			, allowedChildTypes    = poService.getObjectAttribute( objectName=arguments.id, attributeName="allowedChildPageTypes" , defaultValue="*"   )
			, allowedParentTypes   = poService.getObjectAttribute( objectName=arguments.id, attributeName="allowedParentPageTypes", defaultValue="*"   )
			, showInSiteTree       = poService.getObjectAttribute( objectName=arguments.id, attributeName="showInSiteTree"        , defaultValue=true  )
			, siteTemplates        = poService.getObjectAttribute( objectName=arguments.id, attributeName="siteTemplates"         , defaultValue="*"   )
			, isSystemPageType     = poService.getObjectAttribute( objectName=arguments.id, attributeName="isSystemPageType"      , defaultValue=false )
			, parentSystemPageType = poService.getObjectAttribute( objectName=arguments.id, attributeName="parentSystemPageType"  , defaultValue="homepage" )
		);
	}

	private void function _calculateManagedPageTypes() {
		var pageTypes         = _getRegisteredPageTypes();
		var siteTreePageTypes = listSiteTreePageTypes();

		for( var pageTypeId in pageTypes ){
			var pageType = pageTypes[ pageTypeId ];

			if ( !pageType.showInSiteTree() ) {
				if ( Len( Trim( pageType.getAllowedParentTypes() ) ) && pageType.getAllowedParentTypes() != "*" ) {
					for( var parentTypeId in ListToArray( pageType.getAllowedParentTypes() ) ) {
						var parentType = getPageType( parentTypeId );
						var parentManaged = parentType.getManagedChildTypes();
						var parentAllowed = parentType.getAllowedChildTypes();

						parentType.setManagedChildTypes( ListAppend( parentManaged, pageType.getId() ) );
						if ( parentAllowed != "*" ) {
							parentAllowed = ListToArray( parentAllowed );
							parentAllowed.delete( pageType.getId() );
							parentType.setAllowedChildTypes( parentAllowed.len() ? parentAllowed.toList() : "none" );
						}
					}
				}
			}
			if ( pageType.getAllowedChildTypes() == "*" ) {
				pageType.setAllowedChildTypes( siteTreePageTypes.toList() );
			}
		}
	}

	private boolean function _fileExistsNoCase( required string path ) {
		var directory = GetDirectoryFromPath( arguments.path );
		var fileName  = ListLast( arguments.path, "\/" );
		var ext       = ListLast( fileName, "." );
		var filesInDir = DirectoryList( directory, false, "name", "*.#ext#" );

		return filesInDir.findNoCase( fileName );

	}

	private string function _getConventionsBasePageTypeName( required string id ) {
		return "page-types.#arguments.id#:name";
	}
	private string function _getConventionsBasePageTypeDescription( required string id ) {
		return "page-types.#arguments.id#:description";
	}
	private string function _getConventionsBasePageTypeViewlet( required string id ) {
		return "page-types.#arguments.id#.index";
	}
	private string function _getConventionsBasePageTypeDefaultForm( required string id ) {
		return "page-types.#arguments.id#";
	}
	private string function _getConventionsBasePageTypeAddForm( required string id ) {
		return "page-types.#arguments.id#.add";
	}
	private string function _getConventionsBasePageTypeEditForm( required string id ) {
		return "page-types.#arguments.id#.edit";
	}
	private string function _getConventionsBasePageTypeCloneForm( required string id ) output=false {
		return "page-types.#arguments.id#.clone";
	}
	private string function _getConventionsBasePageTypePresideObject( required string id ) output=false {
		return arguments.id;
	}

// GETTERS AND SETTERS
	private array function _getAutoDiscoverDirectories() {
		return _autoDiscoverDirectories;
	}
	private void function _setAutoDiscoverDirectories( required array autoDiscoverDirectories ) {
		_autoDiscoverDirectories = arguments.autoDiscoverDirectories;
	}

	private struct function _getRegisteredPageTypes() {
		return _registeredPageTypes;
	}
	private void function _setRegisteredPageTypes( required struct registeredPageTypes ) {
		_registeredPageTypes = arguments.registeredPageTypes;
	}

	private any function _getPresideObjectService() {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) {
		_presideObjectService = arguments.presideObjectService;
	}

	private any function _getSiteService() {
		return _siteService;
	}
	private void function _setSiteService( required any siteService ) {
		_siteService = arguments.siteService;
	}
}
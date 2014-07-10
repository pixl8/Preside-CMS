component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @autoDiscoverDirectories.inject presidecms:directories
	 * @presideObjectService.inject    presideObjectService
	 */
	public any function init( required array autoDiscoverDirectories, required any presideObjectService ) output=false {
		_setAutoDiscoverDirectories( arguments.autoDiscoverDirectories );
		_setPresideObjectService( arguments.presideObjectService );

		reload();

		return this;
	}

// PUBLIC API
	public array function listPageTypes( string allowedBeneathParent="" ) output=false {
		var pageTypes = _getRegisteredPageTypes();
		var result    = [];

		for( var id in pageTypes ){
			if ( !Len( Trim( arguments.allowedBeneathParent ) ) || typeIsAllowedBeneathParentType( id, arguments.allowedBeneathParent ) ) {
				ArrayAppend( result, pageTypes[ id ] );
			}
		}

		return result;
	}

	public boolean function pageTypeExists( required string id ) output=false {
		return StructKeyExists( _getRegisteredPageTypes(), arguments.id );
	}

	public any function getPageType( required string id ) output=false {
		var pageTypes = _getRegisteredPageTypes();

		if ( StructKeyExists( pageTypes, arguments.id ) ) {
			return pageTypes[ arguments.id ];
		}

		throw( type="PageTypesService.missingPageType", message="The template, [#arguments.id#], was not registered with the Preside page types system" );
	}

	public array function listLayouts( required string pageTypeId ) output=false {
		return [ "default" ];
	}

	public void function reload() output=false {
		_setRegisteredPageTypes({});
		_autoDiscoverPageTypes();
	}

	public boolean function typeIsAllowedBeneathParentType( required string child, required string parent ) output=false {
		var allowedParentTypes = getPageType( arguments.child ).getAllowedParentTypes();
		var allowedChildTypes  = getPageType( arguments.parent ).getAllowedChildTypes();

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

// PRIVATE HELPERS
	private void function _autoDiscoverPageTypes() output=false {
		var objectsPath             = "/preside-objects/page-types";
		var ids                     = {};
		var autoDiscoverDirectories = _getAutoDiscoverDirectories();

		for( var dir in autoDiscoverDirectories ) {
			dir   = ReReplace( dir, "/$", "" );
			var objects = DirectoryList( dir & objectsPath, false, "query", "*.cfc" );

			for ( var obj in objects ) {
				if ( obj.type eq "File" ) {
					ids[ ReReplace( obj.name, "\.cfc$", "" ) ] = true;
				}
			}
		}

		for( var id in ids ) {
			var handlerExists = false;
			var layouts       = {};

			for( var dir in autoDiscoverDirectories ) {
				dir = ReReplace( dir, "/$", "" );

				if ( !handlerExists) {
					handlerExists = FileExists( dir & "/handlers/page-types/#id#.cfc" );
				}

				var viewDir = dir & "/views/page-types/#id#/";
				var layoutFiles = DirectoryList( viewDir, false, "name", "*.cfm" );

				for( var file in layoutFiles ) {
					if ( !file.startsWith( "_" ) ) {
						layouts[ ReReplaceNoCase( file, "\.cfm$", "" ) ] = true;
					}
				}
			}

			_registerPageType( id = LCase( id ), hasHandler = handlerExists, layouts=layouts.keyList() );
		}
	}

	private void function _registerPageType( required string id, required boolean hasHandler, required string layouts ) output=false {
		var pageTypes = _getRegisteredPageTypes();

		pageTypes[ arguments.id ] = new PageType(
			  id                 = arguments.id
			, name               = _getConventionsBasePageTypeName( arguments.id )
			, description        = _getConventionsBasePageTypeDescription( arguments.id )
			, viewlet            = _getConventionsBasePageTypeViewlet( arguments.id )
			, addForm            = _getConventionsBasePageTypeAddForm( arguments.id )
			, defaultForm        = _getConventionsBasePageTypeDefaultForm( arguments.id )
			, editForm           = _getConventionsBasePageTypeEditForm( arguments.id )
			, presideObject      = _getConventionsBasePageTypePresideObject( arguments.id )
			, hasHandler         = arguments.hasHandler
			, layouts            = arguments.layouts
			, allowedChildTypes  = _getPresideObjectService().getObjectAttribute( objectName=arguments.id, attributeName="allowedChildPageTypes" , defaultValue="*" )
			, allowedParentTypes = _getPresideObjectService().getObjectAttribute( objectName=arguments.id, attributeName="allowedParentPageTypes", defaultValue="*" )
		);
	}

	private string function _getConventionsBasePageTypeName( required string id ) output=false {
		return "page-types.#arguments.id#:name";
	}
	private string function _getConventionsBasePageTypeDescription( required string id ) output=false {
		return "page-types.#arguments.id#:description";
	}
	private string function _getConventionsBasePageTypeViewlet( required string id ) output=false {
		return "page-types.#arguments.id#";
	}
	private string function _getConventionsBasePageTypeDefaultForm( required string id ) output=false {
		return "page-types.#arguments.id#";
	}
	private string function _getConventionsBasePageTypeAddForm( required string id ) output=false {
		return "page-types.#arguments.id#.add";
	}
	private string function _getConventionsBasePageTypeEditForm( required string id ) output=false {
		return "page-types.#arguments.id#.edit";
	}
	private string function _getConventionsBasePageTypePresideObject( required string id ) output=false {
		return arguments.id;
	}

// GETTERS AND SETTERS
	private array function _getAutoDiscoverDirectories() output=false {
		return _autoDiscoverDirectories;
	}
	private void function _setAutoDiscoverDirectories( required array autoDiscoverDirectories ) output=false {
		_autoDiscoverDirectories = arguments.autoDiscoverDirectories;
	}

	private struct function _getRegisteredPageTypes() output=false {
		return _registeredPageTypes;
	}
	private void function _setRegisteredPageTypes( required struct registeredPageTypes ) output=false {
		_registeredPageTypes = arguments.registeredPageTypes;
	}

	private any function _getPresideObjectService() output=false {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) output=false {
		_presideObjectService = arguments.presideObjectService;
	}
}
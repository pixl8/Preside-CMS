/**
 * A service for aiding with the configuration and dynamic
 * rendering of admin menu items
 *
 * @presideService true
 * @singleton      true
 * @autodoc        true
 * @feature        admin
 */
component {

	variables._legacyImplCache = {};
	variables._neverIncludeCache = {};

// CONSTRUCTOR
	/**
	 * @itemSettings.inject coldbox:setting:adminMenuItems
	 *
	 */
	public any function init( required struct itemSettings ) {
		_setItemSettings( arguments.itemSettings );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Main entry point. Prepares menu items ready for rendering for the current request/user.
	 *
	 * @autodoc        true
	 * @menuItems      Array of top level menu items
	 * @legacyViewBase Base view path to be used for menu backward compatibility. e.g. for default Preside admin sidebar menu, this is /admin/layout/sidebar/{itemid}
	 */
	public array function prepareMenuItemsForRequest(
		  required array   menuItems
		,          string  legacyViewBase = "/admin/layout/sidebar/"
		,          boolean runActiveChecks = true
	) {
		var prepared = [];

		for( var itemId in menuItems ) {
			if ( itemShouldBeIncluded( itemId, arguments.legacyViewBase ) ) {
				var config = prepareItemForRequest( itemId, arguments.legacyViewBase, arguments.runActiveChecks );
				if ( StructCount( config ) ) {
					ArrayAppend( prepared, config );
				}
			}
		}

		_trimSeparators( prepared );

		return prepared;
	}

	public string function getActiveItemForRequest( required array menuItems ) {
		var settings       = _getItemSettings();
		var requestContext = $getRequestContext();
		var prc            = requestContext.getCollection( private=true );
		var dmObject       = requestContext.isDataManagerRequest() ? ( prc.objectName ?: "" ) : "";
		var flatItems      = [];
		var expandItems    = function( children ){
			for( var childId in children ) {
				var childItem = settings[ childId ] ?: {};
				if ( StructKeyExists( childItem, "subMenuItems" ) && IsArray( childItem.subMenuItems ) && ArrayLen( childItem.subMenuItems ) ) {
					expandItems( childItem.subMenuItems );
				} else {
					ArrayAppend( flatItems, childId );
				}
			}
		};

		expandItems( arguments.menuItems );

		// first check dm object patterns as these are cheapest
		if ( Len( dmObject ) ) {
			for( var itemId in flatItems ) {
				var item = settings[ itemId ] ?: {};

				if ( StructIsEmpty( item ) ) {
					continue;
				}

				var datamanagerObject = item.activeChecks.datamanagerObject ?: "";
				if ( ( IsArray( datamanagerObject ) && ArrayLen( datamanagerObject ) ) || ( IsSimpleValue( datamanagerObject ) && Len( Trim( datamanagerObject ) ) ) ) {
					if ( IsSimpleValue( datamanagerObject ) ) {
						datamanagerObject = [ Trim( datamanagerObject ) ];
					}

					for( var objectName in datamanagerObject ) {
						if ( objectName == dmObject ) {
							return itemId;
						}
					}
				}
			}
		}

		// next cheapest, request pattern check
		var currentHandler = $getRequestContext().getCurrentEvent();
		for( var itemId in flatItems ) {
			var item = settings[ itemId ] ?: {};

			if ( StructIsEmpty( item ) ) {
				continue;
			}

			var handlerPatterns = item.activeChecks.handlerPatterns ?: "";
			if ( ( IsArray( handlerPatterns ) && ArrayLen( handlerPatterns ) ) || ( IsSimpleValue( handlerPatterns ) && Len( Trim( handlerPatterns ) ) ) ) {
				if ( IsSimpleValue( handlerPatterns ) ) {
					handlerPatterns = [ Trim( handlerPatterns ) ];
				}

				for( var pattern in handlerPatterns ) {
					if ( ReFindNoCase( pattern, currentHandler ) ) {
						return itemId;
					}
				}
			}
		}

		// finally, run handlers for complex checks
		for( var itemId in flatItems ) {
			var item = settings[ itemId ] ?: {};

			if ( StructIsEmpty( item ) || StructCount( item.activeChecks ?: {} ) ) {
				continue;
			}
			var isActive = runItemHandlerAction(
				  itemId        = itemId
				, action        = "isActive"
				, args          = item
				, defaultResult = false
			);

			if ( isActive ) {
				return itemId;
			}
		}

		return "";
	}

// PUBLIC FOR EASY TESTING, BUT CONSIDERED PRIVATE
	/**
	 * Returns dynamically calculated config for an item, with support for recursion
	 * on child menu items
	 *
	 */
	public struct function prepareItemForRequest( required string itemId, required string legacyViewBase, boolean runActiveChecks=true ) {
		var config = StructCopy( getRawItemConfig( arguments.itemId, arguments.legacyViewBase ) );

		if ( itemIsSeparator( arguments.itemId ) || itemIsLegacyViewImplementation( arguments.itemId, arguments.legacyViewBase ) || StructIsEmpty( config ) ) {
			return config;
		}

		config.subMenuItems = config.subMenuItems ?: [];
		if ( IsArray( config.subMenuItems ) && ArrayLen( config.subMenuItems ) ) {
			for( var i=ArrayLen( config.subMenuItems ); i>0; i-- ) {
				if ( IsSimpleValue( config.subMenuItems[ i ] ) ) {
					if ( itemShouldBeIncluded( config.subMenuItems[ i ], arguments.legacyViewBase ) ) {
						config.subMenuItems[ i ] = prepareItemForRequest( config.subMenuItems[ i ], arguments.legacyViewBase, arguments.runActiveChecks );
						if ( StructIsEmpty( config.subMenuItems[ i ] ) ) {
							ArrayDeleteAt( config.subMenuItems, i );
						}
					} else {
						ArrayDeleteAt( config.subMenuItems, i );
					}
				}
			}
		}

		config.active = arguments.runActiveChecks && itemIsActive( itemId, config );
		config.link   = buildItemLink( itemId, config );

		config.title = config.title ?: "admin.menuitem:#arguments.itemId#.title";
		config.icon  = config.icon ?: "admin.menuitem:#arguments.itemId#.iconClass";
		config.title = $translateResource( uri=config.title, defaultValue=config.title );
		config.icon  = $translateResource( uri=config.icon, defaultValue=config.icon );

		runItemHandlerAction( arguments.itemId, "prepare", config );

		if ( IsArray( config.subMenuItems ?: "" ) ) {
			if ( ArrayLen( config.subMenuItems ) ) {
				_trimSeparators( config.subMenuItems );
			}

			if ( !Len( Trim( config.link ?: "" ) ) && !ArrayLen( config.subMenuItems ) ) {
				return {};
			}
		}

		return config;
	}

	/**
	 * Returns whether or not the given item has a "new style" config.cfc
	 * configuration entry
	 *
	 */
	public boolean function itemHasConfiguration( required string itemId ){
		return StructKeyExists( _getItemSettings(), arguments.itemId );
	}

	/**
	 * Returns whether or not the given item has an "old style" convention
	 * based view for rendering the item
	 *
	 */
	public boolean function itemIsLegacyViewImplementation( required string itemId, required string legacyViewBase ) {
		var cacheKey = legacyViewBase & "-" & arguments.itemId;
		if ( !StructKeyExists( _legacyImplCache, cacheKey ) ) {
			_legacyImplCache[ cacheKey ] =
				   !itemHasConfiguration( arguments.itemId )
				&& $getColdbox().viewExists( arguments.legacyViewBase & arguments.itemId );
		}

		return _legacyImplCache[ cacheKey ];
	}

	/**
	 * Returns whether or not the given item is a menu separator
	 *
	 */
	public boolean function itemIsSeparator( required string itemId ) {
		return Trim( arguments.itemid ) == "-";
	}

	/**
	 * Returns whether or not the given item has a "new style" convention
	 * based handler method for the given action
	 *
	 */
	public boolean function itemHasHandlerAction( required string itemId, required string action ){
		return $getColdbox().handlerExists( "admin.layout.menuitem.#arguments.itemId#.#arguments.action#" );
	}

	/**
	 * Runs the given item action, if it exists
	 *
	 */
	public any function runItemHandlerAction(
		  required string itemId
		, required string action
		,          struct args          = {}
		,          any    defaultResult = NullValue()
	){
		if ( itemHasHandlerAction( arguments.itemId, arguments.action ) ) {
			var result = $getColdbox().runEvent(
				  event          = "admin.layout.menuitem.#arguments.itemId#.#arguments.action#"
				, private        = true
				, prepostExempt  = true
				, eventArguments = { args=arguments.args }
			);

			return IsNull( local.result ) ? arguments.defaultResult : result;
		}

		return arguments.defaultResult;
	}

	/**
	 * Returns raw config of an item without any dynamic elements
	 *
	 */
	public struct function getRawItemConfig( required string itemid, required string legacyViewBase ) {
		if ( itemIsSeparator( arguments.itemId ) ) {
			return { separator=true };
		}

		if ( itemIsLegacyViewImplementation( arguments.itemId, arguments.legacyViewBase ) ) {
			return { id=arguments.itemId, view=arguments.legacyViewBase & arguments.itemId }
		}

		var itemSettings = _getItemSettings();
		var settings     = StructCopy( itemSettings[ arguments.itemId ] ?: {} );

		if ( StructCount( settings ) ) {
			settings.id = arguments.itemId;
		}

		return settings;
	}

	/**
	 * Returns decision on whether or not to include the supplied item in the
	 * menu for this request. This will be based on item configuration and
	 * the currently logged in user
	 *
	 */
	public boolean function itemShouldBeIncluded( required string itemId, required string legacyViewBase ) {
		if ( itemIsSeparator( arguments.itemId ) || itemIsLegacyViewImplementation( arguments.itemId, arguments.legacyViewBase ) ) {
			return true;
		}

		_neverIncludeCache[ arguments.itemId ] = _neverIncludeCache[ arguments.itemId ] ?: runItemHandlerAction(
			  itemId        = arguments.itemId
			, action        = "neverInclude"
			, defaultResult = false
		);
		if ( !IsBoolean( _neverIncludeCache[ arguments.itemId ] ?: "" ) || _neverIncludeCache[ arguments.itemId ] ) {
			return false;
		}

		var itemConfig = getRawItemConfig( arguments.itemId, arguments.legacyViewBase );
		if ( Len( Trim( itemConfig.feature ?: "" ) ) && !$isFeatureEnabled( itemConfig.feature ) ) {
			_neverIncludeCache[ arguments.itemId ] = true;
			return false;
		}

		if ( Len( Trim( itemConfig.permissionKey ?: "" ) ) && !$hasAdminPermission( itemConfig.permissionKey ) ) {
			return false;
		}
		var includeForUser = runItemHandlerAction(
			  itemId        = arguments.itemId
			, action        = "includeForUser"
			, defaultResult = true
		);
		if ( !IsBoolean( local.includeForUser ?: "" ) || !includeForUser ) {
			return false;
		}

		return true;
	}

	/**
	 * Returns whether or not the given item and its config
	 * should be active for the current request
	 *
	 */
	public boolean function itemIsActive( required string itemId, required struct itemConfig ) {
		if ( IsArray( arguments.itemConfig.subMenuItems ?: "" ) && ArrayLen( arguments.itemConfig.subMenuItems ) ) {
			for( var item in arguments.itemConfig.subMenuItems ) {
				if ( isBoolean( item.active ?: "" ) && item.active ) {
					return true;
				}
			}
			return false;
		}

		var handlerPatterns = arguments.itemConfig.activeChecks.handlerPatterns ?: "";
		if ( ( IsArray( handlerPatterns ) && ArrayLen( handlerPatterns ) ) || ( IsSimpleValue( handlerPatterns ) && Len( Trim( handlerPatterns ) ) ) ) {
			var currentHandler = $getRequestContext().getCurrentEvent();

			if ( IsSimpleValue( handlerPatterns ) ) {
				handlerPatterns = [ Trim( handlerPatterns ) ];
			}

			for( var pattern in handlerPatterns ) {
				if ( ReFindNoCase( pattern, currentHandler ) ) {
					return true;
				}
			}
			return false;
		}

		var datamanagerObject = arguments.itemConfig.activeChecks.datamanagerObject ?: "";
		if ( ( IsArray( datamanagerObject ) && ArrayLen( datamanagerObject ) ) || ( IsSimpleValue( datamanagerObject ) && Len( Trim( datamanagerObject ) ) ) ) {
			var requestContext = $getRequestContext();
			var prc            = requestContext.getCollection( private=true );

			if ( !requestContext.isDataManagerRequest() || !Len( Trim( prc.objectName ?: "" ) ) ) {
				return false;
			}

			if ( IsSimpleValue( datamanagerObject ) ) {
				datamanagerObject = [ Trim( datamanagerObject ) ];
			}

			for( var objectName in datamanagerObject ) {
				if ( objectName == prc.objectName ) {
					return true;
				}
			}
			return false;
		}

		var isActive = runItemHandlerAction(
			  itemId        = arguments.itemId
			, action        = "isActive"
			, args          = arguments.itemConfig
			, defaultResult = false
		)

		return IsBoolean( isActive ?: "" ) && isActive;
	}

	/**
	 * Builds link to the the menu item
	 *
	 */
	public string function buildItemLink( required string itemId, required struct itemConfig ) {
		if ( itemHasHandlerAction( arguments.itemId, "buildLink" ) ) {
			var link = runItemHandlerAction( itemId=arguments.itemId, action="buildLink", args=arguments.itemConfig, defaultResult="" );

			if ( IsSimpleValue( link ) && Len( Trim( link ) ) ) {
				return link;
			}
		}

		var buildLinkArgs = itemConfig.buildLinkArgs ?: "";
		if ( IsStruct( buildLinkArgs ) ) {
			return $getRequestContext().buildAdminLink( argumentCollection=buildLinkArgs )
		}

		return "";
	}

	private void function _trimSeparators( menuItems ) {
		var _isSeparatorItem = function( itm ) {
			return IsBoolean( itm.separator ?: "" ) && itm.separator;
		};

		for( var i=1; i<=ArrayLen( menuItems ); i++ ) {
			if ( _isSeparatorItem( menuItems[i] ) ) {
				while( ArrayLen( menuItems ) > i && _isSeparatorItem( menuItems[ i+1 ] ) ) {
					ArrayDeleteAt( menuItems, i+1 );
				}
			}

			if ( i>=ArrayLen( menuItems ) ) {
				break;
			}
		}

		while( ArrayLen( menuItems ) && _isSeparatorItem( menuItems[1] ) ) {
			ArrayDeleteAt( menuItems, 1 )
		}
		while( ArrayLen( menuItems ) && _isSeparatorItem( ArrayLast( menuItems ) ) ) {
			ArrayDeleteAt( menuItems, ArrayLen( menuItems ) );
		}
	}


// GETTERS AND SETTERS
	private struct function _getItemSettings() {
	    return variables._itemSettings;
	}
	private void function _setItemSettings( required struct itemSettings ) {
		variables._itemSettings = {};
		for( var itemId in arguments.itemSettings ) {
			variables._itemSettings[ itemId ]    = StructCopy( arguments.itemSettings[ itemId ] );
			variables._itemSettings[ itemId ].id = itemId;
		}
	}
}
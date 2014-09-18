component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @websiteUserService.inject WebsiteUserService
	 * @cacheProvider.inject      cachebox:WebsitePermissionsCache
	 * @permissionsConfig.inject  coldbox:setting:websitePermissions
	 * @benefitsDao.inject        presidecms:object:website_benefit
	 * @userDao.inject            presidecms:object:website_user
	 * @appliedPermDao.inject     presidecms:object:website_applied_permission
	 */
	public any function init(
		  required any    websiteUserService
		, required any    cacheProvider
		, required struct permissionsConfig
		, required any    benefitsDao
		, required any    userDao
		, required any    appliedPermDao
	) output=false {
		_setWebsiteUserService( arguments.websiteUserService );
		_setCacheProvider( arguments.cacheProvider )
		_setBenefitsDao( arguments.benefitsDao );
		_setUserDao( arguments.userDao );
		_setAppliedPermDao( arguments.appliedPermDao );

		_denormalizeAndSaveConfiguredPermissions( arguments.permissionsConfig );

		return this;
	}

// PUBLIC API METHODS
	public array function listPermissionKeys( string benefit="", string user="", array filter=[] ) output=false {
		if ( Len( Trim( arguments.benefit ) ) ) {
			return _getBenefitPermissions( arguments.benefit );

		} elseif ( Len( Trim( arguments.user ) ) ) {
			return _getUserPermissions( arguments.user );

		} elseif ( arguments.filter.len() ) {
			return _filterPermissions( arguments.filter );
		}

		return _getPermissions();
	}

	public boolean function hasPermission(
		  required string permissionKey
		,          string context       = ""
		,          array  contextKeys   = []
		,          string userId        = _getWebsiteUserService().getLoggedInUserId()
	) output=false {
		if ( !Len( Trim( arguments.userId ) ) ) {
			return false;
		}

		if ( Trim( arguments.context ).len() && arguments.contextKeys.len() ) {
			var contextPerm = _getContextPermission( argumentCollection=arguments );
			if ( !IsNull( contextPerm ) && IsBoolean( contextPerm ) ) {
				return contextPerm;
			}
		}

		return listPermissionKeys( user=arguments.userId ).find( arguments.permissionKey );
	}

	public array function listUserBenefits( required string userId ) output=false {
		var benefits = _getUserDao().selectManyToManyData(
			  propertyName = "benefits"
			, id           = arguments.userId
			, selectFields = [ "benefits.id" ]
			, orderby      = "benefits.priority desc"
		);

		return ListToArray( ValueList( benefits.id ) );
	}

	public array function listUserPermissions( required string userId ) output=false {
		return _getUserPermissions( arguments.userId, false );
	}

	public void function syncBenefitPermissions( required string benefitId, required array permissions ) output=false {
		var dao = _getAppliedPermDao();

		transaction {
			dao.deleteData( filter="benefit = :benefit and context is null and context_key is null", filterParams={ benefit=arguments.benefitId } );
			for( var permissionKey in arguments.permissions ){
				dao.insertData({
					  permission_key = permissionKey
					, granted        = true
					, benefit        = arguments.benefitId
				} );
			}
		}
	}

	public void function syncUserPermissions( required string userId, required array permissions ) output=false {
		var dao = _getAppliedPermDao();

		transaction {
			dao.deleteData( filter="user = :user and context is null and context_key is null", filterParams={ user=arguments.userId } );
			for( var permissionKey in arguments.permissions ){
				dao.insertData({
					  permission_key = permissionKey
					, granted        = true
					, user           = arguments.userId
				} );
			}
		}
	}

	public void function syncContextPermissions(
		  required string context
		, required string contextKey
		, required string permissionKey
		, required array  grantBenefits
		, required array  denyBenefits
		, required array  grantUsers
		, required array  denyUsers
	) output=false {
		var dao = _getAppliedPermDao();

		transaction {
			dao.deleteData( filter={ context = arguments.context, context_key=arguments.contextKey, permission_key=arguments.permissionKey } );

			for( var benefit in arguments.grantBenefits ){
				dao.insertData({
					  permission_key = arguments.permissionKey
					, context        = arguments.context
					, context_key    = arguments.contextKey
					, benefit        = benefit
					, granted        = true
				} );
			}
			for( var benefit in arguments.denyBenefits ){
				dao.insertData({
					  permission_key = arguments.permissionKey
					, context        = arguments.context
					, context_key    = arguments.contextKey
					, benefit        = benefit
					, granted        = false
				} );
			}
			for( var user in arguments.grantUsers ){
				dao.insertData({
					  permission_key = arguments.permissionKey
					, context        = arguments.context
					, context_key    = arguments.contextKey
					, user           = user
					, granted        = true
				} );
			}
			for( var user in arguments.denyUsers ){
				dao.insertData({
					  permission_key = arguments.permissionKey
					, context        = arguments.context
					, context_key    = arguments.contextKey
					, user           = user
					, granted        = false
				} );
			}
		}

		_getCacheProvider().clear( "Context perms for context: " & arguments.context );
	}

	public struct function getContextualPermissions( required string context, required string contextKey, required string permissionKey ) output=false {
		var perms = {
			  benefit = { grant=[], deny=[] }
			, user    = { grant=[], deny=[] }
		};

		var dbRecords = _getAppliedPermDao().selectData(
			  selectFields = [ "user", "benefit", "granted" ]
			, filter       = { context=arguments.context, context_key=arguments.contextKey, permission_key=arguments.permissionKey }
		);

		for( var perm in dbRecords ){
			var benefitOrUser = Len( Trim( perm.benefit ?: "" ) ) ? "benefit" : "user";
			var grantOrDeny   = perm.granted ? "grant" : "deny";

			perms[ benefitOrUser ][ grantOrDeny ].append( perm[ benefitOrUser ] );
		}

		return perms;
	}

	public void function prioritizeBenefits( required array benefitsInOrder ) output=false {
		var dao = _getBenefitsDao();

		for ( var i=1; i <= arguments.benefitsInOrder.len(); i++ ) {
			dao.updateData( id=arguments.benefitsInOrder[i], data={ priority=i } );
		}
	}

// PRIVATE HELPERS
	private void function _denormalizeAndSaveConfiguredPermissions( required struct permissionsConfig ) output=false {
		_setPermissions( _expandPermissions( arguments.permissionsConfig ) );
	}

	private array function _getBenefitPermissions( required string benefit ) output=false {
		var dbData = _getAppliedPermDao().selectData(
			  selectFields = [ "granted", "permission_key" ]
			, filter       = "benefit = :website_benefit.id and context is null and context_key is null"
			, filterParams = { "website_benefit.id" = arguments.benefit }
			, forceJoins   = "inner"
		);
		var perms = [];

		for ( var perm in dbData ) {
			if ( perm.granted ) {
				perms.append( perm.permission_key );
			} else {
				perms.delete( perm.permission_key );
			}
		}

		return perms;
	}

	private array function _getUserPermissions( required string user, boolean includeBenefitPerms=true ) output=false {
		var perms = [];

		if ( arguments.includeBenefitPerms ) {
			var benefits = listUserBenefits( arguments.user );
			var benefitPerms = _getAppliedPermDao().selectData(
				  selectFields = [ "granted", "permission_key" ]
				, filter       = "benefit in ( :website_benefit.id ) and context is null and context_key is null"
				, filterParams = { "website_benefit.id" = benefits }
				, forceJoins   = "inner"
				, orderby      = "benefit.priority"
			);

			for ( var perm in benefitPerms ) {
				if ( perm.granted ) {
					if ( !perms.find( perm.permission_key ) ) {
						perms.append( perm.permission_key );
					}
				} else {
					perms.delete( perm.permission_key );
				}
			}
		}

		var userPerms = _getAppliedPermDao().selectData(
			  selectFields = [ "granted", "permission_key" ]
			, filter       = "user in ( :website_user.id ) and context is null and context_key is null"
			, filterParams = { "website_user.id" = arguments.user }
			, forceJoins   = "inner"
		);

		for ( var perm in userPerms ) {
			if ( perm.granted ) {
				if ( !perms.find( perm.permission_key ) ) {
					perms.append( perm.permission_key );
				}
			} else {
				perms.delete( perm.permission_key );
			}
		}

		return perms;
	}

	private array function _filterPermissions( required array filter ) output=false {
		var filtered   = [];
		var exclusions = [];
		var allPerms   = _getPermissions();

		for( var permissionKey in filter ){
			if ( IsSimpleValue( permissionKey ) ) {
				if ( Left( permissionKey, 1 ) == "!" ) {
					exclusions.append( ReReplace( permissionKey, "^!(.*)$", "\1" ) );

				} elseif ( permissionKey contains "*" ) {
					( _expandWildCardPermissionKey( permissionKey ) ).each( function( expandedKey ){
						if ( !filtered.findNoCase( expandedKey ) ) {
							filtered.append( expandedKey );
						}
					} );
				} elseif ( allPerms.findNoCase( permissionKey ) && !filtered.findNoCase( permissionKey ) ) {
					filtered.append( permissionKey );
				}
			}
		}

		for( var exclusion in exclusions ){
			if ( exclusion contains "*" ) {
				( _expandWildCardPermissionKey( exclusion ) ).each( function( expandedKey ){
					filtered.delete( expandedKey );
				} );
			} else {
				filtered.delete( exclusion );
			}
		}

		return filtered;
	}

	private any function _getContextPermission(
		  required string userId
		, required string permissionKey
		, required string context
		, required array  contextKeys
	) {
		var cacheKey           = "Context perms for context: " & arguments.context;
		var cntext             = arguments.context;
		var cachedContextPerms = _getCacheProvider().getOrSet( objectKey=cacheKey, produce=function(){
			var permsToCache = {};
			var permsFromDb  = _getAppliedPermDao().selectData(
				  selectFields = [ "granted", "context_key", "permission_key", "benefit", "user" ]
				, filter       = "context = :context and ( benefit is not null or user is not null )"
				, filterParams = { context = cntext }
			);

			for( var perm in permsFromDb ){
				if ( IsNull( perm.benefit ) || !Len( Trim( perm.benefit ) ) ) {
					permsToCache[ perm.context_key & "_" & perm.permission_key & "_" & perm.user ] = perm.granted;
				} else {
					permsToCache[ perm.context_key & "_" & perm.permission_key & "_" & perm.benefit ] = perm.granted;
				}
			}

			return permsToCache;
		} );

		for( var key in arguments.contextKeys ){
			// direct user context permission
			cacheKey = key & "_" & arguments.permissionKey & "_" & arguments.userId;
			if ( StructKeyExists( cachedContextPerms, cacheKey ) && IsBoolean( cachedContextPerms[ cacheKey ] ) ) {
				return cachedContextPerms[ cacheKey ];
			}

			// context permission via user's benefits
			for( var benefit in listUserBenefits( arguments.userId ) ){
				cacheKey = key & "_" & arguments.permissionKey & "_" & benefit;
				if ( StructKeyExists( cachedContextPerms, cacheKey ) && IsBoolean( cachedContextPerms[ cacheKey ] ) ) {
					return cachedContextPerms[ cacheKey ];
				}
			}
		}

		return NullValue();
	}

	private array function _expandPermissions( required struct permissions, string prefix="" ) output=false {
		var expanded = [];

		for( var perm in permissions ){
			var newPrefix = ListAppend( arguments.prefix, perm, "." );

			if ( IsStruct( permissions[ perm ] ) ) {
				var childPerms = _expandPermissions( permissions[ perm ], newPrefix );
				for( var childPerm in childPerms ){
					expanded.append( childPerm );
				}
			} elseif ( IsArray( permissions[ perm ] ) ) {
				for( var key in permissions[ perm ] ) {
					if ( IsSimpleValue( key ) ) {
						expanded.append( ListAppend( newPrefix, key, "." ) );
					}
				}
			}
		}

		return expanded;
	}

	private array function _expandWildCardPermissionKey( required string permissionKey ) output=false {
		var regex       = Replace( _reEscape( arguments.permissionKey ), "\*", "(.*?)", "all" );
		var permissions = _getPermissions();

		return permissions.filter( function( permKey ){
			return ReFindNoCase( regex, permKey );
		} );
	}

	private string function _reEscape( required string stringToEscape ) output=false {
		var charsToEscape = [ "\", "$","{","}","(",")","<",">","[","]","^",".","*","+","?","##",":","&" ];
		var escaped       = arguments.stringToEscape;

		for( var char in charsToEscape ){
			escaped = Replace( escaped, char, "\" & char, "all" );
		}

		return escaped;
	}

	private array function _getDefaultBenefitsForPermission( required string permissionKey ) output=false {
		var roles         = _getRoles();
		var rolesWithPerm = {};
		var benefits        = [];

		for( var role in roles ){
			if ( roles[ role ].find( arguments.permissionKey ) ) {
				rolesWithPerm[ role ] = 1;
			}
		}

		if ( StructCount( rolesWithPerm ) ) {
			var allBenefits = _getBenefitsDao().selectData(
				selectFields = [ "id", "label", "roles" ]
			);

			for( var benefit in allBenefits ){
				for ( var role in ListToArray( benefit.roles ) ) {
					if ( rolesWithPerm.keyExists( role ) ) {
						benefits.append( { id=benefit.id, name=benefit.label } );
						break;
					}
				}
			}
		}

		return benefits;
	}

// GETTERS AND SETTERS
	private array function _getPermissions() output=false {
		return _permissions;
	}
	private void function _setPermissions( required array permissions ) output=false {
		_permissions = arguments.permissions;
	}

	private any function _getWebsiteUserService() output=false {
		return _websiteUserService;
	}
	private void function _setWebsiteUserService( required any websiteUserService ) output=false {
		_websiteUserService = arguments.websiteUserService;
	}

	private any function _getCacheProvider() output=false {
		return _cacheProvider;
	}
	private void function _setCacheProvider( required any cacheProvider ) output=false {
		_cacheProvider = arguments.cacheProvider;
	}

	private any function _getBenefitsDao() output=false {
		return _benefitsDao;
	}
	private void function _setBenefitsDao( required any benefitsDao ) output=false {
		_benefitsDao = arguments.benefitsDao;
	}

	private any function _getUserDao() output=false {
		return _userDao;
	}
	private void function _setUserDao( required any userDao ) output=false {
		_userDao = arguments.userDao;
	}

	private any function _getAppliedPermDao() output=false {
		return _appliedPermDao;
	}
	private void function _setAppliedPermDao( required any appliedPermDao ) output=false {
		_appliedPermDao = arguments.appliedPermDao;
	}
}
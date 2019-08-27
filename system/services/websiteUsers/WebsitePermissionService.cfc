/**
 * Service that provides API methods for dealing with website user permissions.
 * See [[websiteusersandpermissioning]] for a full guide to website users and permissions.
 *
 * @singleton
 * @presideService
 * @autodoc
 *
 */
component displayName="Website permissions service" {

// CONSTRUCTOR
	/**
	 * @websiteLoginService.inject websiteLoginService
	 * @cacheProvider.inject       cachebox:WebsitePermissionsCache
	 * @permissionsConfig.inject   coldbox:setting:websitePermissions
	 * @benefitsDao.inject         presidecms:object:website_benefit
	 * @userDao.inject             presidecms:object:website_user
	 * @appliedPermDao.inject      presidecms:object:website_applied_permission
	 */
	public any function init(
		  required any    websiteLoginService
		, required any    cacheProvider
		, required struct permissionsConfig
		, required any    benefitsDao
		, required any    userDao
		, required any    appliedPermDao
	) {
		_setWebsiteLoginService( arguments.websiteLoginService );
		_setCacheProvider( arguments.cacheProvider );
		_setBenefitsDao( arguments.benefitsDao );
		_setUserDao( arguments.userDao );
		_setAppliedPermDao( arguments.appliedPermDao );

		_denormalizeAndSaveConfiguredPermissions( arguments.permissionsConfig );

		return this;
	}

// PUBLIC API METHODS

	/**
	 * Returns an array of permission keys that apply to the
	 * given arguments.
	 * \n
	 * See [[websiteusersandpermissioning]] for a full guide to website users and permissions.
	 *
	 * @autodoc
	 * @benefit.hint If supplied, the method will return permission keys that users with the supplied benefit have access to
	 * @user.hint    If supplied, the method will return permission keys that the user has access to
	 * @filter.hint  An array of filters with which to filter permission keys
	 *
	 */
	public array function listPermissionKeys( string benefit="", string user="", array filter=[] ) {
		if ( Len( Trim( arguments.benefit ) ) ) {
			return _getBenefitPermissions( arguments.benefit );

		} else if ( Len( Trim( arguments.user ) ) ) {
			return _getUserPermissions( arguments.user );

		} else if ( arguments.filter.len() ) {
			return _filterPermissions( arguments.filter );
		}

		return _getPermissions();
	}

	/**
	 * Returns whether or not the user has permission to the given
	 * set of keys.
	 * \n
	 * See [[websiteusersandpermissioning]] for a full guide to website users and permissions.
	 *
	 * @autodoc
	 * @permissionKey.hint       The permission key as defined in `Config.cfc`
	 * @context.hint             Optional named context
	 * @contextKeys.hint         Array of keys for the given context (required if context supplied)
	 * @userId.hint              ID of the user whose permissions we wish to check
	 * @userId.docdefault        ID of logged in user
	 * @forceGrantByDefault.hint Whether or not to force a granted permission by default, unless a specific context permission overrides that grant
	 *
	 */
	public boolean function hasPermission(
		  required string  permissionKey
		,          string  context             = ""
		,          array   contextKeys         = []
		,          string  userId              = _getWebsiteLoginService().getLoggedInUserId()
		,          boolean forceGrantByDefault = false
	) {
		if ( !Len( Trim( arguments.userId ) ) ) {
			return false;
		}

		if ( Trim( arguments.context ).len() && arguments.contextKeys.len() ) {
			var contextPerm = _getContextPermission( argumentCollection=arguments );
			if ( !IsNull( local.contextPerm ) && IsBoolean( contextPerm ) ) {
				return contextPerm;
			}
		}

		return arguments.forceGrantByDefault || listPermissionKeys( user=arguments.userId ).findNoCase( arguments.permissionKey );
	}

	/**
	 * Returns an array of IDs of the supplied user's benefits
	 * \n
	 * See [[websiteusersandpermissioning]] for a full guide to website users and permissions.
	 *
	 * @autodoc
	 * @userId  ID of the user whose benefits we wish to get
	 *
	 */
	public array function listUserBenefits( required string userId ) {
		if ( !$isFeatureEnabled( "websiteBenefits" ) ) {
			return [];
		}

		var comboBenefits = _getComboBenefits();
		var benefits      = _getUserDao().selectManyToManyData(
			  propertyName = "benefits"
			, id           = arguments.userId
			, selectFields = [ "benefits.id" ]
			, orderby      = "benefits.priority desc"
		);

		var userBenefits = ValueArray( benefits.id );
		var comboFound   = false;

		do {
			comboFound = false;
			for( var comboBenefit in comboBenefits ){
				if ( userBenefits.findNoCase( comboBenefit.id ) ) {
					continue;
				}

				var inclusive = IsBoolean( comboBenefit.combined_benefits_are_inclusive ) && comboBenefit.combined_benefits_are_inclusive;
				var hasComboBenefit = !inclusive;
				for( var benefitId in ListToArray( comboBenefit.combined_benefits ) ){
					if ( inclusive ) {
						if ( userBenefits.findNoCase( benefitId ) ) {
							hasComboBenefit = true;
							break;
						}
					} else {
						if ( !userBenefits.findNoCase( benefitId ) ) {
							hasComboBenefit = false;
							break;
						}
					}
				}

				if ( hasComboBenefit ) {
					userBenefits.append( comboBenefit.id );
					comboFound = true;
				}
			}
		} while( comboFound );

		return userBenefits;
	}

	/**
	 * Returns an array of permission keys that the user
	 * has access to
	 * \n
	 * See [[websiteusersandpermissioning]] for a full guide to website users and permissions.
	 *
	 * @autodoc
	 * @userId  ID of the user whose permissions we wish to get
	 *
	 */
	public array function listUserPermissions( required string userId ) {
		return _getUserPermissions( arguments.userId, false );
	}

	public void function syncBenefitPermissions( required string benefitId, required array permissions ) {
		if ( !$isFeatureEnabled( "websiteBenefits" ) ) {
			return;
		}

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

	public void function syncUserPermissions( required string userId, required array permissions ) {
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
	) {
		var dao = _getAppliedPermDao();

		transaction {
			dao.deleteData( filter={ context = arguments.context, context_key=arguments.contextKey, permission_key=arguments.permissionKey } );

			if ( $isFeatureEnabled( "websiteBenefits" ) ) {
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

	public struct function getContextualPermissions( required string context, required string contextKey, required string permissionKey ) {
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

	public void function prioritizeBenefits( required array benefitsInOrder ) {
		if ( !$isFeatureEnabled( "websiteBenefits" ) ) {
			return;
		}

		var dao = _getBenefitsDao();

		for ( var i=1; i <= arguments.benefitsInOrder.len(); i++ ) {
			dao.updateData( id=arguments.benefitsInOrder[i], data={ priority=i } );
		}

		$audit(
			  source = "websitebenefitsmanager"
			, type   = "websitebenefitsmanager"
			, action = "prioritize_website_benefits"
		);
	}

// PRIVATE HELPERS
	private void function _denormalizeAndSaveConfiguredPermissions( required struct permissionsConfig ) {
		_setPermissions( _expandPermissions( arguments.permissionsConfig ) );
	}

	private array function _getBenefitPermissions( required string benefit ) {
		if ( !$isFeatureEnabled( "websiteBenefits" ) ) {
			return [];
		}
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

	private array function _getUserPermissions( required string user, boolean includeBenefitPerms=true ) {
		var perms = [];

		if ( $isFeatureEnabled( "websiteBenefits" ) && arguments.includeBenefitPerms ) {
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
					if ( !perms.findNoCase( perm.permission_key ) ) {
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
				if ( !perms.findNoCase( perm.permission_key ) ) {
					perms.append( perm.permission_key );
				}
			} else {
				perms.delete( perm.permission_key );
			}
		}

		return perms;
	}

	private array function _filterPermissions( required array filter ) {
		var filtered   = [];
		var exclusions = [];
		var allPerms   = _getPermissions();

		for( var permissionKey in filter ){
			if ( IsSimpleValue( permissionKey ) ) {
				if ( Left( permissionKey, 1 ) == "!" ) {
					exclusions.append( ReReplace( permissionKey, "^!(.*)$", "\1" ) );

				} else if ( permissionKey contains "*" ) {
					( _expandWildCardPermissionKey( permissionKey ) ).each( function( expandedKey ){
						if ( !filtered.findNoCase( expandedKey ) ) {
							filtered.append( expandedKey );
						}
					} );
				} else if ( allPerms.findNoCase( permissionKey ) && !filtered.findNoCase( permissionKey ) ) {
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
		var cntext       = arguments.context;
		var cache        = _getCacheProvider();
		var cacheKey     = "Context perms for context: " & arguments.context;
		var contextPerms = cache.get( cacheKey );

		if ( IsNull( local.contextPerms ) ) {
			contextPerms = {};

			var permsFromDb  = _getAppliedPermDao().selectData(
				  selectFields = [ "granted", "context_key", "permission_key", "benefit", "user" ]
				, filter       = "context = :context and ( benefit is not null or user is not null )"
				, filterParams = { context = cntext }
			);

			for( var perm in permsFromDb ){
				if ( IsNull( perm.benefit ) || !Len( Trim( perm.benefit ) ) ) {
					contextPerms[ perm.context_key & "_" & perm.permission_key & "_" & perm.user ] = perm.granted;
				} else {
					contextPerms[ perm.context_key & "_" & perm.permission_key & "_" & perm.benefit ] = perm.granted;
				}
			}

			cache.set( cacheKey, contextPerms );
		}

		for( var key in arguments.contextKeys ){
			// direct user context permission
			cacheKey = key & "_" & arguments.permissionKey & "_" & arguments.userId;
			if ( StructKeyExists( contextPerms, cacheKey ) && IsBoolean( contextPerms[ cacheKey ] ) ) {
				return contextPerms[ cacheKey ];
			}

			// context permission via user's benefits
			for( var benefit in listUserBenefits( arguments.userId ) ){
				cacheKey = key & "_" & arguments.permissionKey & "_" & benefit;
				if ( StructKeyExists( contextPerms, cacheKey ) && IsBoolean( contextPerms[ cacheKey ] ) ) {
					return contextPerms[ cacheKey ];
				}
			}
		}

		return NullValue();
	}

	private array function _expandPermissions( required struct permissions, string prefix="" ) {
		var expanded = [];

		for( var perm in permissions ){
			var newPrefix = ListAppend( arguments.prefix, perm, "." );

			if ( IsStruct( permissions[ perm ] ) ) {
				var childPerms = _expandPermissions( permissions[ perm ], newPrefix );
				for( var childPerm in childPerms ){
					expanded.append( childPerm );
				}
			} else if ( IsArray( permissions[ perm ] ) ) {
				for( var key in permissions[ perm ] ) {
					if ( IsSimpleValue( key ) ) {
						expanded.append( ListAppend( newPrefix, key, "." ) );
					}
				}
			}
		}

		return expanded;
	}

	private array function _expandWildCardPermissionKey( required string permissionKey ) {
		var regex       = Replace( _reEscape( arguments.permissionKey ), "\*", "(.*?)", "all" );
		var permissions = _getPermissions();

		return permissions.filter( function( permKey ){
			return ReFindNoCase( regex, permKey );
		} );
	}

	private string function _reEscape( required string stringToEscape ) {
		var charsToEscape = [ "\", "$","{","}","(",")","<",">","[","]","^",".","*","+","?","##",":","&" ];
		var escaped       = arguments.stringToEscape;

		for( var char in charsToEscape ){
			escaped = Replace( escaped, char, "\" & char, "all" );
		}

		return escaped;
	}

	private array function _getDefaultBenefitsForPermission( required string permissionKey ) {
		if ( !$isFeatureEnabled( "websiteBenefits" ) ) {
			return [];
		}

		var roles         = _getRoles();
		var rolesWithPerm = {};
		var benefits        = [];

		for( var role in roles ){
			if ( roles[ role ].findNoCase( arguments.permissionKey ) ) {
				rolesWithPerm[ role ] = 1;
			}
		}

		if ( StructCount( rolesWithPerm ) ) {
			var allBenefits = _getBenefitsDao().selectData(
				selectFields = [ "id", "label", "roles" ]
			);

			for( var benefit in allBenefits ){
				for ( var role in ListToArray( benefit.roles ) ) {
					if ( StructKeyExists( rolesWithPerm, role ) ) {
						benefits.append( { id=benefit.id, name=benefit.label } );
						break;
					}
				}
			}
		}

		return benefits;
	}

	private query function _getComboBenefits() {
		if ( $isFeatureEnabled( "websiteBenefits" ) ) {
			return _getBenefitsDao().selectData(
				  selectFields = [ "website_benefit.id", "website_benefit.combined_benefits_are_inclusive", "group_concat( distinct combined_benefits.id ) as combined_benefits" ]
				, groupBy      = "website_benefit.id,website_benefit.combined_benefits_are_inclusive"
				, forceJoins   = "inner"
			);
		}

		return QueryNew( "id,combined_benefits_are_inclusive,combined_benefits" );
	}

// GETTERS AND SETTERS
	private array function _getPermissions() {
		return _permissions;
	}
	private void function _setPermissions( required array permissions ) {
		_permissions = arguments.permissions;
	}

	private any function _getWebsiteLoginService() {
		return _websiteLoginService;
	}
	private void function _setWebsiteLoginService( required any websiteLoginService ) {
		_websiteLoginService = arguments.websiteLoginService;
	}

	private any function _getCacheProvider() {
		return _cacheProvider;
	}
	private void function _setCacheProvider( required any cacheProvider ) {
		_cacheProvider = arguments.cacheProvider;
	}

	private any function _getBenefitsDao() {
		return _benefitsDao;
	}
	private void function _setBenefitsDao( required any benefitsDao ) {
		_benefitsDao = arguments.benefitsDao;
	}

	private any function _getUserDao() {
		return _userDao;
	}
	private void function _setUserDao( required any userDao ) {
		_userDao = arguments.userDao;
	}

	private any function _getAppliedPermDao() {
		return _appliedPermDao;
	}
	private void function _setAppliedPermDao( required any appliedPermDao ) {
		_appliedPermDao = arguments.appliedPermDao;
	}
}
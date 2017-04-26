component extends="coldbox.system.web.Controller" {

	public any function init() {
		super.init( argumentCollection = arguments );

		services.handlerService     = new preside.system.coldboxModifications.services.HandlerService( this );
		services.moduleService      = new preside.system.coldboxModifications.services.ModuleService( this );
		services.interceptorService = new preside.system.coldboxModifications.services.InterceptorService( this );
		services.requestService     = new preside.system.coldboxModifications.services.RequestService( this );
		variables.wireBox           = CreateObject( "preside.system.coldboxModifications.ioc.Injector" );
	}

	function getRenderer(){
		return variables.wireBox.getInstance( "presideRenderer" );
	}

	public boolean function handlerExists( required string event ) {
		var cache      = getCacheBox().getCache( "ViewletExistsCache" );
		var handlerSvc = "";
		var handler    = "";
		var action     = ListLast( arguments.event, "." );
		var cacheKey   = "handler exists: " & arguments.event;
		var exists     = cache.get( cacheKey );

		if ( not IsNull( exists ) ) {
			return exists;
		}

		try {
			handlerSvc = getHandlerService();
			handler = handlerSvc.getRegisteredHandler( event=arguments.event );

			if ( handler.getViewDispatch() ) {
				cache.set( cacheKey, false );
				return false;
			}

			var fullEvent = handler.getFullEvent();
			if ( fullEvent != arguments.event && fullEvent != ( arguments.event & ".index" ) ) {
				cache.set( cacheKey, false );
				return false;
			}

			handler = handlerSvc.getHandler( handler, getRequestContext() );
			handler = GetMetaData( handler );
			if ( Right( handler.fullname ?: "", Len( arguments.event ) ) eq arguments.event ) {
				action = getSetting( name="EventAction", fwSetting=true, defaultValue="index" );
			}
			exists = _actionExistsInHandler( handler, action );
			cache.set( cacheKey, exists );

			return exists;

		} catch( "HandlerService.EventHandlerNotRegisteredException" e ) {
			cache.set( cacheKey, false );
			return false;
		}
	}

	public boolean function viewExists( required string view ) {
		var cache      = getCacheBox().getCache( "ViewletExistsCache" );
		var cacheKey   = "view exists: " & arguments.view;
		var exists     = cache.get( cacheKey );
		var targetView = "";

		if ( not IsNull( exists ) ) {
			return exists;
		}

		targetView = getRenderer().locateView( ListChangeDelims( arguments.view, "/", "." ) );
		exists     = Len( Trim( targetView ) ) and FileExists( ExpandPath( targetView & ".cfm" ) );

		cache.set( cacheKey, exists );

		return exists;
	}

	public boolean function viewletExists( required string event ) {
		return handlerExists( arguments.event ) or viewExists( arguments.event );
	}

	public any function renderViewlet( required string event, struct args={}, boolean private=true, boolean prepostExempt=true  ) {
		var result        = "";
		var view          = "";
		var handler       = arguments.event;
		var defaultAction = getSetting( name="EventAction", fwSetting=true, defaultValue="index" );

		if ( not handlerExists( handler ) ) {
			handler = ListAppend( handler, defaultAction, "." );
		}

		if ( handlerExists( handler ) ) {
			return runEvent(
				  event          = handler
				, prepostExempt  = arguments.prepostExempt
				, private        = arguments.private
				, eventArguments = { args = arguments.args }
			);
		}

		view = ListChangeDelims( arguments.event, "/", "." );
		if ( not viewExists( view ) ) {
			view = ListAppend( view, defaultAction, "/" );
		}

		try {
			return getRenderer().renderView(
				  view = view
				, args = arguments.args
			);
		} catch ( "missinginclude" e ) {
			var cache             = getCacheBox().getCache( "ViewletExistsCache" );
			var missingCheckedKey = "doublecheckmissing" & arguments.event;
			var checkedAlready    = cache.get( missingCheckedKey );

			if ( IsNull( checkedAlready ) ) {
				cache.clearAll();
				cache.set( missingCheckedKey, true );
				return renderViewlet( argumentCollection=arguments );
			}

			rethrow;
		}
	}

	public any function getRequestContext() {
		return getRequestService().getContext();
	}

	public any function getSetting( required string name, boolean fwSetting=false, any defaultValue ) {
		var target = arguments.fwSetting ? variables.coldboxSettings : variables.configSettings;

		if ( target.keyExists( arguments.name ) ) {
			return target[ arguments.name ];
		}

		if ( IsDefined( "target.#arguments.name#" ) ) {
			return Evaluate( "target.#arguments.name#" );
		}

		if ( StructKeyExists( arguments, "defaultValue" ) ) {
			return arguments.defaultValue;
		}

		throw( message="The setting #arguments.name# does not exist.",
			   detail="FWSetting flag is #arguments.FWSetting#",
			   type="Controller.SettingNotFoundException");
	}

// private helpers
	private boolean function _actionExistsInHandler( required struct handlerMeta, required string action ) {
		if ( StructKeyExists( arguments.handlerMeta, "extends" ) and _actionExistsInHandler( arguments.handlerMeta.extends, arguments.action ) ) {
			return true;
		}

		var functions = arguments.handlerMeta.functions ?: [];

		for( var func in functions ) {
			if ( ( func.name ?: "" ) eq arguments.action ) {
				return true;
			}
		}

		return false;
	}
}
/**
 * Preside overrides for core ColdBox InterceptorService that
 * add a safety check that ensures states are not announced
 * before all the interceptors are loaded.
 *
 */
component extends="coldbox.system.web.services.InterceptorService" output=false {

	_registeringInterceptors       = false;
	_currentRegisteringInterceptor = "";

	// these are unavoidably announced during each interceptor instantiation
	_ignoreStatesDuringLoadCheck   = [ "beforeInstanceInspection", "afterInstanceInspection", "beforeInstanceCreation", "afterInstanceInitialized", "beforeInstanceAutowire", "afterInstanceAutowire", "afterInstanceCreation" ];

	public any function registerInterceptors() {
		_registeringInterceptors = true;

		super.registerInterceptors( argumentCollection=arguments );

		_registeringInterceptors = false;
	}

	public any function registerInterceptor( string interceptorClass ) {
		if ( arguments.keyExists( "interceptorClass" ) ) {
			_currentRegisteringInterceptor = arguments.interceptorClass;
		}

		return super.registerInterceptor( argumentCollection=arguments );
	}


	public any function processState( required string state ) {
		if ( _registeringInterceptors && !_ignoreStatesDuringLoadCheck.findNoCase( arguments.state ) ) {
			throw(
				  type    = "coldbox.interceptor.panic"
				, message = "An interception point, [#arguments.state#], was raised during the interceptor registration process and *before* all registered interceptor listeners have been instantiated. This occurred during the instatiation of the [#_currentRegisteringInterceptor#] interceptor. This is a problem because not all interceptors have been registered and setup to listen for the [#arguments.state#] event and this may lead to unexpected behaviour, including widespread changes to your database. This issue is usually caused by injecting dependencies into your interceptor with wirebox and ommitting the 'delayedInjector:' DSL from the beginning of your inject attributes. For example, in interceptors, [property name=""presideObjectService"" inject=""presideObjectService"";] should be [property name=""presideObjectService"" inject=""delayedInjector:presideObjectService"";]"
			);
		}

		return super.processState( argumentCollection=arguments );
	}
}
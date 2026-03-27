/**
 * Preside Interceptor shim for ColdBox 6.0+
 *
 * 1. ColdBox 6.0 moved loadApplicationHelpers() from the constructor to a
 *    lazy cbLoadInterceptorHelpers event. This means interceptors that fire
 *    during startup (e.g. afterConfigurationLoad) don't have helpers like
 *    isFeatureEnabled() available yet. This shim restores eager loading.
 *
 * 2. ColdBox 6.0 removed getModel() from FrameworkSupertype. This shim
 *    restores it as a passthrough to getInstance().
 */
component extends="coldbox.system.Interceptor" {

	function init( required controller, struct properties = {} ){
		super.init( argumentCollection = arguments );

		// CB 5.4 loaded helpers in init(); CB 6.0+ defers to cbLoadInterceptorHelpers.
		// Restore eager loading so helpers are available during startup interceptions.
		loadApplicationHelpers( force: true );

		return this;
	}

	/**
	 * Compatibility shim: getModel() was removed in ColdBox 6.0
	 */
	function getModel( name, dsl, initArguments={} ){
		return getInstance( argumentCollection=arguments );
	}

}

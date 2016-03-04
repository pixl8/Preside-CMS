component extends="coldbox.system.Interceptor" {

	property name="emailService" inject="delayedInjector:emailService";

// PUBLIC
	public void function configure() {}

	public void function preSaveSystemConfig( event, interceptData ) {
		var category      = interceptData.category ?: "";
		var configuration = interceptData.configuration ?: {};

		if ( category == "email" && configuration.keyExists( "server" ) && configuration.keyExists( "port" ) && configuration.keyExists( "username" ) && configuration.keyExists( "password" ) ) {
			var errorMessage = emailService.validateConnectionSettings(
				  host     = configuration.server
				, port     = configuration.port
				, username = configuration.username
				, password = configuration.password
			);

			if ( Len( Trim( errorMessage ) ) && !IsSimpleValue( interceptData.validationResult ?: "" ) ) {
				if ( errorMessage == "authentication failure" ) {
					interceptData.validationResult.addError( "username", "system-config.email:validation.server.authentication.failure" );
				} else {
					interceptData.validationResult.addError( "server", "system-config.email:validation.server.details.invalid", [ errorMessage ] );
				}
			}
		}
	}
}
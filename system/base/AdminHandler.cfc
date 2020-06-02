component {
	property name="applicationsService" inject="applicationsService";
	property name="loginService"        inject="loginService";
	property name="sessionStorage"      inject="sessionStorage";
	property name="messageBox"          inject="messagebox@cbmessagebox";

	public void function preHandler( event, action, eventArguments ) {
		if( event.isStatelessRequest() ){
			event.adminAccessDenied();
		}
		_checkLogin( event );

		var activeApplication = applicationsService.getActiveApplication( event.getCurrentEvent() );
		var operationSource   = event.getValue( "_psource", "" );

		if ( Len( Trim( operationSource ) ) ) {
			event.setAdminOperationSource( operationSource );
		}

		event.setXFrameOptionsHeader( "SAMEORIGIN" );
		event.setLayout( applicationsService.getLayout( activeApplication ) );
		event.setLanguage( "" );
		event.includeData( {
			  ajaxEndpoint = event.buildAdminLink( linkTo="ajaxProxy" )
			, adminBaseUrl = event.getAdminPath()
			, siteId       = event.getSiteId()
		} );
		event.includeData( event.getCollection() );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:home.title" )
			, link  = event.buildLink( linkTo=applicationsService.getDefaultEvent( activeApplication ) )
		);
	}

// PRIVATE HELPERS
	private void function _checkLogin( event ) {
		var currentEvent = event.getCurrentEvent();
		var loginExcempt = currentEvent.reFindNoCase( "^admin\.(login|ajaxProxy|general\.setlocale)" );
		var postLoginUrl = "";

		if ( !loginExcempt ) {
			var isAdminUser     = event.isAdminUser();
			var isAuthenticated = isAdminUser && !loginService.twoFactorAuthenticationRequired( ipAddress = event.getClientIp(), userAgent = event.getUserAgent() );

			if ( !isAuthenticated ) {
				if ( event.isAjax() ) {
					content reset=true type="application/json";
					header statuscode="401" statustext="Access denied";
					echo( SerializeJson( { error="access denied"} ) );
					abort;
				} else if ( event.isActionRequest() ) {
					if ( Len( Trim( cgi.http_referer ) ) ) {
						postLoginUrl = cgi.http_referer;
						if ( event.getHttpMethod() eq "POST" ) {
							sessionStorage.setVar( "_unsavedFormData", Duplicate( form ) );
							messageBox.warn( translateResource( uri="cms:loggedout.saveddata.warning" ) );

						} else {
							messageBox.warn( translateResource( uri="cms:loggedout.noactiontaken.warning" ) );
						}
					} else {
						postLoginUrl = event.buildAdminLink( linkTo="" );
					}

				} else {
					postLoginUrl = rc.postLoginUrl ?: event.getCurrentUrl();
				}

				if ( isAdminUser ) {
					setNextEvent( url=event.buildAdminLink( "login.twoStep" ), persistStruct={ postLoginUrl = postLoginUrl } );
				} else {
					setNextEvent( url=event.buildAdminLink( "login" ), persistStruct={ postLoginUrl = postLoginUrl } );
				}
			}
		}
	}
}
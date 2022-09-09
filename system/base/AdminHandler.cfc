component {
	property name="applicationsService" inject="applicationsService";
	property name="loginService"        inject="loginService";
	property name="sessionStorage"      inject="sessionStorage";
	property name="messageBox"          inject="messagebox@cbmessagebox";
	property name="antiSamySettings"    inject="coldbox:setting:antiSamy";
	property name="antiSamyService"     inject="antiSamyService";

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

		var data = StructCopy( event.getCollection() );

		// Only necessary for GET request and where antisamy is disabled or disabled in admin
		// clean rc data before setting in javascript data
		if ( !event.isPostRequest() && IsFalse( antiSamySettings.enabled ?: "" ) || IsTrue( antiSamySettings.bypassForAdministrators ?: "" ) ) {
			data = _cleanData( data, antiSamySettings.policy ?: "myspace" );
		}
		event.includeData( data );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:home.title" )
			, link  = applicationsService.getDefaultUrl( applicationId=activeApplication, siteId=event.getSiteId() )
		);
	}

// PRIVATE HELPERS
	private any function _cleanData(
		  required any    data
		,          string policy="myspace"
	) {
		if ( IsSimpleValue( data ) ) {
			return antiSamyService.clean( data, arguments.policy );
		} else {
			if ( IsStruct( data ) ) {
				for ( var key in data ) {
					data[ key ] = _cleanData( data[ key ], arguments.policy );
				}
			} else if ( IsArray( data ) ) {
				for ( var i = 1; i <= ArrayLen( data ); i++ ) {
					data[ i ] = _cleanData( data[ i ], arguments.policy );
				}
			}

			return data;
		}
	}

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
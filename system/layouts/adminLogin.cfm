<cfscript>
	body          = renderView();
	notifications = renderView( 'admin/general/notifications' );

	event.include( "/css/core/"                        , "admin" );
	event.include( "/css/specific/login/"              , "admin" );
	event.include( "/js/core/"                         , "admin" );
	event.include( "/js/specific/login/"               , "admin" );
	event.include( "/js/i18n/#getfwLocale()#/bundle.js", "admin" );

	bottomJs = event.renderIncludes( "js", "admin" );
	css      = event.renderIncludes( "css", "admin" );
	
	event.include( "/js/coretop/ie/"                   , "admin" );
	event.include( "/js/coretop/"                      , "admin" );
	topJs = event.renderIncludes( "js", "admin" );
</cfscript>

<cfoutput><!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="utf-8" />
		<title>PresideCMS</title>

		<meta name="robots" content="NOINDEX,NOFOLLOW" />
		<meta name="description" content="" />
		<meta name="viewport" content="width=device-width, initial-scale=1.0" />

		#css#
		#topJs#
	</head>

	<body class="login-layout">
		<div class="main-container">
			<div class="main-content">
				<div class="row">
					<div class="col-sm-10 col-sm-offset-1">
						<div class="login-container">
							#body#
						</div>
					</div><!--/span-->
				</div><!--/row-->
			</div>
		</div>

		#notifications#

		#bottomJs#
	</body>
</html></cfoutput>
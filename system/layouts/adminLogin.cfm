<cfscript>
	body          = renderView();
	notifications = renderView( 'admin/general/notifications' );

	event.include( "/css/admin/core/" );
	event.include( "/css/admin/specific/login/" );
	event.include( "/js/admin/presidecore/" );
	event.include( "/js/admin/specific/login/" );
	event.include( "i18n-resource-bundle" );

	bottomJs = event.renderIncludes( "js" );
	css = event.renderIncludes( "css" );
	event.include( assetId="/js/admin/coretop/ie/", group="top" );
	event.include( assetId="/js/admin/coretop/", group="top" );
	topJs = event.renderIncludes( "js", "top" );

	htmlTitle = translateResource( uri="cms:cms.title" ) & " :: " & ( prc.pageTitle ?: translateResource( uri="cms:cms.tagline", defaultValue="" ) );

	header name="cache-control" value="no-cache, no-store";
	header name="expires"       value="Fri, 20 Nov 2015 00:00:00 GMT";

	layoutClass = prc.loginLayoutClass ?: "";
</cfscript>

<cfoutput><!DOCTYPE html>
<html lang="en" class="presidecms login">
	<head>
		<meta charset="utf-8" />
		<title>#htmlTitle#</title>

		<meta name="robots" content="NOINDEX,NOFOLLOW" />
		<meta name="description" content="" />
		<meta name="viewport" content="width=device-width, initial-scale=1.0" />

		#css#
		#topJs#
	</head>

	<body class="login-layout #layoutClass# preside-theme">
		<div class="main-container">
			<div class="main-content">
				<div class="row">
					<div class="col-sm-10 col-sm-offset-1">
						<div class="login-container">
							<div class="pull-right admin-locale-picker-container">
								#renderViewlet( event='admin.Layout.localePicker' )#
							</div>
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
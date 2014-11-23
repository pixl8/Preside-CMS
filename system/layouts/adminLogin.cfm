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
</cfscript>

<cfoutput><!DOCTYPE html>
<html lang="en" class="presidecms">
	<head>
		<meta charset="utf-8" />
		<title>#translateResource( uri="cms:cms.title" )#</title>

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
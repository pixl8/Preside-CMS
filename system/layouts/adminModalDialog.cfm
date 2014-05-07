<cfscript>
	body             = renderView();
	notifications    = renderView( 'admin/general/notifications' );

	currentHandler = event.getCurrentHandler();
	currentAction  = event.getCurrentAction();

	event.include( "/css/admin/core/" );
	event.include( "/css/admin/specific/#currentHandler#/" );
	event.include( "/css/admin/specific/#currentHandler#/#currentAction#/" );
	event.include( "/js/admin/core/" );
	event.include( "/js/admin/specific/#currentHandler#/" );
	event.include( "/js/admin/specific/#currentHandler#/#currentAction#/" );
	event.include( "/js/admin/i18n/#getfwLocale()#/bundle.js" );

	css        = event.renderIncludes( "css" );
	bottomJs   = event.renderIncludes( "js" );

	ckEditorJs = renderView( "admin/layout/ckeditorjs" );

	event.include( "/js/admin/coretop/ie/" );
	event.include( "/js/admin/coretop/" );
	topJs = event.renderIncludes( "js" );
</cfscript>

<cfoutput><!DOCTYPE html>
<html lang="en" class="iframe">
	<head>
		<meta charset="utf-8" />
		<title>#translateResource( uri="cms:cms.title" )#</title>
		<meta name="robots" content="NOINDEX,NOFOLLOW" />
		<meta name="description" content="" />
		<meta name="viewport" content="width=device-width, initial-scale=1.0" />

		#css#
		#topJs#
	</head>

	<body>
		<div class="main-container widgets-browser" id="main-container">
			<div class="main-container-inner">
				<div class="main-content">
					#body#
				</div>
			</div>
 		</div>

		#ckEditorJs#
		#bottomJs#
	</body>
</html></cfoutput>
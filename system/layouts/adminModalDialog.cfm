<cfscript>
	body             = renderView();
	notifications    = renderView( 'admin/general/notifications' );

	currentHandler = event.getCurrentHandler();
	currentAction  = event.getCurrentAction();

	event.include( "/css/core/"                                     , "admin" );
	event.include( "/css/specific/#currentHandler#/"                , "admin" );
	event.include( "/css/specific/#currentHandler#/#currentAction#/", "admin" );
	event.include( "/js/core/"                                      , "admin" );
	event.include( "/js/specific/#currentHandler#/"                 , "admin" );
	event.include( "/js/specific/#currentHandler#/#currentAction#/" , "admin" );
	event.include( "/js/i18n/#getfwLocale()#/bundle.js"             , "admin" );

	ckEditorJs = renderView( "admin/layout/ckeditorjs" );
	css        = event.renderIncludes( "css", "admin" );
	bottomJs   = event.renderIncludes( "js" , "admin" );

	event.include( "/js/coretop/ie/", "admin" );
	event.include( "/js/coretop/"   , "admin" );
	topJs = event.renderIncludes( "js", "admin" );
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
		<div class="main-container modal-dialog-layout-container" id="main-container">
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
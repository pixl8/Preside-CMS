<cfscript>
	body             = renderView();
	notifications    = renderView( 'admin/general/notifications' );

	currentHandler = event.getCurrentHandler();
	currentAction  = event.getCurrentAction();

	event.include( "/css/admin/core/" );
	event.include( "/css/admin/specific/#currentHandler#/", false );
	event.include( "/css/admin/specific/#currentHandler#/#currentAction#/", false );
	event.include( "/js/admin/presidecore/" );
	event.include( "/js/admin/specific/#currentHandler#/", false );
	event.include( "/js/admin/specific/#currentHandler#/#currentAction#/", false );
	event.include( "i18n-resource-bundle" );

	ckEditorJs = renderView( "admin/layout/ckeditorjs" );
	css        = event.renderIncludes( "css" );
	bottomJs   = event.renderIncludes( "js" );


	event.include( assetId="/js/admin/coretop/ie/", group="top" );
	event.include( assetId="/js/admin/coretop/", group="top" );
	topJs = event.renderIncludes( type="js", group="top" );
</cfscript>

<cfoutput><!DOCTYPE html>
<html lang="en" class="iframe presidecms">
	<head>
		<meta charset="utf-8" />
		<title>#translateResource( uri="cms:cms.title" )#</title>
		<meta name="robots" content="NOINDEX,NOFOLLOW" />
		<meta name="description" content="" />
		<meta name="viewport" content="width=device-width, initial-scale=1.0" />

		#css#
		#topJs#
	</head>

	<body class="preside-theme">
		<div class="main-container modal-dialog-layout-container" id="main-container">
			<div class="main-container-inner">
				<div class="main-content">
					<div class="page-content">
						<cfif Len( Trim( prc.pageTitle ?: "" ) )>
							#renderView( view="admin/general/pageTitle", args={
								  title    = ( prc.pageTitle    ?: "" )
								, subTitle = ( prc.pageSubTitle ?: "" )
								, icon     = ( prc.pageIcon     ?: "" )
							} )#
						</cfif>

						<div class="modal-padding">
							#body#
						</div>
					</div>
				</div>
			</div>
 		</div>

		#ckEditorJs#
		#bottomJs#
	</body>
</html></cfoutput>
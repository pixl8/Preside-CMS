<cfscript>
	body             = renderView();
	navbar           = renderView( 'admin/layout/navbar' );
	breadcrumbs      = renderView( 'admin/layout/breadcrumbs' );
	sideBarNav       = renderView( 'admin/layout/sideBarNavigation' );
//	uiSettingsWidget = renderView( 'admin/layout/uiSettingsWidget' );
	backToTopWidget  = renderView( 'admin/layout/backToTopWidget' );
	notifications    = renderView( 'admin/general/notifications' );

	currentHandler = event.getCurrentHandler();
	currentAction  = event.getCurrentAction();

	event.include( "/css/admin/core/" );
	event.include( "/css/admin/specific/#currentHandler#/", false );
	event.include( "/css/admin/specific/#currentHandler#/#currentAction#/", false );
	event.include( "/js/admin/core/" );
	event.include( "/js/admin/specific/#currentHandler#/", false );
	event.include( "/js/admin/specific/#currentHandler#/#currentAction#/", false );
	event.include( "/js/admin/i18n/#getfwLocale()#/bundle.js", false );

	if ( hasPermission( "devtools.console" ) ) {
		event.include( "/js/admin/devtools/" );
		event.include( "/css/admin/devtools/" );
	}

	ckEditorJs = renderView( "admin/layout/ckeditorjs" );
	css        = event.renderIncludes( "css" );
	bottomJs   = event.renderIncludes( "js" );

	event.include( assetId="/js/admin/coretop/", group="top" );
	event.include( assetId="/js/admin/coretop/ie/", group="top" );
	topJs      = event.renderIncludes( "js", "top" );
</cfscript>

<cfoutput><!DOCTYPE html>
<html lang="en">
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
		#navbar#

		<div class="main-container" id="main-container">
			<script type="text/javascript">
				try{ace.settings.check('main-container' , 'fixed')}catch(e){}
			</script>

			<div class="main-container-inner">
				<a class="menu-toggler" id="menu-toggler" href="##">
					<span class="menu-text"></span>
				</a>
				#breadcrumbs#

				#sideBarNav#
				<div class="main-content">

					<div class="page-content">
						#renderView( view="admin/general/pageTitle", args={
							  title    = ( prc.pageTitle    ?: "" )
							, subTitle = ( prc.pageSubTitle ?: "" )
							, icon     = ( prc.pageIcon     ?: "" )
						} )#

						<div class="row">
							<div class="col-xs-12">
								#body#
							</div>
						</div>
					</div>

					<!--- #uiSettingsWidget# --->
				</div>
			</div>
			#backToTopWidget#
		</div>

		#notifications#

		#ckEditorJs#

		#bottomJs#
	</body>
</html></cfoutput>
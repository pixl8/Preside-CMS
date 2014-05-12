<cfif event.isAdminUser()>
	<cfscript>
		event.include( "/js/admin/core/" );
		event.include( "/js/admin/frontend/" );
		event.include( "/js/admin/i18n/#getfwLocale()#/bundle.js" );
		event.include( "/css/admin/frontend/" );
		event.includeData({
			  ajaxEndpoint = event.buildAdminLink( linkTo="ajaxProxy.index" )
			, adminBaseUrl = "/" & getSetting( "preside_admin_path" ) & "/"
		});

		toolbarUrl = event.buildAdminLink(
			  linkTo      = 'general.adminToolbar'
			, querystring = 'pageId=#event.getCurrentPageId()#&template=#event.getCurrentTemplate()#'
		);

		staticRoot = getSetting( name="cfstatic_generated_url", defaultValue="/_assets" );

		if ( event.hasAdminPermission( "dev-tools" ) ) {
			event.include( "/js/admin/devtools/" );
			event.include( "/css/admin/devtools/" );
		}
	</cfscript>

	<cfoutput>
		<div class="preside-admin-toolbar" id="preside-admin-toolbar">
			<a href="#event.buildAdminLink()#"><h1>#translateResource( "cms:admintoolbar.title" )#</h1></a>

			<div class="preside-admin-toolbar-actions">
				<input id="edit-mode-options" class="ace ace-switch ace-switch-3" type="checkbox" />
				<span class="lbl"></span>
			</div>
		</div>

		<cfoutput>
			<script type="text/javascript" src="#staticRoot#/ckeditor/ckeditor.js"></script>
		</cfoutput>
	</cfoutput>
</cfif>


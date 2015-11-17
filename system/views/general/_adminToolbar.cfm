<cfif event.isAdminUser()>
	<cfscript>
		prc.hasCmsPageEditPermissions = prc.hasCmsPageEditPermissions ?: hasCmsPermission( permissionKey="sitetree.edit", context="page", contextKeys=event.getPagePermissionContext() );

		if ( prc.hasCmsPageEditPermissions ) {
			event.include( "/js/admin/presidecore/" );
			event.include( "/js/admin/frontend/" );
			event.includeData({
				  ajaxEndpoint = event.buildAdminLink( linkTo="ajaxProxy.index" )
				, adminBaseUrl = event.getAdminPath()
			});
		}

		event.include( "i18n-resource-bundle" );
		event.include( "/css/admin/core/" );
		event.include( "/css/admin/frontend/" );

		toolbarUrl = event.buildAdminLink(
			  linkTo      = 'general.adminToolbar'
			, querystring = 'pageId=#event.getCurrentPageId()#&template=#event.getCurrentTemplate()#'
		);

		if ( hasCmsPermission( "devtools.console" ) ) {
			event.include( "/js/admin/devtools/" )
			     .include( "/css/admin/devtools/" )
			     .includeData( { devConsoleToggleKeyCode=getSetting( "devConsoleToggleKeyCode" ) } );
		}


		ckEditorJs = renderView( "admin/layout/ckeditorjs" );
	</cfscript>

	<cfoutput>
		<div class="preside-admin-toolbar presidecms" id="preside-admin-toolbar">
			<a href="#event.buildAdminLink()#"><h1>#translateResource( "cms:admintoolbar.title" )#</h1></a>

			<ul class="preside-admin-toolbar-actions list-unstyled">
				<li>
					<cfif prc.hasCmsPageEditPermissions>
						<div class="edit-mode-toggle-container">
							<label>
								#translateResource( "cms:admintoolbar.editmode" )#
								<input id="edit-mode-options" class="ace ace-switch ace-switch-6" type="checkbox" />
								<span class="lbl"></span>
							</span>
						</div>
					</cfif>
					<a class="view-in-tree-link" href="#event.getEditPageLink()#" title="#translateResource( 'cms:admintoolbar.edit.page' )#">
						<i class="fa fa-pencil fa-lg"></i>
					</a>
				</li>
				<li>
					<a href="#event.buildAdminLink( linkTo="login.logout", querystring="redirect=referer" )#">
						<img class="nav-user-photo" src="//www.gravatar.com/avatar/#LCase( Hash( LCase( event.getAdminUserDetails().email_address ) ) )#?r=g&d=mm&s=40" alt="Avatar for #HtmlEditFormat( event.getAdminUserDetails().known_as )#" />
						<span class="logout-link"> #translateResource( "cms:logout.link" )# </span>
					</a>
				</li>
			</ul>
		</div>

		#ckEditorJs#
	</cfoutput>
</cfif>


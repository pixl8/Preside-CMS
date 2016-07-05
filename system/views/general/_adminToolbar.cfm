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

		userMenu          = renderView( "/admin/layout/userMenu" );
		notificationsMenu = renderViewlet( "admin.notifications.notificationNavPromo" );


		ckEditorJs = renderView( "admin/layout/ckeditorjs" );
	</cfscript>

	<cfoutput>
		<div class="presidecms preside-admin-toolbar">
			<div class="preside-theme">
				<div class="navbar navbar-default" id="preside-admin-toolbar">
					<a href="#event.buildAdminLink()#"><h1>#translateResource( "cms:admintoolbar.title" )#</h1></a>

					<div class="navbar-header pull-left">
						<ul class="nav ace-nav">
							<li>
								<cfif prc.hasCmsPageEditPermissions>
									<a class="edit-mode-toggle-container">
										<label>
											<i class="fa fa-fw fa-pencil"></i>
											#translateResource( "cms:admintoolbar.editmode" )#
											<input id="edit-mode-options" class="ace ace-switch ace-switch-6" type="checkbox" />
											<span class="lbl"></span>
										</span>
									</a>
								</cfif>
<!--- 								<a class="view-in-tree-link" href="#event.getEditPageLink()#" title="#translateResource( 'cms:admintoolbar.edit.page' )#">
									<i class="fa fa-pencil fa-lg"></i>
								</a>
 --->							</li>

						</ul>
					</div>
					<div class="navbar-header pull-right">
						<ul class="nav ace-nav">
							<li>#notificationsMenu#</li>
							<li>#userMenu#</li>
						</ul>
					</div>
				</div>
			</div>
		</div>


		#ckEditorJs#
	</cfoutput>
</cfif>


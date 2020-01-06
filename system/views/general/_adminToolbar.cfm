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

		toggleLiveContentLink = event.buildAdminLink( linkTo="general.toggleNonLiveContent" );
		editPageLink          = event.getEditPageLink();
	</cfscript>

	<cfoutput>
		<div class="presidecms preside-admin-toolbar">
			<div class="preside-theme">
				<div class="navbar navbar-default" id="preside-admin-toolbar">
					<a href="#event.buildAdminLink()#"><h1>#translateResource( "cms:admintoolbar.title" )#</h1></a>

					<cfif prc.hasCmsPageEditPermissions>
						<div class="navbar-header pull-left">
							<ul class="nav ace-nav">
								<li>
									<a class="edit-mode-toggle-container">
										<label>
											#translateResource( "cms:admintoolbar.editmode" )#
											<input id="edit-mode-options" class="ace ace-switch ace-switch-6" type="checkbox" />
											<span class="lbl"></span>
										</label>
									</a>

									<a href="#editPageLink#">
										<i class="fa fa-pencil fa-lg fa-fw"></i> #translateResource( 'cms:admintoolbar.edit.page' )#
									</a>
								</li>
								<li class="no-border-left">
									<a data-toggle="preside-dropdown" href="##" class="dropdown-toggle">
										<i class="fa fa-eye-slash fa-lg fa-fw"></i>
										#translateResource( 'cms:admintoolbar.show.hide' )#
										<i class="fa fa-caret-down"></i>
									</a>

									<ul class="user-menu dropdown-menu dropdown-yellow dropdown-caret dropdown-close">
										<li>
											<a href="#toggleLiveContentLink#">
												<cfif event.showNonLiveContent()>
													<i class="fa fa-fw smaller-80"></i>
												<cfelse>
													<i class="fa fa-check fa-fw grey smaller-80"></i>
												</cfif>
												#translateResource( 'cms:admintoolbar.show.live.only' )#
											</a>
										</li>
										<li>
											<a href="#toggleLiveContentLink#">
												<cfif event.showNonLiveContent()>
													<i class="fa fa-check fa-fw grey smaller-80"></i>
												<cfelse>
													<i class="fa fa-fw smaller-80"></i>
												</cfif>
												#translateResource( 'cms:admintoolbar.show.non.live' )#
											</a>
										</li>
									</ul>

								</li>
							</ul>
						</div>
					</cfif>
					<div class="navbar-header pull-right">
						<ul class="nav ace-nav">
							<cfif event.isWebUserImpersonated()>
								<li>&nbsp; <i class="fa fa-fw fa-user-md green"></i> #translateResource( uri="cms:admintoolbar.impersonating.web.user", data=[ getLoggedInUserDetails().email_address ]  )#</li>
							</cfif>
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


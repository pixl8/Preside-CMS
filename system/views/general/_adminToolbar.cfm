<!---@feature admin and cms--->
<cfscript>
	if ( event.isAdminUser() ) {
		prc.adminToolbarDisplayMode = prc.adminToolbarDisplayMode ?: getSystemSetting( "frontend-editing", "admin_toolbar_mode", "fixed" );
	}
</cfscript>
<cfif event.isAdminUser() and !getModel( "loginService" ).twoFactorAuthenticationRequired( ipAddress=event.getClientIp(), userAgent=event.getUserAgent() ) and prc.adminToolbarDisplayMode neq "none">
	<cfscript>
		prc.hasCmsPageEditPermissions = prc.hasCmsPageEditPermissions ?: hasCmsPermission( permissionKey="sitetree.edit", context="page", contextKeys=event.getPagePermissionContext() );
		prc.adminQuickEditDisabled    = prc.adminQuickEditDisabled    ?: isTrue( getSystemSetting( "frontend-editing", "disable_quick_edit" ) );
		event.include( "/js/admin/presidecore/" );

		if ( prc.hasCmsPageEditPermissions ) {
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
		systemAlertsMenu  = renderViewlet( "admin.systemAlerts.systemAlertsMenuItem" );
		ckEditorJs        = prc.adminQuickEditDisabled ? "" : renderView( "admin/layout/ckeditorjs" );

		toggleLiveContentLink = event.buildAdminLink( linkTo="general.toggleNonLiveContent" );
		editPageLink          = event.getEditPageLink();
	</cfscript>

	<cfoutput>
		<cfif prc.adminToolbarDisplayMode eq "reveal">
			<button id="presideAdminToolbarReveal" aria-label="#translateResource( "cms:admintoolbar.toggle" )#"></button>
		</cfif>
		<div class="presidecms preside-admin-toolbar <cfif prc.adminToolbarDisplayMode eq "reveal">preside-admin-toolbar-hidden</cfif>">
			<div class="preside-theme">
				<div class="navbar navbar-default" id="preside-admin-toolbar">
					<a href="#event.buildAdminLink()#"><h1>#translateResource( "cms:admintoolbar.title" )#</h1></a>

					<cfif prc.hasCmsPageEditPermissions>
						<div class="navbar-header pull-left">
							<ul class="nav ace-nav">
								<li>
									<cfif !prc.adminQuickEditDisabled>
										<a class="edit-mode-toggle-container">
											<label>
												#translateResource( "cms:admintoolbar.editmode" )#
												<input id="edit-mode-options" class="ace ace-switch ace-switch-6" type="checkbox" />
												<span class="lbl"></span>
											</label>
										</a>
									</cfif>

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
								<li>
									&nbsp;
									<a class="pr-0 orange" href="#event.buildAdminLink( objectName="website_user", operation="viewRecord", recordId=getLoggedinUserId() )#">
										<i class="fa fa-fw fa-lg fa-mask orange"></i>
										#translateResource( uri="cms:admintoolbar.impersonating.web.user", data=[ getLoggedInUserDetails().email_address ] )#
									</a>
									<a class="p-0" href="#event.buildLink( linkto="login.logout" )#">
										<i class="fa fa-fw fa-lg fa-times"></i>
									</a>
									&nbsp;
								</li>
							</cfif>
							#systemAlertsMenu#
							<li>#notificationsMenu#</li>
							<li>#userMenu#</li>
						</ul>
					</div>
				</div>
			</div>
		</div>

		<script>
			( function(){
				var htmlElement    = document.querySelector( "html" )
				  , bodyElement    = document.querySelector( "body" )
				  , toolbarElement = document.querySelector( ".preside-admin-toolbar" );

				htmlElement.classList.add( "admin-toolbar-#prc.adminToolbarDisplayMode#" );

				<cfif prc.adminToolbarDisplayMode eq "fixed">
					[ htmlElement, bodyElement ].forEach( function( el ){
						el.style.backgroundPositionY = "calc( " + getComputedStyle( el ).backgroundPositionY + " + var( --adminToolbarHeight ) )";
					} );
				<cfelseif prc.adminToolbarDisplayMode eq "reveal">
					var revealButton = document.querySelector( "##presideAdminToolbarReveal" )
					  , toolbarTimeout;

					revealButton.addEventListener( "click", function( event ){
						event.preventDefault();
						event.stopPropagation();
						toolbarElement.classList.remove( "fade-out", "preside-admin-toolbar-hidden" );
						toolbarElement.classList.add( "fade-in" );

						toolbarTimeout = setTimeout( function() {
							toolbarElement.classList.add( "fade-out" );
							toolbarElement.classList.remove( "fade-in" );
						}, 7500 );
					} );

				</cfif>
			} )();
		</script>

		#ckEditorJs#
	</cfoutput>
</cfif>


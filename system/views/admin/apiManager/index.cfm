<cfscript>
	apis           = prc.apis ?: [];
	configLinkBase = prc.configLinkBase ?: "";
</cfscript>

<cfoutput>
	<cfif apis.len()>
		<cfloop array="#apis#" index="i" item="api">
			<div class="well">
				<h3 class="blue">#api.id#</h3>
				<p><em class="grey">
					<cfif api.description.len()>
						#api.description#
					<cfelse>
						#translateResource( 'cms:apiManager.api.no.description' )#
					</cfif>
				</em></p>
				<p>
					<strong>#translateResource( 'cms:apiManager.authProvider.title' )#</strong>:
					<cfif api.authProvider.len()>
						<a href="#configLinkBase.replace( '{id}', api.id, 'all' )#" title="#HtmlEditFormat( translateResource( 'cms:apiManager.configureauth.link' ) )#">
							<i class="grey fa fa-fw #translateResource( uri='rest.auth.#api.authProvider#:iconClass', defaultValue='fa-users' )#"></i>
							#translateResource( uri='rest.auth.#api.authProvider#:title', defaultValue=api.authProvider )#
						</a>
						<em class="light-grey">#translateResource( 'cms:apiManager.configureauth.link.hint' )#</em>
					<cfelse>
						#translateResource( 'cms:apiManager.authProvider.none' )#
					</cfif>
				</p>
			</div>
		</cfloop>
	<cfelse>
		<p class="alert alert-warning">
			<i class="fa fa-fw fa-exclamation-circle"></i> #translateResource( 'cms:apiManager.no.apis.to.manage' )#
		</p>
	</cfif>
</cfoutput>
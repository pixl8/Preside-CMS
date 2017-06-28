<cfscript>
	apis = prc.apis ?: [];
</cfscript>

<cfoutput>
	<cfif apis.len()>
		<cfsavecontent variable="tabBody">
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
							<i class="grey fa fa-fw #translateResource( uri='rest.auth.#api.authProvider#:iconClass', defaultValue='fa-users' )#"></i>
							#translateResource( uri='rest.auth.#api.authProvider#:title', defaultValue=api.authProvider )#
						<cfelse>
							#translateResource( 'cms:apiManager.authProvider.none' )#
						</cfif>
					</p>
				</div>
			</cfloop>
		</cfsavecontent>

		#renderView(
			  view = "/admin/apiManager/_apiManagerTabs"
			, args = { body=tabBody, tab="apis" }
		)#
	<cfelse>
		<p class="alert alert-warning">
			<i class="fa fa-fw fa-exclamation-circle"></i> #translateResource( 'cms:apiManager.no.apis.to.manage' )#
		</p>
	</cfif>
</cfoutput>
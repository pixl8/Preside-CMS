<cfscript>
	usr     = prc.record ?: {};
	apis    = prc.apis ?: [];
	canEdit = IsTrue( prc.canEdit ?: "" );
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<cfif canEdit>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="apiUserManager.edit", queryString="id=#usr.id#" )#" data-global-key="e">
				<button class="btn btn-success btn-sm">
					<i class="fa fa-pencil"></i>
					#translateResource( "cms:edit.btn" )#
				</button>
			</a>
		</cfif>
	</div>

	<cfif Len( Trim( usr.description ) )>
		<p class="alert alert-info">#HtmlEditFormat( usr.description )#</p>
	</cfif>

	<div class="row">
		<cfif isFeatureEnabled( "restTokenAuth" )>
			<div class="col-md-4">
				<div class="well">
					<h4 class="blue">#translateResource( "apiManager:user.access.token.title" )#</h4>
					<p><code>#usr.access_token#</code></p>
					<cfif canEdit>
						<hr>
						<p class="text-center">
							<a class="btn btn-danger confirmation-prompt" href="#event.buildAdminLink( linkto='apiUserManager.regenerateTokenAction', queryString='id=#usr.id#' )#" title="#HtmlEditFormat( translateResource( "apiManager:user.regenerate.token.prompt" ) )#">
								<i class="fa fa-fw fa-refresh"></i>
								#translateResource( "apiManager:user.regenerate.token.btn" )#
							</a>
						</p>
					</cfif>
				</div>
			</div>
		</cfif>
		<div class="col-md-4">
			<div class="well">
				<h4 class="blue">#translateResource( "apiManager:user.apis.access.title" )#</h4>
				<cfif apis.len()>
					<p><em>#translateResource( "apiManager:user.apis.access.intro" )#</em></p>
					<ul class="list-unstyled">
						<cfloop array="#apis#" item="api" index="i">
							<li><code>#api#</code></li>
						</cfloop>
					</ul>
				<cfelse>
					<p><em>#translateResource( "apiManager:user.has.no.apis" )#</em></p>
				</cfif>
			</div>
		</div>
	</div>

</cfoutput>
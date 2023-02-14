<cfscript>
	loginProviders        = prc.loginProviders    ?: [];
	renderedProviders     = prc.renderedProviders ?: {};
	renderedProviderCount = 0;
</cfscript>

<cfoutput>
	<div class="position-relative">
		<div id="login-box" class="login-box visible widget-box no-border">
			<div class="widget-body">
				<div class="widget-main">
 					<h4 class="cms-brand">
						#translateResource( uri="cms:cms.title" )#
					</h4>

					<cfif renderedProviders.count()>
						<cfloop array="#loginProviders#" index="i" item="provider">
							<cfif StructKeyExists( renderedProviders, provider )>
								<cfif renderedProviderCount gt 0>
									<hr>
								</cfif>
								#renderedProviders[ provider ]#
								<cfset renderedProviderCount++/>
							</cfif>
						</cfloop>
					<cfelse>
						<p class="alert alert-block alert-danger">
							<i class="fa fa-fw fa-exclamation-triangle"></i>
							#translateResource( uri="cms:login.no.providers" )#
						</p>
					</cfif>


				</div><!--/widget-main-->
			</div><!--/widget-body-->
		</div><!--/login-box-->



	</div><!--/position-relative-->
</cfoutput>
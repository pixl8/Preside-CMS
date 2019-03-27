<cfscript>
	params = args.params ?: [];
</cfscript>

<cfoutput>
	<h3 class="header smaller lighter green">#translateResource( "cms:emailcenter.variables.title" )#</h3>
	<cfif !params.len()>
		<p class="alert alert-warning">
			<i class="fa fa-fw fa-exclamation-circle"></i>
			#translateResource( "cms:emailcenter.variables.no.variables" )#
		</p>
	<cfelse>
		<p class="alert alert-info">
			<i class="fa fa-fw fa-info-circle"></i>
			#translateResource( "cms:emailcenter.variables.description" )#
		</p>

		<div class="well">
			<cfloop array="#params#" item="param" index="i">
				<h5 class="lighter">
					<code>${#param.id#}</code>
					<cfif param.required>
						<em class="light-grey">(#translateResource( "cms:emailcenter.variables.required" )#)</em>
					</cfif>
				</h5>
				<p class="grey">#param.description#</p>
				<br>
			</cfloop>
		</div>
	</cfif>
</cfoutput>

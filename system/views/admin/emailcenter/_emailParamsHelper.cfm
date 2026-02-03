<!---@feature admin and emailCenter--->
<cfscript>
	params = args.params ?: [];
	event.include( "/css/admin/specific/emailcenter/emailparams/" );
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

		<div class="email-params well">
			<cfloop array="#params#" item="param" index="i">
				<div class="email-param lighter">
					<span class="email-param-id">${#param.id#}</span>
					<cfif param.required>
						<em class="light-grey">(#translateResource( "cms:emailcenter.variables.required" )#)</em>
					</cfif>
				</div>
				<p class="grey">#param.description#</p>
				<br>
			</cfloop>
		</div>
	</cfif>
</cfoutput>
<!---@feature webflow--->
<cfscript>
	flowLink = Trim( args.flowLink ?: "" );
</cfscript>

<cfoutput>
	<cfif Len( flowLink )>
		<div class="webflow-form-ajax-submit">
			<iframe id="webflowAjax" src="#flowLink#" frameborder="0"></iframe>
		</div>
	<cfelse>
		<div class="alert alert-danger">
			<i class="fa fa-fw fa-exclamation-circle"></i>
			#translateResource( uri="webflow:ajaxLayout.missing.link.error" )#
		</div>
	</cfif>
</cfoutput>
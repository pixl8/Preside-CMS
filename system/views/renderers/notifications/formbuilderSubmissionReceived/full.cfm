<!---@feature formbuilder and admin--->
<cfscript>
	formName = args.formName ?: "";
</cfscript>

<cfoutput>
	<p class="alert alert-info"><i class="fa fa-fw #translateResource( uri="notifications.FormbuilderSubmissionReceived:iconClass" )#"></i> #translateResource( uri="notifications.FormbuilderSubmissionReceived:full.title" , data=[ formName ] )#</p>
</cfoutput>
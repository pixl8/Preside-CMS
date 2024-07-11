<!---@feature admin--->
<cfparam name="args.objectName" />
<cfparam name="args.configForm" />

<cfoutput>
	<form class="form-horizontal export-config-form" data-auto-focus-form="true" method="post" action="" id="export-config-form-#args.objectName#">
		#args.configForm#
	</form>
</cfoutput>
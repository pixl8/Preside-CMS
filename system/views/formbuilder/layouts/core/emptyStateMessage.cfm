<!---@feature formbuilder--->
<cfoutput>
	<div class="alert alert-warning">
		<form action="#event.buildLink( linkTo="formbuilder.core.submitAction" )#" method="post">
			<input type="hidden" name="csrfToken"      value="#event.getCsrfToken()#">
			<input type="hidden" name="form"           value="#( args.form ?: "" )#">
			<input type="hidden" name="formPageNext"   value="0">
			<input type="hidden" name="formPageNumber" value="#( args.formPageNumber ?: 1 )#">

			#translateResource( uri="formbuilder:state.empty.message" )#
		</form>
	</div>
</cfoutput>
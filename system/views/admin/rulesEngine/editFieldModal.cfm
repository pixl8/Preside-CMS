<cfscript>
	configScreen = prc.configScreen ?: "";
	fieldType    = rc.fieldType     ?: "[not supplied]";
</cfscript>

<cfoutput>
	<cfif !Len( Trim( configScreen ) )>
		<p class="alert alert-danger">
			#translateResource( uri="cms:rulesEngine.warning.no.config.form.for.field.type", data=[ fieldType ] )#
		</p>
	<cfelse>
		<form class="form-horizontal edit-field-form" action="#event.buildAdminLink( linkTo='rulesEngine.editFieldModalAction' )#" method="post" enctype="multipart/form-data">
			#configScreen#
		</form>
	</cfif>
</cfoutput>
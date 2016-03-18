<cfparam name="prc.logs" type="query">
<cfoutput>
	<form class="form-horizontal row" action="#event.buildAdminLink( linkTo = "auditTrail.search" )#" method="post">
		<cfif isStruct( prc.filterControl )>
			#prc.filterControl.From#
			#prc.filterControl.To#
		<cfelse>
			#prc.filterControl#
		</cfif>
	</form>
</cfoutput>
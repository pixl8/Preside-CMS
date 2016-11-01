<cfparam name="prc.logs" type="query">
<cfoutput>
	<form class="form-horizontal row" action="#event.buildAdminLink( linkTo = "auditTrail.search" )#" method="post">
			#prc.filterControl#
	</form>
</cfoutput>
<cfparam name="prc.auditTrail" type="query">
<cfscript>
	auditTrailData.Action      = prc.auditTrail.Action;
	auditTrailData.Type        = prc.auditTrail.Type;
	auditTrailData.Detail      = prc.auditTrail.Detail;
	auditTrailData.datecreated = prc.auditTrail.datecreated;
	auditTrailData.id          = prc.auditTrail.id
</cfscript>
<cfoutput>
	<div class="modal-padding-horizontal">
		<h2 class="blue">#translateResource( "cms:auditTrail.logTitle" )#</h2>
		#renderAuditLog( data=auditTrailData, context=auditTrailData.Action )#
	</div>
</cfoutput>
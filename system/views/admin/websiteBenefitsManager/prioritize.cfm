<cfscript>
	benefits = prc.benefits ?: QueryNew('');

	prc.pageIcon     = "sort-amount-asc";
	prc.pageTitle    = translateResource( uri="cms:websiteBenefitsManager.prioritize.title" );

</cfscript>

<cfoutput>
	<cfif benefits.recordCount lt 2>
		<p>#translateResource( uri="cms:websiteBenefitsManager.prioritize.not.enough.benefits" )#</p>
		<div class="form-actions">
			<div>
				<a class="btn btn-sm btn-default" href="#event.buildAdminLink( linkTo="websiteBenefitsManager" )#">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:cancel.btn" )#
				</a>
			</div>
		</div>
	<cfelse>
		<p>#translateResource( uri="cms:websiteBenefitsManager.prioritize.instructions" )#</p>
		<div class="dd" id="sortable-benefits">
			<ol class="dd-list">
				<cfloop query="benefits">
					<li class="dd-item" data-id="#benefits.id#">
						<div class="dd-handle">#benefits.label#</div>
					</li>
				</cfloop>
			</ol>
		</div>

		<form id="reorder-form" data-dirty-form="toggleDisable,protect" action="#event.buildAdminLink( linkTo='websiteBenefitsManager.prioritizeAction' )#" method="post">
			<input type="hidden" value="#ValueList( benefits.id )#" name="benefits" />

			<div class="form-actions">
				<div>
					<a class="btn btn-sm btn-default" href="#event.buildAdminLink( linkTo="websiteBenefitsManager" )#">
						<i class="fa fa-reply bigger-110"></i>
						#translateResource( "cms:cancel.btn" )#
					</a>
					<button id="reset-order-btn" class="btn btn-sm btn-primary" type="submit">
						<i class="fa fa-reply bigger-110"></i>
						#translateResource( "cms:websiteBenefitsManager.prioritize.reset.btn" )#
					</button>
					<button class="btn btn-sm btn-success" type="submit">
						<i class="fa fa-check bigger-110"></i>
						#translateResource( "cms:save.btn" )#
					</button>
				</div>
			</div>
		</form>
	</cfif>
</cfoutput>
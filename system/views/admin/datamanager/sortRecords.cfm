<cfscript>
	object  = rc.object ?: "";
	records = prc.records ?: QueryNew('');
	formId  = "sortForm-" & CreateUUId();
</cfscript>

<cfoutput>
	<div class="dd" id="sortable-records">
		<ol class="dd-list">
			<cfloop query="records">
				<li class="dd-item" data-id="#records.id#">
					<div class="dd-handle">#records.label#</div>
				</li>
			</cfloop>
		</ol>
	</div>

	<form id="reorder-form" data-dirty-form="toggleDisable,protect" action="#event.buildAdminLink( linkTo='datamanager.sortRecordsAction' )#" method="post">
		<input type="hidden" value="#object#" name="object" />
		<input type="hidden" value="#ValueList( records.id )#" name="ordered" />

		<div class="form-actions">
			<div>
				<a id="reset-order-btn" class="btn btn-sm btn-default">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:sitetree.reorderchildren.reset.btn" )#
				</a>
				<button class="btn btn-sm btn-success" type="submit">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:save.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>
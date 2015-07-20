<cfscript>
	object     = rc.object ?: "";
	records    = prc.records ?: QueryNew('');
	formId     = "sortForm-" & CreateUUId();
	cancelLink = event.buildAdminLink( linkTo="datamanager.object", queryString="id=#object#" );
</cfscript>

<cfoutput>
	<cfif !records.recordCount>
		<p class="alert alert-warning">
			<i class="fa fa-fw fa-exclamation-triangle"></i>
			#translateResource( uri="cms:datamanager.noRecordsToSort.error" )#
		</p>
		<div class="form-actions">
			<div>
				<a href="#cancelLink#" class="btn btn-sm btn-danger">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:cancel.btn" )#
				</a>
			</div>
		</div>
	<cfelse>
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
					<a href="#cancelLink#" class="btn btn-sm btn-danger">
						<i class="fa fa-reply bigger-110"></i>
						#translateResource( "cms:cancel.btn" )#
					</a>
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
	</cfif>
</cfoutput>
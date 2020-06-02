<cfscript>
	objectName = "rules_engine_condition";
	contexts   = prc.contexts   ?: [];
	gridFields = prc.gridFields ?: [];
</cfscript>


<cfoutput>
	<div class="top-right-button-group">
		<cfif hasCmsPermission( "rulesEngine.add" )>
			<button data-toggle="dropdown" class="btn btn-sm btn-success pull-right inline">
				<span class="fa fa-caret-down"></span>
				<i class="fa fa-fw fa-plus"></i>&nbsp; #translateResource( 'cms:rulesEngine.add.condition.btn')#
			</button>

			<ul class="dropdown-menu pull-right dropdown-caret dropdown-caret-right" role="menu" aria-labelledby="label">
				<cfloop array="#contexts#" item="context" index="i">
					<li>
						<a href="#event.buildAdminLink( linkTo='rulesEngine.addCondition', queryString='context=' & context.id )#">
							<p class="title"><i class="fa fa-fw #context.iconClass#"></i>&nbsp; #context.title#</p>
							<p class="description"><em class="light-grey">#context.description#</em></p>
						</a>
					</li>
				</cfloop>
			</ul>
		</cfif>
	</div>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = objectName
		, useMultiActions = false
		, datasourceUrl   = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=rulesengine.getConditionsForAjaxDataTables" )
		, gridFields      = gridFields
	} )#
</cfoutput>
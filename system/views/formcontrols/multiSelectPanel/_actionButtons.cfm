<cfscript>
	enableSelectAll   = args.enableSelectAll   ?: true;
	enableDeselectAll = args.enableDeselectAll ?: true;
</cfscript>

<cfoutput>
	<cfif isTrue( enableSelectAll )>
		<button id="select-all-btn" class="btn btn-sm btn-info width-100">
			#translateResource( "formcontrols.multiSelectPanel:btn.selectAll.label" )#
			<i class="bigger-110 fa #translateResource( "formcontrols.multiSelectPanel:btn.selectAll.icon" )#"></i>
		</button>
	</cfif>

	<button id="select-btn" class="btn btn-sm btn-info width-100">
		#translateResource( "formcontrols.multiSelectPanel:btn.select.label" )#
		<i class="bigger-110 fa #translateResource( "formcontrols.multiSelectPanel:btn.select.icon" )#"></i>
	</button>

	<button id="deselect-btn" class="btn btn-sm btn-info width-100">
		<i class="bigger-110 fa #translateResource( "formcontrols.multiSelectPanel:btn.deselect.icon" )#"></i>
		#translateResource( "formcontrols.multiSelectPanel:btn.deselect.label" )#
	</button>

	<cfif isTrue( enableDeselectAll )>
		<button id="deselect-all-btn" class="btn btn-sm btn-info width-100">
			<i class="bigger-110 fa #translateResource( "formcontrols.multiSelectPanel:btn.deselectAll.icon" )#"></i>
			#translateResource( "formcontrols.multiSelectPanel:btn.deselectAll.label" )#
		</button>
	</cfif>
</cfoutput>
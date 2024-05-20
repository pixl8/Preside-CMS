<!---@feature admin--->
<cfoutput>
	<div class="batch-update-select-all">
		<label>
			<input name="batchAll" type="checkbox" class="ace" value="1">
			<span class="lbl"></span>

			#translateResource( uri="cms:datamanager.batch.select.all" )#
		</label>
	</div>
</cfoutput>
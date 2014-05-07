<cfparam name="args.recordId" type="string" />

<cfoutput>
	<label>
		<input name="id" type="checkbox" class="ace" value="#args.recordId#">
		<span class="lbl"></span>
	</label>
</cfoutput>
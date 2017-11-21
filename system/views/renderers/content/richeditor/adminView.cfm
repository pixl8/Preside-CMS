<cfscript>
	rawContent = args.data ?: "";
</cfscript>

<cfoutput>
	<div class="admin-richeditor-preview-container">
		<script type="text/template" class="admin-richeditor-preview-content">#rawContent#</script>
	</div>
</cfoutput>
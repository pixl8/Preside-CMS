<cfscript>
	rawContent = args.data ?: "";
</cfscript>

<cfif Len( Trim( rawContent ) )>
	<div class="admin-richeditor-preview-container">
		<script type="text/template" class="admin-richeditor-preview-content"><cfoutput>#rawContent#</cfoutput></script>
	</div>
</cfif>
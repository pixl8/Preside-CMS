<cfscript>
	ext     = ListLast( args.storage_path ?: "", "." );
	iconUrl = event.buildLink( assetId=args.id ?: "", derivative='pickerIcon' );
</cfscript>

<cfoutput><img src="#iconUrl#" class="icon-derivative" /></cfoutput>
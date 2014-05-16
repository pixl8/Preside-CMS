<cfscript>
	staticRoot = getSetting( name="cfstatic_generated_url", defaultValue="/_assets" );

	event.includeData( { ckeditorConfig = staticRoot & "/ckeditorExtensions/config.js" } );
</cfscript>

<cfoutput>
	<script type="text/javascript" src="#staticRoot#/ckeditor/ckeditor.js"></script>
</cfoutput>
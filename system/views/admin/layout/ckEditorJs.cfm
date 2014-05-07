<cfset staticRoot = getSetting( name="cfstatic_generated_url", defaultValue="/_assets" ) />

<cfoutput>
	<script type="text/javascript" src="#staticRoot#/ckeditor/ckeditor.js"></script>
</cfoutput>
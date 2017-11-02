<cfscript>
	stylesheets = getSetting( name="ckeditor.defaults.stylesheets", defaultValue=[] );
	if ( IsArray( stylesheets ) ) {
		for( var stylesheet in stylesheets ) {
			event.include( stylesheet );
		}
	}

	css         = event.renderIncludes( "css" );
	js          = event.renderIncludes( "js" );
	content     = args.content ?: "";
</cfscript>

<cfoutput><!DOCTYPE html>
<html lang="en" class="richeditor-preview presidecms">
	<head>
		<meta charset="utf-8" />
		<meta name="robots" content="NOINDEX,NOFOLLOW" />
		<meta name="description" content="" />
		<meta name="viewport" content="width=device-width, initial-scale=1.0" />

		#css#
	</head>

	<body>
		#content#
		#js#
	</body>
</html></cfoutput>
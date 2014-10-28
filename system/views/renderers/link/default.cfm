<cfscript>
	param name="args.href"   type="string";
	param name="args.title"  type="string";
	param name="args.body"   type="string";
	param name="args.target" type="string";

	anchorTag = 'href="#args.href#"';

	if ( Len( Trim( args.title ) ) ) {
		anchorTag &= ' title="#args.title#"';
	}
	if ( Len( Trim( args.target ) ) && args.target != "_self" ) {
		anchorTag &= ' target="#args.target#"';
	}
</cfscript>

<cfoutput><a #anchorTag#>#args.body#</a></cfoutput>
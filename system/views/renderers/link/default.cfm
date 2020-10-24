<cfscript>
	param name="args.href"     type="string"  default="";
	param name="args.title"    type="string"  default="";
	param name="args.body"     type="string"  default="";
	param name="args.target"   type="string"  default="";
	param name="args.style"    type="string"  default="";
	param name="args.class"    type="string"  default="";
	param name="args.nofollow" type="boolean" default=false;
	param name="args.referrer_policy" type="string"  default="";

	anchorTag = 'href="#args.href#"';

	if ( Len( Trim( args.title ) ) ) {
		anchorTag &= ' title="#args.title#"';
	}
	if ( Len( Trim( args.class ) ) ) {
		anchorTag &= ' class="#args.class#"';
	}
	if ( Len( Trim( args.style ) ) ) {
		anchorTag &= ' style="#args.style#"';
	}
	if ( Len( Trim( args.target ) ) && args.target != "_self" ) {
		anchorTag &= ' target="#args.target#"';
	}
	if ( args.noFollow ) {
		anchorTag &= ' rel="nofollow"';
	}
	if ( Len( Trim( args.referrer_policy ) ) ) {
		anchorTag &= ' referrerpolicy="#args.referrer_policy#"';
	}
</cfscript>

<cfoutput><a #anchorTag#>#args.body#</a></cfoutput>
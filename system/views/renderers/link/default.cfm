<cfscript>
	param name="args.href"     type="string"  default="";
	param name="args.title"    type="string"  default="";
	param name="args.body"     type="string"  default="";
	param name="args.target"   type="string"  default="";
	param name="args.style"    type="string"  default="";
	param name="args.class"    type="string"  default="";
	param name="args.nofollow" type="boolean" default=false;
	param name="args.referrer_policy" type="string"  default="";
	param name="args.role"            type="string"  default="";
	param name="args.ariaLabel"       type="string"  default="";
	param name="args.ariaLabelledby"  type="string"  default="";
	param name="args.ariaDescribedby" type="string"  default="";
	param name="args.ariaHidden"      type="boolean" default=false;
	param name="args.download"        type="boolean" default=false;

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
	if ( Len( Trim( args.role ) ) ) {
		anchorTag &= ' role="#args.role#"';
	}
	if ( Len( Trim( args.ariaLabel ) ) ) {
		anchorTag &= ' aria-label="#args.ariaLabel#"';
	}
	if ( Len( Trim( args.ariaLabelledby ) ) ) {
		anchorTag &= ' aria-labelledby="#args.ariaLabelledby#"';
	}
	if ( Len( Trim( args.ariaDescribedby ) ) ) {
		anchorTag &= ' aria-describedby="#args.ariaDescribedby#"';
	}
	if ( args.ariaHidden ) {
		anchorTag &= ' aria-hidden="true"';
	}
	if ( isTrue( args.download ) ) {
		anchorTag &= ' download';
	}
</cfscript>

<cfoutput><a #anchorTag#>#args.body#</a></cfoutput>
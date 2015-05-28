<cfscript>
	imgSrc     = event.buildLink( ( assetId=args.id ?: "" ), derivative=( args.derivative ?: "" ) );
	altText    = HtmlEditFormat( Len( Trim( args.alt_text ?: '' ) ) ? args.alt_text : ( args.label ?: '' ) );
	style      = ListFindNoCase( "left,right", args.alignment ?: "" ) ? "float:#LCase( args.alignment )#;" : "";
	hasFigure  = Len( Trim( args.copyright ?: "" ) ) || Len( Trim( args.caption ?: "" ) );
	hasLink    = Len( Trim( args.link ?: "" ) );

	if ( IsNumeric( args.spacing ?: "" ) ) {
		style &= "margin:#Trim(args.spacing)#px;";

		switch( args.alignment ?: "" ) {
			case "left"   : style &= "margin-left:0;"; break;
			case "right"  : style &= "margin-right:0;"; break;
			case "center" : style &= "margin:0 auto; display:block;text-align:center"; break;
			default       : style &= "margin-left:0;margin-right:0;"; break;
		}
	}
</cfscript>

<cfoutput>
	<cfif hasFigure>
		<figure style="#style#">
	</cfif>

	<cfif hasLink>
		<a href="#Trim( args.link )#" target="#( args.link_target ?: '_self' )#"<cfif !hasFigure> style="display:block;#style#"</cfif>>
	</cfif>

	<img src="#imgSrc#" alt="#altText#"<cfif !hasFigure && !hasLink> style="#style#"</cfif> />

	<cfif hasLink>
		</a>
	</cfif>

	<cfif hasFigure>
			<figcaption>
				<cfif Len( Trim( args.copyright ?: "" ) )>
					<small class="copyright">&copy; #args.copyright#</small>
				</cfif>
				<cfif Len( Trim( args.caption ?: "" ) )>
					#renderContent( data=args.caption, renderer="richeditor" )#
				</cfif>
			</figcaption>
		</figure>
	</cfif>
</cfoutput>
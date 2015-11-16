<cfscript>
	imgSrc        = event.buildLink( ( assetId=args.id ?: "" ), derivative=( args.derivative ?: "" ) );
	altText       = HtmlEditFormat( Len( Trim( args.alt_text ?: '' ) ) ? args.alt_text : ( args.label ?: '' ) );
	style         = ListFindNoCase( "left,right", args.alignment ?: "" ) ? "float:#LCase( args.alignment )#;" : "";
	hasFigure     = Len( Trim( args.copyright ?: "" ) ) || Len( Trim( args.caption ?: "" ) );
	hasLink       = Len( Trim( args.link ?: ""  ) ) ;

	if( Len( Trim( args.link_asset ?: "" ) )){
		args.link  = event.buildLink(  assetId=args.link_asset );
		hasLink       = Len( Trim( args.link ?: ""  ) ) ;
	}
	if( Len( Trim( args.link_page ?: ""  ) )){
		args.link  = event.buildLink(  page=args.link_page );
		hasLink       = Len( Trim( args.link ?: ""  ) ) ;
	}


	spacing = {
		  top    = Val( args.spacing_top    ?: ( args.spacing ?: 0 ) )
		, right  = Val( args.spacing_right  ?: ( args.spacing ?: 0 ) )
		, bottom = Val( args.spacing_bottom ?: ( args.spacing ?: 0 ) )
		, left   = Val( args.spacing_left   ?: ( args.spacing ?: 0 ) )
	};

	if ( args.alignment == "center" ) {
		style = "margin:#Trim(spacing.top)#px auto #Trim(spacing.bottom)#px auto; display:block;text-align:center";
	} else {
		style &= "margin:#Trim(spacing.top)#px #Trim(spacing.right)#px #Trim(spacing.bottom)#px #Trim(spacing.left)#px;";
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
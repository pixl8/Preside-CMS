<cfparam name="args.embargo_date" />
<cfparam name="args.expiry_date"  />
<cfparam name="args.active"       />
<cfparam name="args.is_draft"     />
<cfparam name="args.has_drafts"   />

<cfscript>
	usesDateRestrictions = IsDate( args.embargo_date ) || IsDate( args.expiry_date );
	isDraft              = IsTrue( args.is_draft );
	hasDrafts            = IsTrue( args.has_drafts );

	statusText   = translateResource( "cms:sitetree.page.status.published" )
	statusIcon   = "check-circle";
	statusColour = "green";

	if ( isDraft ) {
		statusText   = translateResource( "cms:sitetree.page.status.draft" );
		statusIcon   = "edit";
		statusColour = "light-grey";
	} else {
		if ( IsFalse( args.active ) ) {
			statusIcon   = "times-circle";
			statusColour = "red";
			statusText   = translateResource( "cms:sitetree.page.status.inactive" );
		} else if ( usesDateRestrictions ) {
			statusIcon = "clock-o";

			if ( IsDate( args.embargo_date ) && args.embargo_date > Now() ) {
				statusColour = "red";
				statusText   = translateResource( "cms:sitetree.page.status.embargoed" );
			} else if ( IsDate( args.expiry_date ) && args.expiry_date < Now() ) {
				statusColour = "red";
				statusText   = translateResource( "cms:sitetree.page.status.expired" );
			} else {
				statusColour = "green";
			}
		}

		if ( hasDrafts ) {
			statusText &= " &nbsp; <em class=""light-grey"">#translateResource( "cms:sitetree.page.status.has.drafts" )#</em>";
		}
	}
</cfscript>

<cfoutput>
	<i class="fa fa-fw fa-#statusIcon# #statusColour#"></i>
	#statusText#
</cfoutput>
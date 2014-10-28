<cfscript>
	public numeric function calculateTagCloudWeighting( required numeric tagCount, required numeric maxTags, required numeric maxTagRange, required numeric minTagRange ) output=false {
		return round( ( arguments.tagCount / arguments.maxTags ) * ( arguments.maxTagRange - arguments.minTagRange ) + arguments.minTagRange );
	}
</cfscript>

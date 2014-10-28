<cfscript>
	public boolean function isTrue( required any someValue ) output=false {
		return IsBoolean( arguments.someValue ) && arguments.someValue;
	}

	public boolean function isFalse( required any someValue ) output=false {
		return !IsBoolean( arguments.someValue ) || !arguments.someValue;
	}
</cfscript>
<cfscript>
	public boolean function isTrue( any someValue ) output=false {
		return IsBoolean( arguments.someValue ) && arguments.someValue;
	}

	public boolean function isFalse( any someValue ) output=false {
		return !IsBoolean( arguments.someValue ) || !arguments.someValue;
	}
</cfscript>
component output=false validationProvider=true {

	public boolean function required( required string fieldName, string value="", struct data={} ) output=false validatorMessage="cms:validation.required.default" {
		return StructKeyExists( arguments.data, fieldName ) and Len( Trim( value ) );
	}

	public boolean function minlength( required string fieldName, string value="", required numeric length, boolean list=false ) output=false validatorMessage="cms:validation.minLength.default" {
		var length = arguments.list ? ListLen( Trim( arguments.value ) ) : Len( Trim( arguments.value ) );

		return not length or length gte arguments.length;
	}

	public boolean function maxlength( required string fieldName, string value="", required numeric length, boolean list=false ) output=false validatorMessage="cms:validation.maxLength.default" {
		var length = arguments.list ? ListLen( Trim( arguments.value ) ) : Len( Trim( arguments.value ) );

		return not length or length lte arguments.length;
	}

	public boolean function rangelength( required string fieldname, string value="", required numeric minLength, required numeric maxLength, boolean list=false ) output=false validatorMessage="cms:validation.rangeLength.default" {
		var length = arguments.list ? ListLen( Trim( arguments.value ) ) : Len( Trim( arguments.value ) );

		return not length or ( length gte arguments.minLength and length lte arguments.maxLength );
	}

	public boolean function min( required string fieldName, string value="", required numeric min ) output=false validatorMessage="cms:validation.min.default" {
		if ( not Len( Trim( arguments.value ) ) ) {
			return true;
		}

		return Val( arguments.value ) gte arguments.min;
	}

	public boolean function max( required string fieldName, string value="", required numeric max ) output=false validatorMessage="cms:validation.max.default" {
		if ( not Len( Trim( arguments.value ) ) ) {
			return true;
		}

		return Val( arguments.value ) lte arguments.max;
	}

	public boolean function range( required string fieldName, string value="", required numeric min, required numeric max ) output=false validatorMessage="cms:validation.range.default" {
		if ( not Len( Trim( arguments.value ) ) ) {
			return true;
		}

		return Val( arguments.value ) lte arguments.max and Val( arguments.value ) gte arguments.min;
	}

	public boolean function number( required string value ) output=false validatorMessage="cms:validation.number.default" {
		if ( not Len( Trim( arguments.value ) ) ) {
			return true;
		}
		return IsNumeric( arguments.value );
	}

	public boolean function digits( required string value ) output=false validatorMessage="cms:validation.digits.default" {
		if ( not Len( Trim( arguments.value ) ) ) {
			return true;
		}
		return ReFind( "^[0-9]+$", arguments.value );
	}

	public boolean function date( required string value ) output=false validatorMessage="cms:validation.date.default" {
		if ( not Len( Trim( arguments.value ) ) ) {
			return true;
		}

		return IsDate( arguments.value );
	}

	public boolean function match( required string fieldName, string value="", required string regex ) output=false validatorMessage="cms:validation.match.default" {
		if ( not Len( Trim( arguments.value ) ) ) {
			return true;
		}

		return ReFind( arguments.regex, arguments.value );
	}
	public string function match_js() output=false {
		return "function( value, el, params ){ return !value.length || value.match( new RegExp( params[0] ) ) !== null }";
	}

	public boolean function sameAs( required string fieldName, string value="", required struct data, required string field ) output=false validatorMessage="cms:validation.sameAs.default" {
		return arguments.value == ( arguments.data[ field ] ?: "" );
	}
	public string function sameAs_js() output=false {
		return "function( value, el, params ){ var $field = $( this.form ).find( '[name=' + params[0] + ']' ); return $field.length && value == $field.val(); }";
	}

	public boolean function slug( required string fieldName, string value="" ) output=false validatorMessage="cms:validation.slug.default" {
		return match( fieldName=arguments.fieldName, value=arguments.value, regex="^[a-z0-9\-]+$" );
	}
	public string function slug_js() output=false {
		return "function( value ){ return !value.length || value.match( /^[a-z0-9\-]+$/ ) !== null }";
	}
}
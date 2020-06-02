/**
 *
 * REST User for authenticated access to REST APIs
 *
 * @feature    apiManager
 * @versioned  false
 * @labelfield name
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="name"         type="string" dbtype="varchar" required=true  maxlength=100 uniqueindexes="username";
	property name="access_token" type="string" dbtype="varchar" required=true  maxlength=32  uniqueindexes="token" generate="insert" generator="method:generateToken";
	property name="description"  type="string" dbtype="text"    required=false;

	public string function generateToken() {
		var chars       = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789=";
		var token       = "";
		var charsLength = chars.len();

		do {
			token &= chars[ RandRange( 1, charsLength ) ];
		} while( token.len() < 32 )

		return token;
	}
}
component extends="preside.system.base.AdminHandler" {

	property name="languageDao" inject="presidecms:object:multilingual_language";

	public void function getLanguagesForAjaxPicker( event, rc, prc ) {
		var languages = languageDao.selectData();
		var preparedLanguages = [];

		for( var language in languages ) {
			preparedLanguages.append({
				  value = language.id
				, text = translateResource( uri="languages:#language.iso_code#", data=[language.native_name], defaultValue=language.name & " [#language.native_name#]" )
			});
		}

		if ( !IsEmpty( rc.q ?: "" ) ) {
			preparedLanguages = preparedLanguages.filter( function( language ){
				return language.text.findNoCase( rc.q );
			} );
		}

		if ( !IsEmpty( rc.values ?: "" ) ) {
			preparedLanguages = preparedLanguages.filter( function( language ){
				return rc.values.listFindNoCase( language.value );
			} );
		}

		preparedLanguages.sort( function( a, b ){
			return a.text > b.text ? 1 : -1;
		} );

		event.renderData( type="json", data=preparedLanguages );
	}
}
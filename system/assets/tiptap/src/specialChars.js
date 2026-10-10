/**
 * Special-character DATA — CKEditor's own default list and character names.
 *
 * Split out from the dialog (src/specialChar.js) because this is a verbatim
 * transcription, not logic:
 *
 *   CHARS  = CKEDITOR.config.specialChars, byte-for-byte (ckeditor.js), so a
 *            field that overrides `specialChars` starts from the same baseline
 *            CKEditor did. Kept as the ENTITY strings CKEditor listed - the
 *            dialog decodes them for display and insertion, and shows the raw
 *            string in its HTML preview pane exactly as CKEditor's dialog did.
 *            Two entries in CKEditor's default (`&#374`, `&#373`) are missing
 *            their semicolon upstream; they are preserved as-is because the HTML
 *            parser decodes them anyway, so the list stays a faithful copy.
 *
 *   NAMES  = plugins/specialchar/dialogs/lang/en.js, keyed the way CKEditor
 *            keyed it (the entity with `&`, `;` and `#` stripped).
 *
 * The per-character NAMES are data, not editor chrome: CKEditor shipped them in
 * its own dialog language packs, which is not a Preside resource bundle, and
 * putting ~110 tooltip strings through cfrequest.tiptapI18n would grow every
 * admin page's payload for text only ever seen on hover. They stay English here,
 * and src/specialChar.js still consults i18n first (a site can override an
 * individual name via window.PresideTiptapI18n["specialchar.char.<key>"]).
 */

// CKEDITOR.config.specialChars — space separated, in CKEditor's own order.
export const CHARS = (
	  "! &quot; # $ % &amp; ' ( ) * + - . / 0 1 2 3 4 5 6 7 8 9 : ; &lt; = &gt; ? @ "
	+ "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z [ ] ^ _ ` "
	+ "a b c d e f g h i j k l m n o p q r s t u v w x y z { | } ~ "
	+ "&euro; &lsquo; &rsquo; &ldquo; &rdquo; &ndash; &mdash; &iexcl; &cent; &pound; "
	+ "&curren; &yen; &brvbar; &sect; &uml; &copy; &ordf; &laquo; &not; &reg; &macr; "
	+ "&deg; &sup2; &sup3; &acute; &micro; &para; &middot; &cedil; &sup1; &ordm; "
	+ "&raquo; &frac14; &frac12; &frac34; &iquest; &Agrave; &Aacute; &Acirc; &Atilde; "
	+ "&Auml; &Aring; &AElig; &Ccedil; &Egrave; &Eacute; &Ecirc; &Euml; &Igrave; "
	+ "&Iacute; &Icirc; &Iuml; &ETH; &Ntilde; &Ograve; &Oacute; &Ocirc; &Otilde; "
	+ "&Ouml; &times; &Oslash; &Ugrave; &Uacute; &Ucirc; &Uuml; &Yacute; &THORN; "
	+ "&szlig; &agrave; &aacute; &acirc; &atilde; &auml; &aring; &aelig; &ccedil; "
	+ "&egrave; &eacute; &ecirc; &euml; &igrave; &iacute; &icirc; &iuml; &eth; "
	+ "&ntilde; &ograve; &oacute; &ocirc; &otilde; &ouml; &divide; &oslash; &ugrave; "
	+ "&uacute; &ucirc; &uuml; &yacute; &thorn; &yuml; &OElig; &oelig; &#372; &#374 "
	+ "&#373 &#375; &sbquo; &#8219; &bdquo; &hellip; &trade; &#9658; &bull; &rarr; "
	+ "&rArr; &hArr; &diams; &asymp;"
).split( " " );

// CKEditor's dialog lang pack (English). Key = entity minus "&", ";" and "#".
export const NAMES = {
	  euro  : "Euro sign"
	, lsquo : "Left single quotation mark"
	, rsquo : "Right single quotation mark"
	, ldquo : "Left double quotation mark"
	, rdquo : "Right double quotation mark"
	, ndash : "En dash"
	, mdash : "Em dash"
	, iexcl : "Inverted exclamation mark"
	, cent  : "Cent sign"
	, pound : "Pound sign"
	, curren: "Currency sign"
	, yen   : "Yen sign"
	, brvbar: "Broken bar"
	, sect  : "Section sign"
	, uml   : "Diaeresis"
	, copy  : "Copyright sign"
	, ordf  : "Feminine ordinal indicator"
	, laquo : "Left-pointing double angle quotation mark"
	, not   : "Not sign"
	, reg   : "Registered sign"
	, macr  : "Macron"
	, deg   : "Degree sign"
	, sup2  : "Superscript two"
	, sup3  : "Superscript three"
	, acute : "Acute accent"
	, micro : "Micro sign"
	, para  : "Pilcrow sign"
	, middot: "Middle dot"
	, cedil : "Cedilla"
	, sup1  : "Superscript one"
	, ordm  : "Masculine ordinal indicator"
	, raquo : "Right-pointing double angle quotation mark"
	, frac14: "Vulgar fraction one quarter"
	, frac12: "Vulgar fraction one half"
	, frac34: "Vulgar fraction three quarters"
	, iquest: "Inverted question mark"
	, Agrave: "Latin capital letter A with grave accent"
	, Aacute: "Latin capital letter A with acute accent"
	, Acirc : "Latin capital letter A with circumflex"
	, Atilde: "Latin capital letter A with tilde"
	, Auml  : "Latin capital letter A with diaeresis"
	, Aring : "Latin capital letter A with ring above"
	, AElig : "Latin capital letter Æ"
	, Ccedil: "Latin capital letter C with cedilla"
	, Egrave: "Latin capital letter E with grave accent"
	, Eacute: "Latin capital letter E with acute accent"
	, Ecirc : "Latin capital letter E with circumflex"
	, Euml  : "Latin capital letter E with diaeresis"
	, Igrave: "Latin capital letter I with grave accent"
	, Iacute: "Latin capital letter I with acute accent"
	, Icirc : "Latin capital letter I with circumflex"
	, Iuml  : "Latin capital letter I with diaeresis"
	, ETH   : "Latin capital letter Eth"
	, Ntilde: "Latin capital letter N with tilde"
	, Ograve: "Latin capital letter O with grave accent"
	, Oacute: "Latin capital letter O with acute accent"
	, Ocirc : "Latin capital letter O with circumflex"
	, Otilde: "Latin capital letter O with tilde"
	, Ouml  : "Latin capital letter O with diaeresis"
	, times : "Multiplication sign"
	, Oslash: "Latin capital letter O with stroke"
	, Ugrave: "Latin capital letter U with grave accent"
	, Uacute: "Latin capital letter U with acute accent"
	, Ucirc : "Latin capital letter U with circumflex"
	, Uuml  : "Latin capital letter U with diaeresis"
	, Yacute: "Latin capital letter Y with acute accent"
	, THORN : "Latin capital letter Thorn"
	, szlig : "Latin small letter sharp s"
	, agrave: "Latin small letter a with grave accent"
	, aacute: "Latin small letter a with acute accent"
	, acirc : "Latin small letter a with circumflex"
	, atilde: "Latin small letter a with tilde"
	, auml  : "Latin small letter a with diaeresis"
	, aring : "Latin small letter a with ring above"
	, aelig : "Latin small letter æ"
	, ccedil: "Latin small letter c with cedilla"
	, egrave: "Latin small letter e with grave accent"
	, eacute: "Latin small letter e with acute accent"
	, ecirc : "Latin small letter e with circumflex"
	, euml  : "Latin small letter e with diaeresis"
	, igrave: "Latin small letter i with grave accent"
	, iacute: "Latin small letter i with acute accent"
	, icirc : "Latin small letter i with circumflex"
	, iuml  : "Latin small letter i with diaeresis"
	, eth   : "Latin small letter eth"
	, ntilde: "Latin small letter n with tilde"
	, ograve: "Latin small letter o with grave accent"
	, oacute: "Latin small letter o with acute accent"
	, ocirc : "Latin small letter o with circumflex"
	, otilde: "Latin small letter o with tilde"
	, ouml  : "Latin small letter o with diaeresis"
	, divide: "Division sign"
	, oslash: "Latin small letter o with stroke"
	, ugrave: "Latin small letter u with grave accent"
	, uacute: "Latin small letter u with acute accent"
	, ucirc : "Latin small letter u with circumflex"
	, uuml  : "Latin small letter u with diaeresis"
	, yacute: "Latin small letter y with acute accent"
	, thorn : "Latin small letter thorn"
	, yuml  : "Latin small letter y with diaeresis"
	, OElig : "Latin capital ligature OE"
	, oelig : "Latin small ligature oe"
	, 372   : "Latin capital letter W with circumflex"
	, 374   : "Latin capital letter Y with circumflex"
	, 373   : "Latin small letter w with circumflex"
	, 375   : "Latin small letter y with circumflex"
	, sbquo : "Single low-9 quotation mark"
	, 8219  : "Single high-reversed-9 quotation mark"
	, bdquo : "Double low-9 quotation mark"
	, hellip: "Horizontal ellipsis"
	, trade : "Trade mark sign"
	, 9658  : "Black right-pointing pointer"
	, bull  : "Bullet"
	, rarr  : "Rightwards arrow"
	, rArr  : "Rightwards double arrow"
	, hArr  : "Left right double arrow"
	, diams : "Black diamond suit"
	, asymp : "Almost equal to"
};

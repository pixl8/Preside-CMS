Richeditor: image form
======================

*/forms/richeditor/image.xml*

This form is used for the add/edit image screen in the richeditor.

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="main" sortorder="10" title="cms:ckeditor.imagepicker.main.tab">
            <fieldset id="main" sortorder="10">
                <field sortorder="10" name="asset"       control="assetPicker"     required="true"  label="cms:ckeditor.imagepicker.asset.label" allowedTypes="image" />
                <field sortorder="20" name="alt_text"    control="textinput"       required="false" label="cms:ckeditor.imagepicker.alt_text.label" maxLength="200" />
                <field sortorder="30" name="dimensions"  control="imagedimensions" required="true"  label="cms:ckeditor.imagepicker.dimensions.label" />
                <field sortorder="40" name="quality"     control="select"  required="true"  label="cms:ckeditor.imagepicker.quality.label"   values="highestQuality,highQuality,mediumQuality,highestPerformance,highPerformance,mediumPerformance" labels="cms:ckeditor.imagepicker.quality.highestQuality,cms:ckeditor.imagepicker.quality.highQuality,cms:ckeditor.imagepicker.quality.mediumQuality,cms:ckeditor.imagepicker.quality.highestPerformance,cms:ckeditor.imagepicker.quality.highPerformance,cms:ckeditor.imagepicker.quality.mediumPerformance" />
                <field sortorder="50" name="alignment"   control="select"  required="false" label="cms:ckeditor.imagepicker.alignment.label" values="auto,left,right" labels="cms:ckeditor.imagepicker.alignment.auto,cms:ckeditor.imagepicker.alignment.left,cms:ckeditor.imagepicker.alignment.right" />
                <field sortorder="60" name="spacing"     control="spinner" required="false" label="cms:ckeditor.imagepicker.spacing.label" default="5" />
            </fieldset>
        </tab>
        <tab id="caption" sortorder="20" title="cms:ckeditor.imagepicker.caption.tab">
            <fieldset id="caption" sortorder="10">
                <field sortorder="10" name="copyright" control="textinput"   required="false"  label="cms:ckeditor.imagepicker.copyright.label" maxLength="600" />
                <field sortorder="20" name="caption"   control="richeditor"  required="false"  label="cms:ckeditor.imagepicker.caption.label" toolbar="noInserts" />
            </fieldset>
        </tab>
        <tab id="link" sortorder="30" title="cms:ckeditor.imagepicker.link.tab">
            <fieldset id="link" sortorder="10">
                <field sortorder="10" name="link" control="textinput" required="false" label="cms:ckeditor.imagepicker.link.label" maxLength="500" />
                <field sortorder="20" name="link_target" control="select" required="false" label="cms:ckeditor.imagepicker.link_target.label" values="_self,_blank,_parent,_top" />
            </fieldset>
        </tab>
    </form>


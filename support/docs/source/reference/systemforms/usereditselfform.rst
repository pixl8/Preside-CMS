User: edit self form
====================

*/forms/preside-objects/security_user/admin.edit.self.xml*

This form is used for the "edit user" form in the user admin section of the administrator **when the user being edited is the same as the logged in user**.

.. note::

	This form gets mixed in with :doc:`usereditform`. Its purpose is to remove the "active" flag control, preventing the user from deactivating themselves (the service layer also prevents this).

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="basic">
            <fieldset id="basic">
                <field name="active" deleted="true" />
            </fieldset>
        </tab>
    </form>


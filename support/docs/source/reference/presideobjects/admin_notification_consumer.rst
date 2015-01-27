Notification consumer
=====================

Overview
--------

The notification consumer object is used to store details of a single user's interactions with a notification

**Object name:**
    admin_notification_consumer

**Table name:**
    psys_admin_notification_consumer

**Path:**
    /preside-objects/admin/notifications/admin_notification_consumer.cfc

Properties
----------

.. code-block:: java

    property name="admin_notification" relationship="many-to-one" required=true uniqueindexes="notificationUser|1" ondelete="cascade";
    property name="security_user"      relationship="many-to-one" required=true uniqueindexes="notificationUser|2" ondelete="cascade";

    property name="read" type="boolean" dbtype="boolean" required=false default=false indexes="read";
# fn-dhis2
This is an adapter for DHIS2, intended to be used with OpenFn, but built to stand alone. This adapter will allow users to insert data values to a DHIS2 system using JSON from OpenFn's core and the DHIS2 WebApi.

DHIS2
-----------------
DHIS 2 is a tool for collection, validation, analysis, and presentation of aggregate statistical data, tailored (but not limited) to integrated health information management activities. It is a generic tool rather than a pre-configured database application, with an open meta-data model and a flexible user interface that allows the user to design the contents of a specific information system without the need for programming. For this reason, the schema of every DHIS2 system, including the important `data elements` and `data sets` will be different.

This adapter
----------------------
Use [fn-salesforce](https://github.com/OpenFn/fn-salesforce) as a boilerplate for this `fn-dhis2` adapter.
fn-dhis2 should abide by the same API calls:

1. fn-describe (takes `credentials.json` and an object name, returns a destination schema in the form of [JSON-schema](JSON-schema.org))
2. fn-prepare (takes a `destination_payload` from `open-mapper` and a destination schema, and returns a `plan` which can be directly loaded into DHIS2.)
3. fn-push (takes a `plan` and `credentials.json`, inserts data values into DHIS2)

these basic actions are defined in [fn-salesforce/lib/salesforce.rb](https://github.com/OpenFn/fn-salesforce/blob/master/lib/fn/salesforce.rb))

Objectives
-----------------------------------
1. Given `payload1_aggregate.json`, create a new `dataset` with new `data values`.
2. Given `payload2_individual_tracker.json`, create new `data values`.
3. Given `payload3_event_with_attendees.json`, create a new `event` with participant registration data.

n.b.: "A data value set represents a set of data values which have a logical relationship, usually from being captured off the same data entry form."


Stu's Thoughts:
-------------------
1. Start with "fn-push" given some JSON, try to insert in DHIS2 using the webAPI.
2. Then with "fn-describe" fetch JSON scema for a given object in DHIS2.
3. Finally, "fn-prepare" flattens the `destination_payload.json` and maps the dependencies (if necessary) so the output is ready to be inserted piece by piece to DHIS2.

Resources
----------------------
[DHIS2 Glossary](https://www.dhis2.org/doc/snapshot/en/user/html/go01.html)

1. [DHIS2 data-values api](https://www.dhis2.org/doc/snapshot/en/developer/html/ch01s11.html);
2. [DHIS2 events api](https://www.dhis2.org/doc/snapshot/en/developer/html/ch01s13.html)
3. [DHIS2 metadata api](https://www.dhis2.org/doc/snapshot/en/developer/html/ch01s06.html): this is needed to fetch JSON-schema compliant schemas for objects that we plan to create or update. Works similar to the "describe" method

[DHIS2 as a "tracker" system with individual beneficiaries](https://www.dhis2.org/individual-data-records) - explains objective #3.
[How adding data to the tracker works!](https://www.npmjs.com/package/dhis2-tracker-populator)

See DHIS2 in action!
--------------------
1. [live hosted DHIS2 demo](https://apps.dhis2.org/demo/dhis-web-dashboard-integration/index.action): un=admin,pw=district;
2. View, create, and edit [data elements](https://apps.dhis2.org/demo/dhis-web-maintenance-datadictionary/dataElement.action) in a DHIS2 demo system
3. View, create, and edit [data sets](https://apps.dhis2.org/demo/dhis-web-maintenance-dataset/dataSet.action) in a DHIS2 demo system. 

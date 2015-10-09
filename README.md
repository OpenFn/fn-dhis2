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
2. fn-prepare (takes a `raw_destination_payload` from `open-mapper` and a destination schema, and returns a `destination_payload` (formerly called `plan`) which can be directly loaded into DHIS2.)
3. fn-push (takes a `destination_payload.json` and `credentials.json`, inserts data values into DHIS2)

these basic actions are defined in [fn-salesforce/lib/salesforce.rb](https://github.com/OpenFn/fn-salesforce/blob/master/lib/fn/salesforce.rb))

Stu's Thoughts:
-------------------
1. Start with "fn-push" given some JSON, try to insert in DHIS2 using the webAPI.
2. Then with "fn-describe" fetch JSON scema for a given object in DHIS2.
3. Finally, "fn-prepare" flattens the `raw_destination_payload.json` and maps the dependencies (if necessary) so the output is ready to be inserted piece by piece to DHIS2.

Resources
----------------------
[DHIS2 Glossary](https://www.dhis2.org/doc/snapshot/en/user/html/go01.html)

1. [DHIS2 data-values api](https://www.dhis2.org/doc/snapshot/en/developer/html/ch01s11.html);
2. [DHIS2 events api](https://www.dhis2.org/doc/snapshot/en/developer/html/ch01s13.html)
3. [DHIS2 metadata api](https://www.dhis2.org/doc/snapshot/en/developer/html/ch01s06.html): this is needed to fetch JSON-schema compliant schemas for objects that we plan to create or update. Works similar to the "describe" method

4. [DHIS2 as a "tracker" system with individual beneficiaries](https://www.dhis2.org/individual-data-records) - explains objective #3.
5. [DHIS2 tracker documentation](https://www.dhis2.org/doc/snapshot/en/user/html/ch29.html)
6. [How adding data to the tracker works!](https://www.npmjs.com/package/dhis2-tracker-populator)
7. [Tracked entity instance management](https://www.dhis2.org/doc/snapshot/en/user/html/ch30s34.html) - this is how DHIS2 handles individuals.

Open-source integrations to DHIS2 from Json Xform data:
----------------------------------------------------------
[How CommCare integrates to DHIS2](http://commcare-hq.readthedocs.org/en/latest/dhis2_integration.html#implementation)
=> [Source for CommCare-DHIS2 integration](https://github.com/dimagi/commcare-hq/tree/ea85d66706068ffcc8d7440f061df3b30d2aeb1f/custom/dhis2)

See DHIS2 in action!
--------------------
1. [live hosted DHIS2 demo](https://apps.dhis2.org/demo/dhis-web-dashboard-integration/index.action): un=admin,pw=district;
2. View, create, and edit [data elements](https://apps.dhis2.org/demo/dhis-web-maintenance-datadictionary/dataElement.action) in a DHIS2 demo system
3. View, create, and edit [data sets](https://apps.dhis2.org/demo/dhis-web-maintenance-dataset/dataSet.action) in a DHIS2 demo system. 

Prototype
---------

The prototype can be run using 
```
./prototype/prototype.rb
```

The prototype was intended as a proof of concept / testbed for interactions between an external system and DHIS2, using the pattern employed by fn-salesforce.

It contains really crude code intended to validate some expected use cases and also to start to identify common areas between the use cases - so that we can start collapsing the code. There are four classes - each class maps to a use case, and, in the case of AggregatedEvent, some reuse of existing classes takes place.

The classes expose three methods - .describe, .prepare and .push (functionality as per the `This adapter` section above): For every case, except AggregatedEvent, .describe and .prepare are mostly there for preserving the interface. AggregatedEvent has, however, proved to be complex enough to benefit from the describe/prepare model (ironically enough - neither of these endpoints have been written in the prototype yet).

Most of the effort spent in writing the prototype has been getting to grips with the nuances of DHIS 2. In terms of coding time, I would estimate it represents an hour or two's worth of effort at most - the rest of the time was spent exploring the DHIS 2 api and domain. The last item of difficulty that remains would be to start abstracting components of the individual use cases - but that is out of scope for the prototype.

Next Steps
----------

The next step woudl be to start building production-ready code extending out of the rudimentary proofs found in the prototype code. What the prototype does not attemp to do is provide unified describe, prepare and push endpoints that can address all four use cases and more.This is, admittedly,  not trivial but, based on the results of the prototype, well within reach.

It is recommended *not* to use the DHIS2 demo server for testing. While it is a useful service, it is a public one and therefore this will produce erratic results.

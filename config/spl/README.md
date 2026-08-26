# Detection content

One `.spl` file per detection. Each file starts with a comment header so the intent
survives outside Splunk:

```
# Title:     Short human name, matches the saved search name in Splunk
# MITRE:     Txxxx[.xxx] - Technique name
# Data:      Which sourcetype(s) / EventCode(s) this depends on
# Why:       What this is actually catching, in a sentence
# Noise:     Known false-positive sources and how they're filtered
```

Then the SPL itself.

## Conventions

- Always pin `index=endpoint` — never rely on a default index.
- Prefer CIM fields (`process_name`, `parent_process_name`, `user`) over raw
  `EventData` paths, so detections survive add-on and schema changes.
- Filter noise in the search, not in the alert action. A detection that only works
  because nobody looks at it isn't a detection.
- Keep the time window out of the SPL — set it on the saved search, so the same file
  can be run ad hoc over a different range while hunting.

## Depends on

Field names below assume these add-ons are installed on the search head:

- `Splunk_TA_windows` — Splunk Add-on for Microsoft Windows
- `Splunk_TA_microsoft_sysmon` — Splunk Add-on for Sysmon

Without them, Sysmon events are unparsed XML and none of this works as written.

Privacy Policy
==============

Effective date: February 10, 2026

Summary
-------
OSDCloud is a PowerShell module that runs locally. Some workflows send deployment analytics events during deployment tasks. The module also transmits data when you invoke commands that connect to external services (for example, downloading operating system or driver content).

Deployment analytics
--------------
During workflow task execution, OSDCloud sends a deployment event to PostHog. The event includes:
- A hashed device identifier derived from the device UUID
- Device details (manufacturer, model, SKU, system family)
- BIOS details (firmware type, release date, SMBIOS version)
- Keyboard name and layout
- OS details (name, version, build, edition, language)
- Workflow details (workflow name, task name, driver pack name, OS selection)
- Module version and deployment phase (WinPE or Windows)

**No personal identifying information is captured.** The analytics do not include usernames, email addresses, device serial numbers, computer names, IP addresses (beyond standard HTTP headers), or any other data that could identify an individual or specific device. The device identifier is cryptographically hashed and cannot be reversed to obtain the original UUID.

What data may be shared
-----------------------
- Network metadata (IP address, request headers) may be logged by third-party services you connect to.
- Content downloads may include standard HTTP request details required by those services.
- Deployment analytics events include the fields described above and a timestamp.

External services
-----------------
OSDCloud may interact with external services when you choose to download content, update the module, or run workflows. Those services have their own privacy policies. Examples include:
- Microsoft Update Catalog
- GitHub (project hosting and issue tracking)
- PowerShell Gallery (module distribution)
- PostHog (deployment analytics)

Your choices
------------
- You control when network requests happen by choosing which commands to run.
- If you do not want any outbound network requests, avoid commands that download content, update the module, or run workflows.

Contact
-------
For questions or concerns, open an issue at https://github.com/OSDeploy/OSDCloud/issues.

# Subprocessors

**Last updated: <YYYY-MM-DD>**

<COMPANY> uses the third-party providers below to deliver <PRODUCT>. Each one
processes personal data only on our documented instructions, under a written
data processing agreement.

**Subscribe to change notifications:** <LINK> — we notify at least <30> days
before adding a new subprocessor, so you have time to object.

---

## Infrastructure

| Provider | Purpose | Data processed | Location | Transfer safeguard |
|---|---|---|---|---|
| <Amazon Web Services> | Application hosting, database, file storage | All customer data | <eu-west-1, Ireland> | <N/A — EU> |
| <Cloudflare> | CDN, DDoS protection, DNS | IP addresses, request metadata | Global edge | <SCCs> |

## Product operations

| Provider | Purpose | Data processed | Location | Transfer safeguard |
|---|---|---|---|---|
| <Stripe> | Payment processing, invoicing | Name, email, billing address, purchase history | <US> | <SCCs> |
| <Postmark> | Transactional email delivery | Name, email address, email content | <US> | <SCCs> |
| <Twilio> | SMS notifications | Phone number, message content | <US> | <SCCs> |

## Support and communication

| Provider | Purpose | Data processed | Location | Transfer safeguard |
|---|---|---|---|---|
| <Intercom> | Customer support | Name, email, support conversations | <US> | <SCCs> |

## Monitoring and analytics

| Provider | Purpose | Data processed | Location | Transfer safeguard |
|---|---|---|---|---|
| <Sentry> | Error tracking | User id, IP address, technical error data | <EU> | <N/A — EU> |
| <PostHog> | Product analytics (consent-based) | Usage events, IP address, device data | <EU> | <N/A — EU> |

## AI and machine learning

<DELETE IF NOT APPLICABLE. If you send any user content to a model API, it
belongs here — this is one of the most commonly omitted rows, and one of the
most consequential.>

| Provider | Purpose | Data processed | Location | Transfer safeguard | Training |
|---|---|---|---|---|---|
| <Provider> | <Feature> | <What is sent> | <Region> | <SCCs> | **Not used for model training** |

---

## Notification and objection

We notify subscribers to the list above at least **<30> days** before a new
subprocessor begins processing customer data.

If you have a written agreement with us that grants a right to object, you may
raise a reasonable, documented objection within that period. We will work with
you to find an alternative; if none is available, you may terminate the affected
service in accordance with your agreement.

---

## Change history

| Date | Change |
|---|---|
| <YYYY-MM-DD> | Added <Provider> for <purpose> |
| <YYYY-MM-DD> | Removed <Provider>; data migrated to <Provider> and deleted |

---

## Questions

<privacy@DOMAIN> · Data processing agreement: <LINK> · Privacy policy: <LINK>

---

<!--
  MAINTAINING THIS PAGE

  This list must match reality. Generate the candidate set from the code:

    grep -rhoE 'googletagmanager|google-analytics|connect\.facebook\.net|hotjar|
      segment|mixpanel|posthog|intercom|clarity\.ms|sentry\.io|stripe|paypal|
      twilio|postmark|sendgrid|resend|fonts\.googleapis|recaptcha|cloudflare|
      openai|anthropic' . --exclude-dir={node_modules,.git,dist}

  Plus everything in your infrastructure that never appears in application code:
  hosting, DNS, CDN, log storage, backup storage, CI provider, secret manager.

  The most common failure is a provider added by an engineer during a sprint
  that never reached this page or the privacy policy. Add a line to the PR
  template asking about it.

  Before adding any provider:
    [ ] Is there a DPA in force?
    [ ] Where does the data physically go, and under what transfer mechanism?
    [ ] What is their retention, and can it be configured down?
    [ ] Is our data used to train their models? (If yes: disclose it, or turn it off)
    [ ] Do they have a deletion API our erasure pipeline can call?
    [ ] What is their breach-notification commitment?
-->

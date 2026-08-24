# Infrastructure

## Infrastructure as code — the standard

The test: **could you delete the production environment and rebuild it from the
repository?** If the honest answer is no, you do not have infrastructure as code;
you have documentation that happens to be executable in places.

- All infrastructure in code, in the repository, reviewed like application code.
- **State stored remotely with locking** (S3 + DynamoDB, Terraform Cloud, GCS).
  Local state is a single point of failure and a merge conflict waiting to
  happen.
- Environments as separate state, sharing modules — never one state file with
  conditionals.
- `plan` in the pull request, output visible to reviewers; `apply` only from the
  pipeline, on the default branch.
- **Never `apply` from a laptop against production.** Drift introduced by hand is
  invisible until the next `plan` reveals it, usually mid-incident.
- Drift detection on a schedule; treat drift as a defect.
- Secrets never in state or variables files. State files contain resolved values
  — treat state as sensitive and encrypt it.

**Structure**
```
infra/
  modules/           network/  database/  service/  observability/
  environments/
    staging/         main.tf  variables.tf  terraform.tfvars
    production/      main.tf  variables.tf  terraform.tfvars
```

Version module sources. Tag every resource with `service`, `environment`,
`owner`, `cost-center` — tagging is what makes cost attribution and cleanup
possible later.

---

## Network and access

- Databases and internal services in **private subnets**, unreachable from the
  internet. The application reaches them; the world does not.
- Security groups reference other security groups, not CIDR blocks, wherever
  possible — the rule then survives IP changes.
- Ingress restricted to the ports actually needed. Egress restricted too, where
  the threat model warrants it (it also mitigates SSRF and data exfiltration).
- Administrative access through a bastion, an identity-aware proxy, or a session
  manager — never a permanently open SSH port.
- **No long-lived static cloud keys.** Use workload identity / instance roles for
  services, and federated identity for CI.
- Least-privilege IAM per service. Audit for wildcard permissions; `*:*` on a
  production role is a finding.
- Separate cloud accounts (or projects) per environment. It is the strongest
  blast-radius control available and it is cheap.

---

## Scaling

**Scale the right thing.** Most applications hit the database, an external
dependency, or a single-threaded bottleneck long before they run out of
application CPU. Adding instances in front of a saturated database makes things
worse, not better.

- **Horizontal** for stateless services. Which requires them to be genuinely
  stateless: no session state in memory, no local file writes, no in-process
  cache treated as authoritative.
- **Vertical** for databases, until read replicas or partitioning is justified.
- Autoscale on the metric that reflects load — request concurrency or queue
  depth, usually, rather than CPU.
- **Always set a maximum.** Unbounded autoscaling turns a retry storm into a
  five-figure bill and can amplify an incident rather than absorbing it.
- Scale-in slowly, scale-out quickly. Aggressive scale-in causes thrash.
- Warm-up matters: a new instance that takes 90 seconds to be useful cannot
  absorb a spike. Measure it.

**Load shedding** deserves more attention than it gets. Under overload, serving
80% of requests correctly and rejecting 20% quickly with a `503` is far better
than serving 100% of them so slowly that everything times out. Queue depth
limits, concurrency caps and fast rejection are the mechanism.

---

## Managed vs self-hosted

Default to managed for anything that is not your differentiator: database, cache,
queue, search, email, object storage, identity.

The calculation people get wrong: they compare the monthly bill against zero,
rather than against the engineering hours the managed service replaces. A
self-hosted database "saves" a few hundred dollars a month and costs several
days per quarter in patching, backup verification, failover testing and
2am pages — plus a bus factor of one.

Self-host when: a compliance requirement demands it, the workload is genuinely
unusual, the scale makes the managed cost dominant, or you have a platform team
whose job this is.

Whichever you choose, **know the exit cost** before you depend on it.

---

## Kubernetes — a note on when

Kubernetes is excellent at what it does and expensive to operate. It is the right
answer when you have many services, a platform team, and genuine orchestration
needs.

It is the wrong answer for a single application with a small team. The failure
mode is predictable: the team spends its engineering budget on cluster
operations instead of the product, and the resulting system is *less* reliable
than a managed platform would have been, because nobody has time to operate it
properly.

If you are on it anyway, the essentials:
- Resource requests **and** limits on every container. Missing requests break
  scheduling; missing limits let one pod starve the node.
- Liveness and readiness probes, distinct, with sane thresholds. A liveness probe
  that is really a readiness probe causes restart loops under load.
- `PodDisruptionBudget` so voluntary disruptions do not take the service down.
- Secrets from a real secret manager via an operator, not base64 in a manifest —
  Kubernetes `Secret` objects are encoded, not encrypted, by default.
- Network policies (default deny), pod security standards, non-root containers.
- GitOps (Argo CD, Flux) so cluster state matches the repository and drift is
  visible.

---

## Cost control

Cost is an engineering property. Tag everything, report per tag, and put a budget
alert in place on day one.

**Where the money actually goes, in rough order of frequency:**
1. **Log and metric retention.** Unbounded retention on high-cardinality data is
   the most common surprise on the bill.
2. **Idle over-provisioned compute.** Instances at 5% utilisation, sized for a
   peak that never came.
3. **Forgotten non-production environments.** Preview environments without TTLs,
   an old staging cluster nobody turned off.
4. **Data transfer.** Cross-AZ, cross-region and egress. Frequently invisible
   until you look for it specifically.
5. **Orphaned resources.** Unattached volumes, old snapshots, unused elastic IPs,
   idle load balancers.
6. **Oversized managed databases** provisioned for a growth curve that did not
   happen.

**Alert on anomalies, not just budgets.** A 3x day-over-day jump is actionable
today; a monthly overrun is a post-mortem.

Reserved capacity and savings plans are worth real money once your baseline is
stable — but only for the baseline. Buying commitments for a load you have not
established yet is a bet, not a saving.

---

## Review checklist

- [ ] All infrastructure in code, in the repository
- [ ] Remote state with locking; state treated as sensitive
- [ ] `plan` in PRs; `apply` only from the pipeline
- [ ] Environments in separate state, ideally separate accounts
- [ ] Every resource tagged (service, environment, owner, cost-center)
- [ ] Databases and internal services in private subnets
- [ ] No long-lived static cloud credentials; workload identity in use
- [ ] IAM least privilege; no wildcard production roles
- [ ] Autoscaling has a maximum; warm-up time measured
- [ ] Load shedding behaviour defined for overload
- [ ] Managed services chosen for the undifferentiated; exit cost known
- [ ] Budget and anomaly alerts configured
- [ ] Log/metric retention bounded deliberately
- [ ] The environment has actually been rebuilt from code at least once

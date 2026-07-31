---
name: new-realtor-app
description: Scaffold a new application into the realtor-apps namespace — asks the user for the app's requirements, authors its Kubernetes manifests, registers it as an Argo CD Application via Terraform, verifies it live, and opens a PR. Use when the user wants to add/deploy a new app alongside Leads in this cluster.
---

# New realtor-apps application

This skill onboards a new app into the `realtor-apps` namespace, following the same pattern used for the `leads` app (Terraform + Argo CD GitOps, self-referencing this repo). Read `realtor-apps/apps.tf`, `realtor-apps/argocd-app.tf`, and `realtor-apps/leads/manifests/` first to see the current concrete example before scaffolding a new one.

## 1. Ask the user (don't assume)

Ask all of these up front — don't guess or silently default:

1. **App name** — lowercase, hyphenated (e.g. `crm`). This becomes the Argo CD Application name, the `<name>/manifests/` folder, and the `<name>-env` Secret name if it has env vars.
2. **Container image** and tag.
3. **Internal container port** the app listens on.
4. **External vs internal access** — always ask explicitly, never assume (see memory: user wants this asked every time). If external:
   - Pick an **external LoadBalancer port** that is NOT a browser-unsafe port. Chrome/Firefox block a fixed list for HTTP, including (non-exhaustive, check before picking): `1, 7, 9, 11, 13, 15, 17, 19, 20, 21, 22, 23, 25, 37, 42, 43, 53, 69, 77, 79, 87, 95, 101-104, 109-111, 113, 115, 117, 119, 123, 135, 137, 139, 143, 161, 179, 389, 427, 465, 512-515, 526, 530-532, 540, 548, 554, 556, 563, 587, 601, 636, 989, 990, 993, 995, 1719, 1720, 1723, 2049, 3659, 4045, 5060, 5061, 6000-6669, 6697, 10080`. Avoid the whole `6000-6669` (X11/IRC) range — we hit this exact wall with Leads (`6000` → `ERR_UNSAFE_PORT`) and had to move to `7001`.
   - Check `realtor-apps/apps.tf` and every `*/manifests/service.yaml` for ports already in use (`7000` = Argo CD UI, `7001` = Leads, at minimum) so the new port doesn't collide.
   - If internal-only, use a plain `ClusterIP` Service (no external port needed).
5. **Env vars needed** (just the key names — never ask for or accept real secret values meant for git; those get filled in live after sync, never committed). If the app needs to reach a service running on the user's Windows host (e.g. a local database), the DSN/host should point at `host.docker.internal`, not `localhost` — `localhost` inside a pod means the pod itself.

## 2. Scaffold the manifests

Create `realtor-apps/<name>/manifests/`:

- `deployment.yaml` — mirror `leads/manifests/deployment.yaml`'s structure. If there's a Secret, wire it via `envFrom.secretRef.name: <name>-env`.
- `service.yaml` — `type: LoadBalancer` with the chosen external `port` + `targetPort: <container port>` if external; `type: ClusterIP` with just `port`/`targetPort` if internal-only.
- `secret.yaml` (only if env vars were requested) — `type: Opaque`, `stringData` with **empty string placeholders** for every key. Never put real values here.

## 3. Register the app in Terraform

Add one entry to `local.apps` in `realtor-apps/apps.tf`:

```hcl
<name> = {
  has_secret = true  # or false, if no secret.yaml
  port       = 7002  # the external LoadBalancer port (or the ClusterIP port if internal-only)
}
```

That's the only Terraform change needed — `argocd-app.tf`'s `for_each` picks it up automatically (Argo Application name, manifests path, and the `ignoreDifferences`/`RespectIgnoreDifferences` secret protection if `has_secret = true`).

## 4. Verify before opening the PR

1. `terraform fmt -check`, `terraform validate`, `terraform plan`/`apply` in `realtor-apps/` (root config must already be applied — it installs the Argo CD CRDs this depends on).
2. Since the Application only syncs successfully once its manifests exist on the target branch (default `main`), test the raw manifests directly first: `kubectl apply -f realtor-apps/<name>/manifests/`, check `kubectl get pods -n realtor-apps` and logs.
3. If external: recreate the Service once (`kubectl delete svc <name> -n realtor-apps` then reapply) and confirm the host port actually binds — **Docker Desktop's LoadBalancer only binds a new/changed host port on Service recreation, not on an in-place patch.** Verify with `curl http://localhost:<port>/`.

## 5. Open the PR, then after merge

- Commit the new `<name>/manifests/` files + the `apps.tf` entry together, push, open a PR describing what was verified.
- After the user says to merge: merge it, `git pull` main, force an Argo refresh (`kubectl patch application <name> -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'`), and if external, do the one-time `kubectl delete svc <name> -n realtor-apps` to make Docker Desktop rebind the real host port.
- If there's a Secret: tell the user to fill in real values via `kubectl patch secret <name>-env -n realtor-apps --type merge -p '{"stringData":{...}}'` (or `kubectl edit`) — **not** the Argo CD UI's live-resource editor, which is unreliable for Secrets (masks every value as `++++++++`, and resubmitting without replacing every masked field fails with a generic, unhelpful error).

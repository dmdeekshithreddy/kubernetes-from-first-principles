# ReplicaSet Definition — Field-by-Field Notes

Reference file: `replicaset-definition.yml`

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: myreplicaset-agentic-de
  labels:
    app: agentic-de
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-nginx
      tier: frontend
  template:
    metadata:
      labels:
        app: my-nginx
        tier: frontend
    spec:
      containers:
        - name: nginx-container
          image: nginx:1.25.3
```

---

## What is a ReplicaSet?

A ReplicaSet is a Kubernetes controller whose only job is to **ensure a specified number of identical Pods are running at all times**.

- If a Pod crashes or a node goes down, the ReplicaSet notices the count has dropped and starts a replacement.
- If there are too many Pods (e.g. you scaled down), it terminates the extras.
- It does this continuously in a reconciliation loop — forever.

> In practice, you rarely create a ReplicaSet directly. A `Deployment` creates and manages a ReplicaSet for you, and adds rolling-update and rollback on top. But understanding ReplicaSet first makes Deployments much easier to grasp.

---

## `apiVersion`

```yaml
apiVersion: apps/v1
```

- ReplicaSet is **not** in the core API group (`v1`) — it lives in the `apps` group.
- `apps/v1` is the stable, production-ready version. Always use this (not the old `extensions/v1beta1` which is removed).
- Compare with Pod: `apiVersion: v1` — no group prefix because Pod is in the core group.

---

## `kind`

```yaml
kind: ReplicaSet
```

- Tells Kubernetes you want a ReplicaSet controller object.
- The ReplicaSet controller (part of `kube-controller-manager`) watches for this object and acts on it.

---

## `metadata`

```yaml
metadata:
  name: myreplicaset-agentic-de
  labels:
    app: agentic-de
    tier: frontend
```

Same structure as a Pod's metadata — these fields apply to the **ReplicaSet object itself**, not the Pods it creates.

### `metadata.name`

- The unique name of this ReplicaSet within its namespace.
- Pods created by this ReplicaSet are named `<replicaset-name>-<random-suffix>`, e.g. `myreplicaset-agentic-de-x7r2k`.

### `metadata.labels`

- Labels on the ReplicaSet object. Used if something else (like a Deployment) needs to select or describe this ReplicaSet.
- **Not the same as the labels on the Pods it creates** — those are defined in `spec.template.metadata.labels`.

---

## `spec`

`spec` describes what the ReplicaSet should do — how many Pods, which Pods to manage, and what those Pods look like.

---

### `spec.replicas`

```yaml
replicas: 3
```

- The **desired number of Pod copies** to keep running at all times.
- If omitted, defaults to `1`.
- The ReplicaSet will always try to match actual running Pods to this number:
  - Too few → creates new Pods.
  - Too many → deletes excess Pods.
- You can change this at any time:
  ```bash
  kubectl scale replicaset myreplicaset-agentic-de --replicas=5
  ```

---

### `spec.selector`

```yaml
selector:
  matchLabels:
    tier: frontend
```

This is the **most important and most misunderstood field** in a ReplicaSet.

The selector answers: **"Which Pods does this ReplicaSet own and manage?"**

- The ReplicaSet does not manage all Pods in the namespace — only Pods whose labels match this selector.
- It counts matching Pods and reconciles to reach `spec.replicas`.
- **The selector must match the labels in `spec.template.metadata.labels`.** If they don't match, Kubernetes rejects the manifest.
- The selector is **immutable** after creation — you cannot change it without deleting and recreating the ReplicaSet.

#### `matchLabels`

```yaml
matchLabels:
  key: value
```

- A simple equality check: the Pod must have **all** of these labels to be selected.
- You can have multiple key-value pairs — all must match (AND logic).

#### `matchExpressions` (alternative, more powerful)

```yaml
selector:
  matchExpressions:
    - key: app
      operator: In
      values: [agentic-de, agentic-de-v2]
```

- More expressive: supports `In`, `NotIn`, `Exists`, `DoesNotExist` operators.
- `matchLabels` and `matchExpressions` can be combined — both must be satisfied.

---

### `spec.template`

```yaml
template:
  metadata:
    labels:
      app: my-nginx
      type: front-end
  spec:
    containers:
      - name: nginx-container
        image: nginx:1.25.3
```

The template is a **Pod blueprint** — it defines what every Pod created by this ReplicaSet will look like.

- This is an embedded Pod definition (without `apiVersion` or `kind`, since the ReplicaSet already provides that context).
- Every time the ReplicaSet needs to create a new Pod, it stamps out a copy from this template.

#### `spec.template.metadata.labels`

```yaml
metadata:
  labels:
    key: value
```

- These labels are applied to **every Pod this ReplicaSet creates**.
- **Must match `spec.selector.matchLabels`** — this is what links the selector to the Pods. If these don't match, Kubernetes rejects the manifest immediately.

#### `spec.template.spec`

```yaml
spec:
  containers:
    - name: myapp
      image: nginx:1.25.3
```

- Identical to a standalone Pod's `spec`. All Pod spec fields are valid here.
- `containers` is a list — each item defines one container in the Pod.
- `name`: identifies the container within the Pod.
- `image`: the container image to run. Always pin to a specific tag in production.

---

## How the Selector Links Everything Together

```
spec.selector.matchLabels         spec.template.metadata.labels
      key: value          ←——————————————  key: value
         ↑                                      ↓
  "Manage Pods           These labels are stamped onto
   with this label"      every Pod this RS creates
```

This design also means: if a Pod with matching labels exists in the namespace **before** the ReplicaSet is created, the ReplicaSet will **adopt** that Pod and count it toward its replica count. This is intentional — it allows pre-existing Pods to be managed without recreation.

---

## Key ReplicaSet Commands

```bash
# Create from file
kubectl apply -f replicaset-definition.yml

# List all ReplicaSets
kubectl get replicasets
kubectl get rs                          # shorthand

# Show details: events, selector, pod status
kubectl describe replicaset myreplicaset-agentic-de

# Scale replicas up or down
kubectl scale rs myreplicaset-agentic-de --replicas=5

# See the Pods the ReplicaSet created
kubectl get pods -l key=value

# Delete the ReplicaSet (also deletes all Pods it manages)
kubectl delete rs myreplicaset-agentic-de

# Delete the ReplicaSet but KEEP the Pods running
kubectl delete rs myreplicaset-agentic-de --cascade=orphan
```

---

## ReplicaSet vs Deployment — When to Use Which

|                            | ReplicaSet | Deployment                     |
| -------------------------- | ---------- | ------------------------------ |
| Keeps N pods running       | yes        | yes (via a ReplicaSet it owns) |
| Rolling updates            | no         | yes                            |
| Rollback                   | no         | yes                            |
| Use directly in production | rarely     | yes — preferred                |

Use a ReplicaSet directly only when you need the raw primitive and do not need rolling updates. For everything else, use a Deployment.

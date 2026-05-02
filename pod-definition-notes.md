# Pod Definition — Field-by-Field Notes

Reference file: `pod-definition.yml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-nginx
  labels:
    app: my-nginx
    type: front-end
spec:
  containers:
    - name: nginx
      image: nginx
```

> **Note:** The name doesn't affect which image is pulled, but it's used in logs and `kubectl exec` — keep it accurate.

---

## `apiVersion`

```yaml
apiVersion: v1
```

- Tells Kubernetes **which API group and version** to use when processing this file.
- Kubernetes has multiple API groups (core, apps, batch, networking, etc.). Each resource type lives in one group.
- `v1` is the **core API group** — the oldest and most stable. It covers fundamental resources: Pod, Service, ConfigMap, Secret, Namespace, etc.
- Other examples you'll encounter:
  | Resource | apiVersion |
  |---|---|
  | Pod | `v1` |
  | Deployment | `apps/v1` |
  | CronJob | `batch/v1` |
  | Ingress | `networking.k8s.io/v1` |
  | HorizontalPodAutoscaler | `autoscaling/v2` |
- If you use the wrong `apiVersion`, the API server rejects the request with a "no kind ... is registered" error.

---

## `kind`

```yaml
kind: Pod
```

- Specifies **what type of Kubernetes object** you want to create.
- Combined with `apiVersion`, it uniquely identifies the resource type.
- Common kinds: `Pod`, `Deployment`, `Service`, `ConfigMap`, `Secret`, `Namespace`, `StatefulSet`, `DaemonSet`, `Job`, `CronJob`.
- `Pod` is the **smallest deployable unit** in Kubernetes. It wraps one or more containers that share:
  - The same network namespace (same IP address, same `localhost`)
  - The same storage volumes
  - The same lifecycle (start together, stop together)
- In practice you rarely create bare Pods directly. You use a `Deployment`, which creates and manages Pods for you. But understanding Pods first is essential.

---

## `metadata`

```yaml
metadata:
  name: my-nginx
  labels:
    app: my-nginx
    type: front-end
```

Metadata holds **identity and organizational information** about the object. It is not part of the workload itself.

### `metadata.name`

```yaml
name: my-nginx
```

- The **unique name** of this Pod within its namespace.
- Must be unique per namespace — you cannot have two Pods named `my-nginx` in the same namespace.
- Used by `kubectl` to target this object: `kubectl get pod my-nginx`, `kubectl delete pod my-nginx`.
- Naming rules: lowercase alphanumeric characters and hyphens (`-`), must start and end with alphanumeric. Max 253 characters.

### `metadata.labels`

```yaml
labels:
  app: my-nginx
  type: front-end
```

- Labels are **key-value pairs** attached to an object for identification and grouping.
- They have no meaning to Kubernetes itself — they are entirely for your use and for **selectors**.
- **Selectors** are how Services, Deployments, and other controllers find the Pods they manage. A Service with `selector: app: my-nginx` will route traffic to any Pod carrying that label.
- You can add as many labels as you want.
- Common conventions:
  | Key | Example value | Purpose |
  |---|---|---|
  | `app` | `my-nginx` | which application this belongs to |
  | `type` / `tier` | `front-end`, `back-end`, `db` | logical layer |
  | `env` | `production`, `staging` | environment |
  | `version` | `v1.2.0` | app version |
- Labels differ from **annotations**: labels are for selecting/filtering; annotations are for storing arbitrary metadata (e.g. build info, owner contact) that tools read but Kubernetes doesn't use for scheduling.

---

## `spec`

```yaml
spec:
  containers:
    - name: nginx
      image: nginx
```

`spec` is the **desired state** of the Pod — what you want Kubernetes to make happen. Everything under `spec` describes the actual workload.

### `spec.containers`

```yaml
containers:
  - name: nginx
    image: nginx
```

- A list (note the `-`) of container definitions. A Pod can have **one or more containers**.
- Most Pods have a single main container. Multiple containers in one Pod is the "sidecar" pattern (e.g., a log collector running alongside the app).

#### `containers[].name`

```yaml
name: nginx
```

- A name for this container **within the Pod**. Must be unique within the Pod's container list.
- Used in `kubectl logs <pod> <container>` and `kubectl exec <pod> -c <container>` when a Pod has multiple containers.
- Does **not** affect which image is pulled — that's controlled by `image`.

#### `containers[].image`

```yaml
image: nginx
```

- The **container image** to pull and run. Follows Docker image naming conventions.
- `nginx` is shorthand for `docker.io/library/nginx:latest` — the official nginx image from Docker Hub at the `latest` tag.
- In production, always pin to a specific tag to avoid surprise updates:
  ```yaml
  image: nginx:1.25.3
  ```
- You can reference images from any registry:
  ```yaml
  image: gcr.io/my-project/my-app:v2.1.0
  image: ghcr.io/org/repo:sha-abc1234
  image: my-private-registry.example.com/app:stable
  ```

---

## Common Fields You'll Add Next

These are not in the current file but are the most common next fields to learn:

```yaml
spec:
  containers:
    - name: nginx
      image: nginx:1.25.3

      # Expose a port from the container (informational; doesn't actually open it)
      ports:
        - containerPort: 80

      # Environment variables passed into the container
      env:
        - name: ENV_NAME
          value: production

      # CPU and memory limits/requests for the scheduler
      resources:
        requests:
          memory: "64Mi"
          cpu: "250m"
        limits:
          memory: "128Mi"
          cpu: "500m"
```

---

## How These Four Top-Level Fields Relate

Every Kubernetes manifest has the same four root fields:

```
apiVersion  →  which API to talk to
kind        →  what type of object
metadata    →  identity (name, labels, namespace, annotations)
spec        →  desired state (what should run / exist)
```

Kubernetes adds a fifth field, `status`, automatically — you never write it; the control plane fills it in to report the _current_ state vs. your desired `spec`.

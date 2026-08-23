# Wave 1 — Sealed Secrets

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) controller in `kube-system` (`fullnameOverride: sealed-secrets-controller`).

The **sealing certificate is generated in-cluster**. It is unique to this cluster. You cannot reuse SealedSecrets from another lab.

Next: [Secrets workflow](../secrets.md) (catalog + **back up the sealing key**).

!!! success "Validation"
    Do not `kubeseal` (and do not expect wave 2 repo-creds in Git to decrypt) until:

    ```bash
    kubectl -n kube-system get deploy sealed-secrets-controller   # Ready 1/1
    kubeseal --fetch-cert --controller-name=sealed-secrets-controller \
      --controller-namespace=kube-system > /tmp/pub-cert.pem
    openssl x509 -in /tmp/pub-cert.pem -noout -subject   # a cert, not an error
    ```

    Copy `pub-cert.pem` somewhere durable. Back up the [sealing key](../secrets.md#back-up-the-sealing-key) before you rely on ciphertext.

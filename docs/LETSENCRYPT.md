# Letsencrypt certificates

The Ingress Pod can be configured to fetch a certificate bundle from an internal service. This internal service would be the Pod based on [_Let's Encrypt_](https://letsencrypt.org/) or a compatible one.

Run the _Let's Encrypt_ Pod **strictly as a single instance in the cluster**, otherwise there will be a loadbalancing roulette when the _Let's Encrypt_ service (_LE_) is connecting to the _LE_ agent to verify our request.

Configure the Ingress Pods to be using the _fetcher_ service by setting `ingress_useFetcher` to `true` in _cluster-vars.env_ i.e. `ingress_useFetcher=true`. If the fetcher is not used, then _Let's Encrypt_ certificates will not be fetched, which could be the desirable outcome if you are providing the certificates yourself (see more information about this case further on this section).

Add all domains to be issued or renewed to the _Let's Encrypt_ Pods configuration file `_config/certs_list/certs.txt`.
> Note: Renewals are automatically done and they occur 20 days prior to certificate expiration date.

## Cheatsheet and troubleshooting
Useful commands:  
```sh
# After adding domains to _config/certs_list/certs.txt we need to update the pod with the new config.
sns pod updateconfig letsencrypt
git add . && commit -m "Add domain to letsencrypt"
sns cluster sync
```

Updating the configuration will trigger the _Let's Encrypt_ Pod to issue the newly add certificates.

Watch the logs to confirm the certifcate was issued successfully:  
```sh
sns pod logs letsencrypt
```

The Ingress Pod fetcher service fetches the certificate bundle twice a day. However, since the domain is new we may want to manually fetch it to the Ingress pod, as such:
```sh
# This will rerun the fetcher container to trigger it to download the new bundle.
sns pod rerun ingress fetcher
sns pod logs ingress
```

# Letsencrypt certificates

The Ingress pod can be configured to fetch a certificate bundle from an internal service. This internal service would be this Letsencrypt pod or a compatible one.

Run the Letsencrypt pod **strictly as a single instance in the cluster**, otherwise there will be a loadbalancing roulette when the Let's Encrypt (LE) service is connecting to our _LE_ agent to verify our request.

Configure the ingress pods to be using the _fetche _` service by setting `ingress_useFetcher=true` in _cluster-vars.env_. If the fetcher is not used then no Let's Encrypt certificates will be fetched, which could be what you want if you are providing the certificates yourself (see more information about this case further on this section).

Add all domains to be issued or renewed to the Letsencrypt pods configuration file `_config/certs_list/certs.txt`. Renewals are automated and happens 20 days prior to certificate expiration date.

Useful commands:  

```sh
# After adding domains to _config/certs_list/certs.txt we need to update the pod with the new config.
sns pod updateconfig letsencrypt
git add . && commit -m "Add domain to letsencrypt"
sns cluster sync
```

Updating the config will trigger the Letsencrypt pod to issue the newly add certificates.

Watch the logs to confirm the cert was issued successfully:  
```sh
sns pod logs letsencrypt
```

The Ingress pod fetcher service fetches the certificate bundle twice a day. However, since the domain is new we want to manually fetch it now to the Ingress pod.

```sh
# This will rerun the fetcher container to trigger it to download the new bundle.
sns pod rerun ingress fetcher
sns pod logs ingress
```

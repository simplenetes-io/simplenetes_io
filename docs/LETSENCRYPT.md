# Letsencrypt certificates

The Ingress pod can be configured to fetch a certificate bundle from an internal service. This internal service would be this Letsencrypt pod or a compatible one.

Run the Letsencrypt pod **strictly as a single instance in the cluster**, otherwise there will be a loadbalancing roulette when the LE service is connecting to our LE agent to verify our request.

Configure the ingress pods to be using the `fetcher` service by setting `ingress_useFetcher=true` in `cluster-vars.env`. If the fetcher is not used then no Letsencrypt certificates will be fetched, which could be what you want if you are providing the certificates yourself (see more further down).

Add all domains to be issued/renewd to the letsencrypt pods config `_config/certs_list/certs.txt`. Renewals are automated and happens when 20 days is remaining on a certificate.

Useful commands:  

```sh
# After adding domains to _config/certs_list/certs.txt we need to update the pod with the new config.
sns pod updateconfig letsencrypt
git add . && commit -m "Add domain to letsencrypt"
sns cluster sync
```

Updating the config will trigger the Letsencrypt pod to issue the newly add certificates.

Watch the logs to see that the cert was issued successfully:  
```sh
sns pod logs letsencrypt
```

The Ingress pod fetcher service fetches the certificate bundle twice a day, but since the domain was new we want to fetch it ASAP to the Ingress pod.

```sh
# This will rerun the fetcher container to trigger it to download the new bundle.
sns pod rerun ingress fetcher
sns pod logs ingress
```

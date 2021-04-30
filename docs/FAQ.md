**Q. Why does the Proxy (by default) listen to over 61000 TCP ports? This seems like a lot!**  
A. This is because we opted for a super robust low configuration proxy with few moving parts and with no syncing of routing tables across the cluster.  
   Based on observational figures, listening to 61000 ports costs about 500 MB of extra memory, without accounting to memory required for the process itself.  
   This is the default setting when Cluster ports are available between `1024-29999` and `32768-65535`.  
   These ranges can be configured to be lower if needed to be, say between `61000` and `63999` (which is the range for automatically assigned Cluster ports). In such case, it would then only require about 20 MB of additional memory.

**Q. Can I change the _cluster-id.txt_ file in my project?**  
A. You can, as long as you (re)initialize every Host in the Cluster manually by running `sns host init <host> -f`.

**Q. Can two different Clusters have the same _ID_? **  
A. Yes, but avoid it. The Cluster ID is a safety measure to prevent operating on the wrong Hosts by mistake.


**Q. What are the available variable settings and which ones am I allowed to manually change in the _host.env_ file?**  
   _HOST_ - if your Host changes _IP_ address.  
   _PORT_ - if the Host _SSH_ daemon gets reconfigured for another port.  
   _USER_ - if the user on the Host gets renamed.  
   _FLAGS_ - these are _SSH_ flags which you can add in the form of space-separated values.  
   _KEYFILE_ - path to the _SSH_ keyfile.  
   _JUMPHOST_ - if needed to jump via a Host to reach the target Host. This is the name of another Host in your cluster.  
   _HOSTHOME_ - directory on Host where to files are synced to. **Do not** change this.  
   _EXPOSE_ - space-separated list of port numbers to expose to the public Internet. If not using `JUMPHOST` **YOU MUST HAVE** `22` (_SSH_ port) **SET**. Whenever changed, re-run `sns host setup`.  
   _INTERNAL_ - space-separated list of networks treated as internal networks in the Cluster. Important so that hosts can talk internally. Whenever changed, re-run `sns host setup`.  
   _ROUTERADDRESS_ - `InternalIP:port` where other Hosts can connect to in order to reach the Proxy Pod running on the Host. Leave blank if no Proxy pod is running on the Host. Whenever changed, it gets propagated on the next synchronization call i.e. `sns cluster sync`.  

**Q. Can I change the `HOSTHOME` variable on the _host.env_ file? **  
A. Setting `HOSTHOME` is not a good idea. You would first need to set all Pods on the Host to `removed` state, then sync the changes. Only after that the `HOSTHOME` would need to be changed to the desired value, the Host would need reinitialization (`sns host init -f`), then the Cluster would have to be resynchronized. In that case, you should also remove the old `HOSTHOME` directory from the Host.  
   Alternatively, you could, after having removed all Pods, move the old `HOSTNAME` to the new `HOSTHOME`, preserving the logs.

**Q. What are all the different Hosts states?**  
   `active` - Host is synced, has Ingress generated and it is part of internal Proxy routing.  
   `inactive` - Host is synced, but has no Ingress generated and it is not part of internal Proxy routing.  
   `disabled` - Host is not synced, just ignored.  

**Q. How can a I delete a Host? **  

1. Set all Pods to `stopped` or `removed` on the Host.  
2. Set the Host to `inactive` state.  
3. Regenerate the Ingress.  
4. Sync the Cluster.  
5. Put the Host to `disabled` state.  

At the end of the process, feel free to delete the Host directory, if desired.

**Q. Can I work with multiple Hosts on my local development Cluster?**  
A. You can. However, it will require some precautions during configuration.  
   The `HOSTHOME` for each Hosts must, of course, not be the same. Otherwise there will be conflicts during synchronization.  
   The trickier part to be attentive to is that Host ports and Cluster ports must not interfere between the different "hosts", since in reality there is only one underlying Host (your computer or laptop).  
   This would require that all ports are set manually in _cluster-vars.env_ instead of using auto assignments.  

**Q. Can I work with multiple development Clusters on my laptop at the same time?**  
A. It depends.    
   Yes, if not running any Pods simultaneously in the different clusters.  
   No, if wanting the internal Proxy for communication among Pods and running the Clusters at the same time.  
   There are ways to configure around this. The same precautions about interfering ports also applies in this case. At this stage you should just spin up a (new) local _VM_ instead, then run each Cluster in its own separate _VM_.  

**Q. How can I configure to run multiple proxies on the same Host?**  
A. Make the Proxy Pod listen to another port and configure each _host.env_ so its `ROUTERADDRESS` reflects the port change.

**Q. Can I run the daemon without _systemd_?**  
A. Yes, you can run it as is. If you want _ramdisk_ then you need to run it as _root_.  
   You can run it with other init systems too. The important thing is to have the equivalent of systemd's `KillMode=process`, so that the Pods are not killed when the daemon is restarted.

**Q. Why is my data lost when I rerun a pod or a container? **  
A. _Simplenetes_ Pods have no concept of restarting. If a Pod is stopped and started again, then it is a new instance of the Pod and its associated containers. That means any data stored internally in containers is lost in the process.  
   To keep state between Pod restarts you will need to use a volume to store data in.  
   Following this pattern will make it easier for you to upgrade Pods since important data is never expected to be stored inside containers anyway.

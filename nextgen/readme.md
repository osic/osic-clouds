![Select the Flavor](images/osic_banner.png)


### VM (Nova) compute capacity
![compute capacity](https://cloud1.osic.org/grafana/render/dashboard-solo/db/openstack-all-compute-aggregates?var-compute_identifier=comp-&var-node_count=242&var-inter=%24__auto_interval&var-ort=1h&panelId=8&width=225)
![compute capacity](https://cloud1.osic.org/grafana/render/dashboard-solo/db/openstack-all-compute-aggregates?var-compute_identifier=comp-&var-node_count=242&var-inter=%24__auto_interval&var-ort=1h&panelId=10&width=225)
![compute capacity](https://cloud1.osic.org/grafana/render/dashboard-solo/db/openstack-all-compute-aggregates?var-compute_identifier=comp-&var-node_count=242&var-inter=%24__auto_interval&var-ort=1h&panelId=11&width=350)

Capacity metrics are derived from our realtime metric collection system. More data on available VM capacity can be [found here](https://cloud1.osic.org/grafana/dashboard/db/openstack-all-compute-aggregates).

### Baremetal (Ironic) Node Capacity
![node count](https://cloud1.osic.org/grafana/render/dashboard-solo/db/openstack-ironic-baremetal-insights?panelId=11&width=200)
![unused nodes](https://cloud1.osic.org/grafana/render/dashboard-solo/db/openstack-ironic-baremetal-insights?panelId=12&width=200)
![reserved nodes](https://cloud1.osic.org/grafana/render/dashboard-solo/db/openstack-ironic-baremetal-insights?panelId=8&width=200)
![nodes consumed](https://cloud1.osic.org/grafana/render/dashboard-solo/db/openstack-ironic-baremetal-insights?panelId=15&width=200)

Capacity metrics are derived from our realtime metric collection system. More data on available Baremetal capacity can be [found here](https://cloud1.osic.org/grafana/dashboard/db/openstack-ironic-baremetal-insights).

----

##### Consumer Information:
  - [Getting Started](user-getting-started.md)
  - [Getting SSH Access](user-getting-ssh.md)
  - [Getting HTTP Access](user-getting-http.md)
  - [Getting Baremetal nodes](user-getting-baremetal.md)

##### Administrative Information:
  - [Building Ironic Images](admin-building-images.md)
  - [Enrolling new nodes into Ironic](admin-node-enrollment.md)

##### General Notes:
  - [Notes](notes.md#notes)

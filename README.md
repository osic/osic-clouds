![alt text](https://01.org/sites/default/files/pictures/openstack04.png)

# OSIC Clouds Introduction
Welcome to the OSIC Cluster documentation repo. The purpose of this repo is to provide support and information for users of the OSIC Cluster Clouds.

> **This repo is not live just yet**

Through the world’s largest OpenStack developer cloud established by the OpenStack Innovation Center (OSIC), the community can now develop and test code at scale beyond what has been possible before. In addition, this developer cloud serves as a blueprint for organizations to deploy OpenStack within their own environments.
If you are working on improving the manageability, reliability, availability, security, stability or operability of OpenStack at scale, we want to give you access to this environment—comprised of 2,000 nodes of the latest hardware—for your development and testing.

## Cluster Hardware
> Model: HP DL380 Gen9
> Processor: 2x 12-core Intel E5-2680 v3 @ 2.50GHz
> RAM: 256GB RAM
> Disk: 12x 600GB 15K SAS - RAID10
> NICS: 2x Intel X710 Dual Port 10 GbE

> All servers contain two Intel X710 10 GbE NICs. This is a relatively new NIC that has caused us a lot of problems during the setup of the OSIC environment. If you will be installing Ubuntu Server 14.04 on these servers, we highly recommend you use an i40e driver no older than 1.3.47.

Check out the [wiki](https://github.com/osic/osic-clouds/wiki) for more details and helpful tips on how to use these clusters.

# Submitting and Tracking New Requests
File an [issue](https://github.com/osic/osic-clouds-requests/issues) in the [osic-clouds-requests repo](https://github.com/osic/osic-clouds-requests) by clicking the ['New' button under Issues in the separate osic-clouds-requests repo](https://github.com/osic/osic-clouds-requests/issues/new) and fill out the template. The Governance Board will review, vote and respond. Once you have access, come back here to the osic-clouds repo for tools tips and more.

> Why did we make a separate repo for requests? The github template function only allows for one template per repo. Plus, it keeps all requests separate from any work issues that may come up here.

Please complete and submit the form to request access today. All submissions will be reviewed on a monthly basis, and dispositioned using the criteria below. Availability will depend on current utilization rates.

## Use-case Acceptance
 - Project directly benefits OpenStack upstream, with an emphasis on enterprise readiness
 - Project solves an issue, problem or gap or benefits the community as a whole
 - Project utilizes a minimum of one (1) server rack, or 500 cores
 - Applicant commits to publicize test results

 [Learn more about the OSIC developer cloud](https://osic.org/sites/osic.org/files/OSIC_Exposed_final_web.pdf)

# Submitting and Tracking Issues as a Current User
File and [issue](https://github.com/osic/osic-clouds/issues) here in this repo. This is where past and present users are to be most active. The other 'osic-clouds-requests' repo is solely for requesting access.

# Communication
 - **Email**  osic-cluster@rackspace.com
 - **Twitter** [@OSIC_org](https://twitter.com/OSIC_org)
 - **IRC** Freenode `#osic-clouds`
 - **Website** [https://osic.org](https://osic.org)

## OSIC Cluster Governance Board
| Name | Org |
| --- | --- |
| Chris Hoge| OpenStack.org |
| Justin Shepherd | Rackspace |
| Shilla Saebi | Community |
| Das Kamhout | Intel |
| Yih Leong Sun | Intel |

## OSIC Cluster Operations
| Name | Role | Email | IRC | Twitter |
| --- | --- | --- | --- | --- |
| Dale Bracey | Ops & Account Management | dale@rackspace.com | irtermite | [@irtermite](https://twitter.com/irtermite) |
| Kevin Carter | Dev, Ops & Engineering | kevin.carter@rackspace.com | cloudnull | [@cloudnull](https://twitter.com/cloudnull) |
| Melvin Hillsman | Ops & Engineering | melvin.hillsman@rackspace.com | mrhillsman | [@mrhillsman](https://twitter.com/mrhillsman) |

# Getting Started
Head on over to the [OSIC Cluster Wiki](https://github.com/osic/osic-clouds/wiki) for more information.

Please review [this information](nextgen/readme.md) on getting started with OSIC and Ironic Baremetal.

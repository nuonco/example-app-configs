<center>
<h1> AKS Simple </h1>
This is a simple Azure AKS cluster with a whoami app deployed to it.

Nuon Install Id: {{ .nuon.install.id }}

Azure Location: {{ .nuon.install.cloud_account.region }}

</center>

To test, either click the url [https://{{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}) or open a terminal and run the following command:

```bash
curl https://{{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}
```

Expected output:

```bash
Hostname: whoami-78ffb6cbf9-w6tcc
IP: 127.0.0.1
IP: ::1
IP: 10.128.134.220
IP: fe80::a0b5:67ff:fe1f:795
RemoteAddr: 10.128.0.152:44048
GET / HTTP/1.1
Host: whoami.inxxxxxxxxxxxxxxxxxxxxxxx.nuon.run
User-Agent: curl/8.7.1
Accept: */*
X-Request-Id: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
X-Forwarded-For: xxx.xxx.xxx.xxx
X-Forwarded-Port: 443
X-Forwarded-Proto: https
```

### Full State

<details>
<summary>Full Install State</summary>
<pre>{{ toPrettyJson .nuon }}</pre>
</details>

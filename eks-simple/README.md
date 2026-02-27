<center>

<h1> EKS Simple </h1>

An EKS Cluster with a Whoami app deployed to it.

<small>{{ .nuon.install_stack.outputs.region }}</small> | <small>{{ .nuon.install_stack.outputs.account_id }}</small>

</center>

To test, either click the url
[https://{{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})
or open a terminal and run the following command:

```bash
curl https://{{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}
```

<details>

<summary>Example Expected Output</summary>

```txt
Hostname: whoami-78ffb6cbf9-w6tcc
IP: 127.0.0.1
IP: ::1
IP: 10.xxx.xxx.xxx
IP: fe80::a0b5:67ff:fe1f:795
RemoteAddr: 10.xxx.x.xxx:44048
GET / HTTP/1.1
Host: {{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}
User-Agent: curl/8.7.1
Accept: */*
X-Amzn-Trace-Id: Root=1-689f5793-4409b4cb4c923e0b0189cd69
X-Forwarded-For: xxx.xxx.xxx.xxx
X-Forwarded-Port: 443
X-Forwarded-Proto: https
```

</details>

### Full State

<details>
<summary>Full Install State</summary>
<pre>{{ toPrettyJson .nuon }}</pre>
</details>

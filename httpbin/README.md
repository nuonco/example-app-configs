# HTTPBin

{{ if .nuon.install_stack.outputs }}
AWS | {{ dig "account_id" "000000000000" .nuon.install_stack.outputs }} | {{ .nuon.cloud_account.aws.region }} | {{ dig "vpc_id" "vpc-000000" .nuon.install_stack.outputs }}
{{ else }}
AWS | 000000000000 | xx-vvvv-00 | vpc-000000
{{ end }}

A simple service used to test and debug HTTP requests.
This uses go version which can be found [here](https://github.com/mccutchen/go-httpbin).

Click [here](http://{{.nuon.components.ec2.outputs.public_ip}}) to see your httpbin instance.

## Usage

```bash
$ curl -X POST -H "Content-Type: application/json" http://{{.nuon.components.ec2.outputs.public_ip}}/post -d '{"foo": "bar"}'
{
  "args": {},
  "headers": {
    "Accept": [
      "*/*"
    ],
    "Content-Length": [
      "14"
    ],
    "Content-Type": [
      "application/json"
    ],
    "Host": [
      "54.173.32.179"
    ],
    "User-Agent": [
      "curl/8.7.1"
    ]
  },
  "method": "POST",
  "origin": "24.242.20.36",
  "url": "http://54.173.32.179/post",
  "data": "{\"foo\": \"bar\"}",
  "files": {},
  "form": {},
  "json": {
    "foo": "bar"
  }
}
```

## About this App Config

This is a sample App Config with a single `terraform_module` component that creates an EC2 instance
and starts a basic web server.


## Full State

<details>
  <summary>Full Install State</summary>
  <pre>{{ toPrettyJson .nuon }}</pre>
</details>

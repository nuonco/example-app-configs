# AWS Custom Output

This launch-test app exercises a local CloudFormation custom stack on the minimal AWS sandbox:

- `stack.toml` uses the byo-vpc and runner nested templates so the install stack can parse as `aws-cloudformation` without an EKS cluster;
- sync uploads the local `cloudformation/echo.yaml` template;
- the `echo_value` install input maps to its `EchoValue` parameter;
- the nested stack returns the value through its `EchoValue` output;
- the output phones home under the custom-stack output namespace; and
- deleting the install stack destroys the disposable wait-condition handle.

The returned value is available at:

```text
{{.nuon.install_stack.outputs.custom_nested_stacks.echo.outputs.EchoValue}}
```

CloudFormation requires at least one resource, so the template declares `AWS::CloudFormation::WaitConditionHandle` instead of an empty `Resources` map.

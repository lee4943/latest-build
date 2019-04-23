# latest-build

Assuming that provided JSON payloads are of the following structure:
```
{
    "jobs": {
        "Build base AMI": {
            "Builds": [{
                "runtime_seconds": "1931",
                "build_date": "1506741166",
                "result": "SUCCESS",
                "output": "base-ami us-west-2 ami-9f0ae4e5 d1541c88258ccb3ee565fa1d2322e04cdc5a1fda"
            }, {
                "runtime_seconds": "1825",
                "build_date": "1506740166",
                "result": "SUCCESS",
                "output": "base-ami us-west-2 ami-d3b92a92 3dd2e093fc75f0e903a4fd25240c89dd17c75d66"
            }, {
                "runtime_seconds": "126",
                "build_date": "1506240166",
                "result": "FAILURE",
                "output": "base-ami us-west-2 ami-38a2b9c1 936c7725e69855f3c259c117173782f8c1e42d9a"
            }, {
                "runtime_seconds": "1842",
                "build_date": "1506240566",
                "result": "SUCCESS",
                "output": "base-ami us-west-2 ami-91a42ed5 936c7725e69855f3c259c117173782f8c1e42d9a"
            }, {
                "runtime_seconds": "5",
                "build_date": "1506250561"
            }, {
                "runtime_seconds": "215",
                "build_date": "1506250826",
                "result": "FAILURE",
                "output": "base-ami us-west-2 ami-34a42e15 936c7725e69855f3c259c117173782f8c1e42d9a"
            }]
        }
    }
}
```

Finds the latest build among all jobs in `jobs`!


# Tested Using
- Windows 8.1 (I know; I'm sorry)
- Git Bash 2.14.2.3
- Node.js ~8.11.1
- Terraform 0.11.13


# Deployment
- Download `terraform` for your platform & ensure that `terraform` is in your path
  - https://www.terraform.io/downloads.html
- `git clone` this repository and `cd` into it
- `terraform init && terraform apply -auto-approve -var 'access_key=<your_aws_access_key>' -var 'secret_key=<your_aws_secret_key>'`
- And you're done!
- For the sake of ease, `apply` output will be of the following format:
  - ```
    app_server_ip = <private_ip_address>
    app_url = http://<aws_alb_hostname>/builds
    bastion_host_ip = <public_ip_address>
    health_check_url = http://<aws_alb_hostname>/health_check
    ```
- `POST` the above JSON payload to `app_url` to try out your new app!
- SSH to your bastion host (and app server) using the generated private key in `id_rsa`
  - **And yes, it will initially be empty!  Do not delete it!**